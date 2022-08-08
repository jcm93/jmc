//
//  AppleMusicTrackIdentifier.swift
//  jmc
//
//  Created by John Moody on 1/14/22.
//  Copyright © 2022 John Moody. All rights reserved.
//

import Cocoa
import MusicKit

@available(macOS 12.0, *)
class AppleMusicTrackIdentifier: NSObject {
    
    var status: MusicAuthorization.Status
    
    init(authorizes: Bool) {
        self.status = .notDetermined
        super.init()
        if authorizes {
            authorize()
        }
    }
    
    func authorize() {
        Task {
            let authStatus = await MusicAuthorization.request()
            update(status: authStatus)
        }
    }
    
    func update(status: MusicAuthorization.Status) {
        self.status = status
    }
    
    func initializeLibrary() {
        let appleMusicTracksFetchRequest = NSFetchRequest<Track>(entityName: "Track")
        let predicate = NSPredicate(format: "file_kind == 'Apple Music AAC audio file'")
        appleMusicTracksFetchRequest.predicate = predicate
        do {
            let tracks = try managedContext.fetch(appleMusicTracksFetchRequest)
            let artists = Set(tracks.compactMap({return $0.artist}))/*.filter({$0.apple_music_persistent_id == nil})*/.map({return ($0, $0.name!)})
            //let albums = tracks.compactMap({return $0.album!})
            Task {
                for artist in artists {
                    let artistPersistentID = await requestArtist(artistName: artist.1)
                    DispatchQueue.main.async {
                        artist.0.apple_music_persistent_id = artistPersistentID
                    }
                    if artistPersistentID != "" {
                        await requestAlbums(artistPersistentID: artistPersistentID, artist: artist.0)
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    func initializeTracksForArtist(artist: Artist) {
        let artistName = artist.name!
        Task {
            let artistID = await self.requestArtist(artistName: artistName)
            DispatchQueue.main.async {
                artist.apple_music_persistent_id = artistID
            }
            //await self.matchTrackIDs(artistID: artistID)
        }
    }
    
    func requestArtist(artistName: String) async -> String {
        var encodedArtistName = String(artistName.replacingOccurrences(of: " ", with: "+").replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "&", with: "").unicodeScalars.filter(CharacterSet.urlQueryAllowed.union(CharacterSet(charactersIn: "+")).contains))
        let urlString = "https://api.music.apple.com/v1/me/library/search?term=\(encodedArtistName)&types=library-artists&limit=5"
        let requestURL = URL(string: urlString)!
        let urlRequest = URLRequest(url: requestURL)
        do {
            let request = MusicDataRequest(urlRequest: urlRequest)
            let response = try await request.response()
            let artistID = determineArtistID(response: response, initialQuery: artistName)
            return artistID
        } catch {
            print("error making api request")
            return ""
        }
    }
    
    func requestAlbums(artistPersistentID: String, artist: Artist) async {
        let urlString = "https://api.music.apple.com/v1/me/library/artists/\(artistPersistentID)/albums"
        let requestURL = URL(string: urlString)!
        let urlRequest = URLRequest(url: requestURL)
        do {
            let request = MusicDataRequest(urlRequest: urlRequest)
            let response = try await request.response()
            DispatchQueue.main.async {
                self.matchAlbumIDs(artist: artist, response: response)
            }
        } catch {
            DispatchQueue.main.async {
                print("error making api request for artist \(artist.name)")
            }
        }
    }
    
    func getAlbumTracks(albums: [(Album, String)]) {
        Task {
            for album in albums {
                let urlString = "https://api.music.apple.com/v1/me/library/albums/\(album.1)/tracks"
                let requestURL = URL(string: urlString)!
                let urlRequest = URLRequest(url: requestURL)
                do {
                    let request = MusicDataRequest(urlRequest: urlRequest)
                    let response = try await request.response()
                    DispatchQueue.main.async {
                        self.matchTrackIDs(album: album.0, response: response)
                    }
                } catch {
                    print("error making api request")
                }
            }
        }
    }
    
    func matchTrackIDs(album: Album, response: MusicDataResponse) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: response.data, options: [])
            let trackArray = (jsonObject as? NSDictionary)?["data"] as! NSArray
            let coreDataTracks = Array(album.tracks as! Set<Track>)
            for track in trackArray {
                let artistNameFromResponse = ((track as? NSDictionary)?["attributes"] as? NSDictionary)?["artistName"] as! String
                let trackNameFromResponse = ((track as? NSDictionary)?["attributes"] as? NSDictionary)?["name"] as! String
                let trackNumberFromResponse = ((track as? NSDictionary)?["attributes"] as? NSDictionary)?["trackNumber"] as! Int
                let idFromResponse = (track as? NSDictionary)?["id"] as? String
                if let existingTrack = coreDataTracks.first(where: {
                    let coreDataTrackNum = $0.track_num ?? 0
                    let otherNum = NSNumber(value: trackNumberFromResponse)
                    return coreDataTrackNum.isEqual(to: otherNum)
                }) {
                    existingTrack.apple_music_persistent_id = idFromResponse!
                    print("matched \(trackNameFromResponse) by \(artistNameFromResponse) to \(existingTrack.name) by \(existingTrack.artist?.name)")
                } else {
                    print("no match")
                }
            }
            
        } catch {
            print(error)
        }
    }
    
    func matchAlbumIDs(artist: Artist, response: MusicDataResponse) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: response.data, options: [])
            let albumArray = (jsonObject as? NSDictionary)?["data"] as! NSArray
            let coreDataAlbums = Set(artist.tracks!.map({return ($0 as! Track).album!}))
            var albums = [(Album, String)]()
            for album in albumArray {
                let artistNameFromResponse = ((album as? NSDictionary)?["attributes"] as? NSDictionary)?["artistName"] as! String
                let albumNameFromResponse = ((album as? NSDictionary)?["attributes"] as? NSDictionary)?["name"] as! String
                let idFromResponse = (album as? NSDictionary)?["id"] as? String
                if let existingAlbum = coreDataAlbums.first(where: {$0.name!.localizedCaseInsensitiveCompare(albumNameFromResponse) == .orderedSame}) {
                    existingAlbum.apple_music_persistent_id = idFromResponse!
                    //now go match tracks for this album
                    albums.append((existingAlbum, existingAlbum.apple_music_persistent_id!))
                }
            }
            getAlbumTracks(albums: albums)
        } catch {
            print(error)
        }
    }
    
    /*func matchTrackIDs(artistID: String) async {
        let urlString = "https://api.music.apple.com/v1/me/library/artists/\(artistID)/albums"
        let requestURL = URL(string: urlString)!
        let urlRequest = URLRequest(url: requestURL)
        do {
            let request = MusicDataRequest(urlRequest: urlRequest)
            let response = try await request.response()
            let jsonObject = try JSONSerialization.jsonObject(with: response.data, options: [])
            let songsArray = ((jsonObject as? NSDictionary)?["results"] as? NSDictionary)
            print(jsonObject)
        } catch {
            print("error making api request")
        }
    }*/
    
    func requestResource(trackName: String, artistName: String, albumName: String) async -> String {
        var encodedTrackName = String(trackName.replacingOccurrences(of: " ", with: "+").replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "&", with: "").unicodeScalars.filter(CharacterSet.urlQueryAllowed.union(CharacterSet(charactersIn: "+")).contains))
        var encodedArtistName = String(artistName.replacingOccurrences(of: " ", with: "+").replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "&", with: "").unicodeScalars.filter(CharacterSet.urlQueryAllowed.union(CharacterSet(charactersIn: "+")).contains))
        if encodedTrackName.lengthOfBytes(using: .utf8) > 37 {
            let endIndex = encodedTrackName.index(encodedTrackName.startIndex, offsetBy: 37)
            encodedTrackName = String(encodedTrackName[..<endIndex])
        }
        encodedTrackName = encodedTrackName + "+" + encodedArtistName
        let urlString = "https://api.music.apple.com/v1/me/library/search?term=\(encodedTrackName)&types=library-songs&limit=25"
        let requestURL = URL(string: urlString)!
        //"DR.DOMESTIC'S+PHYSICAL+EFFECT+#1+-PIECE+FOR+TURNTABLES+AND+RECORDS"
        let urlRequest = URLRequest(url: requestURL)
        do {
            //form url
            let request = MusicDataRequest(urlRequest: urlRequest)
            let status = try await request.response()
            let trackID = self.determineTrackIDToPlay(response: status, trackName: trackName, artistName: artistName, albumName: albumName)
            return trackID
        } catch {
            print("error making api request")
            return ""
        }
    }
        
    func determineTrackIDToPlay(response: MusicDataResponse, trackName: String, artistName: String, albumName: String) -> String {
        do {
            //let's just take the top response for now
            let jsonObject = try JSONSerialization.jsonObject(with: response.data, options: [])
            guard let songsArray = ((((jsonObject as? NSDictionary)?["results"] as? NSDictionary)?["library-songs"] as? NSDictionary)?["data"] as? NSArray) else { return "" }
            var candidates = [String]()
            for song in songsArray {
                let song = song as! NSDictionary
                let attributes = song["attributes"] as! NSDictionary
                let name = attributes["name"] as! String
                let artistName = attributes["artistName"] as! String
                let albumName = attributes["albumName"] as! String
                if name.compare(trackName, options: [.diacriticInsensitive, .caseInsensitive]) == .orderedSame &&
                    artistName.compare(artistName, options: [.diacriticInsensitive, .caseInsensitive]) == .orderedSame &&
                    albumName.compare(albumName, options: [.diacriticInsensitive, .caseInsensitive]) == .orderedSame {
                    candidates.append(song["id"] as! String)
                }
            }
            if !candidates.isEmpty {
                return candidates.first!
            } else {
                return ""
            }
        } catch {
            return ""
        }
    }
    
    func determineArtistID(response: MusicDataResponse, initialQuery: String) -> String {
        do {
            //let's just take the top response for now
            let jsonObject = try JSONSerialization.jsonObject(with: response.data, options: [])
            guard let artistsArray = ((((jsonObject as? NSDictionary)?["results"] as? NSDictionary)?["library-artists"] as? NSDictionary)?["data"] as? NSArray) else { return "" }
            var candidates = [String]()
            for artist in artistsArray {
                let artist = artist as! NSDictionary
                let id = artist["id"] as! String
                candidates.append(id)
            }
            if !candidates.isEmpty {
                return candidates.first!
            } else {
                return ""
            }
        } catch {
            return ""
        }
    }
    
    
}
