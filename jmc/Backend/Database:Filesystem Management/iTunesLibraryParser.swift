//
//  iTunesLibraryParser.swift
//  minimalTunes
//
//  Created by John Moody on 5/29/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

//Parses iTunes libraries and puts the metadata in Core Data

import Foundation
import CoreData
import Cocoa

class iTunesLibraryParser: NSObject {
    let libDict: NSMutableDictionary
    var XMLPlaylistArray: NSArray
    let XMLMasterPlaylistDict: NSDictionary
    let XMLMasterPlaylistTrackArray: NSArray
    let XMLTrackDictionaryDictionary: NSDictionary
    
    
    init(path: String) throws {
        libDict = NSMutableDictionary(contentsOfFile: path)!
        XMLPlaylistArray = libDict.object(forKey: "Playlists") as! NSArray
        XMLMasterPlaylistDict = XMLPlaylistArray[0] as! NSDictionary
        XMLMasterPlaylistTrackArray = XMLMasterPlaylistDict.object(forKey: "Playlist Items") as! NSArray
        XMLTrackDictionaryDictionary = libDict.object(forKey: "Tracks") as! NSDictionary
    }
    
    var addedArtists = [String : Artist]()
    var addedAlbums = [Artist : [String : Album]]()
    var addedComposers = [String : Composer]()
    var addedTracks = [Int : Track]()
    var albumsWithUnknownArtists = [Album]()
    
