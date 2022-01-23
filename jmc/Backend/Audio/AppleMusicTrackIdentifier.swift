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
        print("patooties")
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
    
    
}