    func makeLibrary(parentLibrary: Library?, visualUpdateHandler: ProgressBarController?, subContext: NSManagedObjectContext) {
        //volume?
        let library = subContext.object(with: parentLibrary!.objectID) as? Library
        let rootLibrary = subContext.object(with: globalRootLibrary!.objectID) as? Library
        let count = self.XMLTrackDictionaryDictionary.allKeys.count
        var kinds = [String : [Track]]()
        DispatchQueue.main.async {
            visualUpdateHandler?.prepareForNewTask(actionName: "Importing", thingName: "tracks", thingCount: count)
        }
        var index = 1
        for (key, value) in self.XMLTrackDictionaryDictionary {
            if let trackDict = value as? NSDictionary, trackDict[iTunesImporterTrackTypeKey] as? String != "URL" {
                guard let location = trackDict[iTunesImporterLocationKey] as? String else { continue }
                guard let file_kind = trackDict[iTunesImporterKindKey] as? String, file_kind != "Protected AAC audio file" else {
                    continue
                }
                let cd_track = NSEntityDescription.insertNewObject(forEntityName: "Track", into: subContext) as! Track
                let new_track_view = NSEntityDescription.insertNewObject(forEntityName: "TrackView", into: subContext) as! TrackView
                cd_track.view = new_track_view
                cd_track.library = library
                cd_track.id                 = (trackDict[iTunesImporterTrackIDKey] as! NSNumber)
                self.addedTracks[cd_track.id!.intValue] = cd_track
                cd_track.bpm                = trackDict[iTunesImporterBPMKey] as? NSNumber
                cd_track.movement_name      = trackDict[iTunesImporterMovementNameKey] as? String
                cd_track.movement_number    = trackDict[iTunesImporterMovementNumKey] as? NSNumber
                cd_track.file_kind          = trackDict[iTunesImporterTrackTypeKey] as? String
                cd_track.date_last_skipped  = trackDict[iTunesImporterSkipDateKey] as? NSDate
                cd_track.sample_rate        = trackDict[iTunesImporterSampleRateKey] as? NSNumber
                cd_track.file_kind          = file_kind
                cd_track.comments           = trackDict[iTunesImporterCommentsKey] as? String
                cd_track.date_last_played   = trackDict[iTunesImporterPlayDateUTCKey] as? NSDate
                cd_track.date_last_played   = trackDict[iTunesImporterPlayDateKey] as? NSDate
                cd_track.date_added         = trackDict[iTunesImporterDateAddedKey] as? NSDate
                cd_track.size               = trackDict[iTunesImporterSizeKey] as? NSNumber
                cd_track.disc_number        = trackDict[iTunesImporterDiscNumberKey] as? NSNumber
                cd_track.location           = location
                cd_track.track_num          = trackDict[iTunesImporterTrackNumberKey] as? NSNumber
                cd_track.name               = trackDict[iTunesImporterNameKey] as? String
                cd_track.skip_count         = trackDict[iTunesImporterSkipCountKey] as? NSNumber
                cd_track.play_count         = trackDict[iTunesImporterPlayCountKey] as? NSNumber
                cd_track.bit_rate           = trackDict[iTunesImporterBitRateKey] as? NSNumber
                cd_track.time               = trackDict[iTunesImporterTotalTimeKey] as? NSNumber
                cd_track.date_modified      = trackDict[iTunesImporterDateModifiedKey] as? NSDate
                cd_track.sort_album         = trackDict[iTunesImporterSortAlbumKey] as? String
                cd_track.genre              = trackDict[iTunesImporterGenreKey] as? String
                cd_track.rating             = trackDict[iTunesImporterRatingKey] as? NSNumber
                cd_track.sort_name          = trackDict[iTunesImporterSortNameKey] as? String
                cd_track.sort_composer      = trackDict[iTunesImporterSortComposerKey] as? String
                cd_track.status             = trackDict[iTunesImporterDisabledKey] as? NSNumber
                cd_track.sort_artist        = trackDict[iTunesImporterSortArtistKey] as? String
                cd_track.sort_album_artist  = trackDict[iTunesImporterSortAlbumArtistKey] as? String
                let artistName              = trackDict[iTunesImporterArtistNameKey] as? String ?? ""
                if let addedArtist = self.addedArtists[artistName] {
                    cd_track.artist = addedArtist
                } else if let artistFromParentContext = checkIfArtistExists(artistName, subcontext: subContext) {
                    cd_track.artist = subContext.object(with: artistFromParentContext.objectID) as? Artist
                } else {
                    let newArtist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: subContext) as! Artist
                    newArtist.name = artistName
                    newArtist.id = rootLibrary!.next_artist_id
                    rootLibrary!.next_artist_id = rootLibrary!.next_artist_id!.intValue + 1 as NSNumber
                    cd_track.artist = newArtist
                    self.addedArtists[artistName] = newArtist
                }
                let albumName               = trackDict[iTunesImporterAlbumNameKey] as? String ?? ""
                if let addedAlbum = self.addedAlbums[cd_track.artist!]?[albumName] {
                    cd_track.album = addedAlbum
                } else if let albumFromParentContext = checkIfAlbumExists(withName: albumName, withArtist: cd_track.artist!, subcontext: subContext) {
                    cd_track.album = subContext.object(with: albumFromParentContext.objectID) as? Album
                } else {
                    let newAlbum = NSEntityDescription.insertNewObject(forEntityName: "Album", into: subContext) as! Album
                    newAlbum.name = albumName
                    newAlbum.id = rootLibrary!.next_album_id
                    rootLibrary!.next_album_id = rootLibrary!.next_album_id!.intValue + 1 as NSNumber
                    cd_track.album = newAlbum
                    if self.addedAlbums[cd_track.artist!] == nil {
                        self.addedAlbums[cd_track.artist!] = [String : Album]()
                    }
                    self.addedAlbums[cd_track.artist!]![albumName] = newAlbum
                }
                //fix
                if let albumArtistName         = trackDict[iTunesImporterAlbumArtistKey] as? String {
                    if let addedArtist = self.addedArtists[albumArtistName] {
                        cd_track.album?.album_artist = addedArtist
                    } else if let artistFromParentContext = checkIfArtistExists(albumArtistName, subcontext: subContext) {
                        cd_track.album?.album_artist = subContext.object(with: artistFromParentContext.objectID) as? Artist
                    } else {
                        let newArtist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: subContext) as! Artist
                        newArtist.name = albumArtistName
                        newArtist.id = rootLibrary!.next_artist_id
                        rootLibrary!.next_artist_id = rootLibrary!.next_artist_id!.intValue + 1 as NSNumber
                        cd_track.album?.album_artist = newArtist
                        self.addedArtists[albumArtistName] = newArtist
                    }
                } else {
                    //assign album artist later
                    albumsWithUnknownArtists.append(cd_track.album!)
                }
                if let composerName         = trackDict[iTunesImporterComposerKey] as? String {
                    if let addedComposer = self.addedComposers[composerName] {
                        cd_track.composer = addedComposer
                    } else if let composerFromParentContext = checkIfComposerExists(composerName, subcontext: subContext) {
                        cd_track.composer = subContext.object(with: composerFromParentContext.objectID) as? Composer
                    } else {
                        let newComposer = NSEntityDescription.insertNewObject(forEntityName: "Composer", into: subContext) as! Composer
                        newComposer.name = composerName
                        newComposer.id = rootLibrary!.next_composer_id
                        rootLibrary!.next_composer_id = rootLibrary!.next_composer_id!.intValue + 1 as NSNumber
                        cd_track.composer = newComposer
                        self.addedComposers[composerName] = newComposer
                    }
                }
                if let year                 = trackDict[iTunesImporterYearKey] as? Int {
                    let date = JMDate(year: year)
                    cd_track.album?.release_date = date
                }
                if let releaseDate              = trackDict[iTunesImporterReleaseDateKey] as? NSDate {
                    if cd_track.album?.release_date == nil {
                        let date = JMDate(date: releaseDate)
                        cd_track.album?.release_date = date
                    }
                }
                cd_track.album?.is_compilation = trackDict[iTunesImporterCompilationKey] as? NSNumber
                DispatchQueue.main.async {
                    visualUpdateHandler?.increment(thingsDone: index)
                }
                /*if kinds[file_kind] != nil {
                    kinds[file_kind]!.append(cd_track)
                } else {
                    kinds[file_kind] = [Track]()
                    kinds[file_kind]!.append(cd_track)
                }*/
                index += 1
            }
        }
        /*if let purchasedTracks = kinds["Protected AAC audio file"] {
            for track in purchasedTracks {
                //delete this track
                print("dooblekjjkt")
            }
        }*/
        index = 0
        DispatchQueue.main.async {
            visualUpdateHandler?.prepareForNewTask(actionName: "Messing with", thingName: "albums", thingCount: self.albumsWithUnknownArtists.count)
        }
        for album in albumsWithUnknownArtists {
            let countSet = NSCountedSet(array: (album.tracks as! Set<Track>).map({return $0.artist!}))
            let mostFrequentArtist = countSet.max(by: {return countSet.count(for: $0) < countSet.count(for: $1)}) as! Artist
            album.album_artist = mostFrequentArtist
            index += 1
            DispatchQueue.main.async {
                visualUpdateHandler?.increment(thingsDone: index)
            }
            let sortName = getSortName(mostFrequentArtist.name!)
            for track in album.tracks! {
                let track = track as! Track
                track.sort_album_artist = sortName
            }
        }
        
        //create playlists
        let playlistsHeader: SourceListItem? = {
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "SourceListItem")
            let pr = NSPredicate(format: "name == 'Playlists' AND is_header == true")
            fr.predicate = pr
            do {
                let res = try subContext.fetch(fr) as! [SourceListItem]
                return res[0]
            } catch {
                print(error)
            }
            return nil
        }()
        index = 0
        DispatchQueue.main.async {
            visualUpdateHandler?.prepareForNewTask(actionName: "Importing", thingName: "playlists", thingCount: self.XMLPlaylistArray.count)
        }
        for thing in self.XMLPlaylistArray {
            let playlistDictionary = thing as! NSDictionary
            let cd_playlist = NSEntityDescription.insertNewObject(forEntityName: "SongCollection", into: subContext) as! SongCollection
            cd_playlist.name = playlistDictionary["Name"] as? String
            cd_playlist.id = playlistDictionary["Playlist ID"] as? NSNumber
            if let playlistItems = playlistDictionary["Playlist Items"] as? NSArray {
                let playlistTrackViews = playlistItems.compactMap({return self.addedTracks[($0 as AnyObject).object(forKey: "Track ID") as! Int]?.view})
                cd_playlist.addToTracks(playlistTrackViews)
            }
            
            //create source list item for playlist
            let cd_playlist_source_list_item = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: subContext) as! SourceListItem
            cd_playlist_source_list_item.parent = playlistsHeader!
            cd_playlist_source_list_item.name = cd_playlist.name
            cd_playlist_source_list_item.playlist = subContext.object(with: cd_playlist.objectID) as? SongCollection
            DispatchQueue.main.async {
                visualUpdateHandler?.increment(thingsDone: index)
            }
            index += 1
        }
        
        do {
            try subContext.save()
        } catch {
            print(error)
        }
        let trackArray = Array(addedTracks.values)
        DispatchQueue.main.async {
            visualUpdateHandler?.prepareForNewTask(actionName: "Reordering", thingName: "sort caches", thingCount: cachedOrders!.count)
        }
        index = 0
        let orders = getCachedOrders(for: subContext)
        for order in orders!.values {
            reorderForTracks(trackArray, cachedOrder: order, subContext: subContext)
            DispatchQueue.main.async {
                visualUpdateHandler?.increment(thingsDone: index)
            }
            index += 1
        }
        do {
            try subContext.save()
        } catch {
            print(error)
        }
        DispatchQueue.main.async {
            visualUpdateHandler?.makeIndeterminate(actionName: "Committing changes...")
            DispatchQueue.main.async {
                do {
                    try managedContext.save()
                    print("done saving main context")
                } catch {
                    print("error: \(error)")
                }
                let highestTrackID = (getInstanceWithHighestIDForEntity("Track") as! Track).id
                (managedContext.object(with: library!.objectID) as! Library).next_track_id = highestTrackID
                
                let highestPlaylistID = (getInstanceWithHighestIDForEntity("SongCollection") as! SongCollection).id
                (managedContext.object(with: library!.objectID) as! Library).next_playlist_id = highestPlaylistID
                visualUpdateHandler?.finish()
                (NSApp.delegate as! AppDelegate).doneImportingiTunesLibrary()
            }
        }
    }
}
