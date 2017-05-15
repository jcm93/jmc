//
//  iTunesLibraryParser.swift
//  minimalTunes
//
//  Created by John Moody on 5/29/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

//Parses iTunes libraries and puts the metadata in Core Data

//note: source list items bound directly to library do NOT include headers. shared lib sources are then accessed by library.local_items

import Foundation
import CoreData
import Cocoa

class iTunesLibraryParser: NSObject {
    let libDict: NSMutableDictionary
    let XMLPlaylistArray: NSArray
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
    var addedAlbums = [String : Album]()
    var addedComposers = [String : Composer]()
    var addedTracks = [Int : Track]()
    
    func makeLibrary(parentLibrary: Library?, visualUpdateHandler: ProgressBarController?) {
        let subContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        subContext.parent = managedContext
        let library = subContext.object(with: parentLibrary!.objectID) as? Library
        let rootLibrary = subContext.object(with: globalRootLibrary!.objectID) as? Library
        let count = self.XMLTrackDictionaryDictionary.allKeys.count
        DispatchQueue.main.async {
            visualUpdateHandler?.prepareForNewTask(actionName: "Importing", thingName: "tracks", thingCount: count)
        }
        var index = 1
        for (key, value) in self.XMLTrackDictionaryDictionary {
            let cd_track = NSEntityDescription.insertNewObject(forEntityName: "Track", into: subContext) as! Track
            let new_track_view = NSEntityDescription.insertNewObject(forEntityName: "TrackView", into: subContext) as! TrackView
            cd_track.view = new_track_view
            cd_track.library = library
            if let trackDict = value as? NSDictionary {
                cd_track.id                 = (trackDict[iTunesImporterTrackIDKey] as! NSNumber)
                self.addedTracks[cd_track.id!.intValue] = cd_track
                cd_track.bpm                = trackDict[iTunesImporterBPMKey] as? NSNumber
                cd_track.movement_name      = trackDict[iTunesImporterMovementNameKey] as? String
                cd_track.movement_number    = trackDict[iTunesImporterMovementNumKey] as? NSNumber
                cd_track.file_kind          = trackDict[iTunesImporterTrackTypeKey] as? String
                cd_track.date_last_skipped  = trackDict[iTunesImporterSkipDateKey] as? NSDate
                cd_track.sample_rate        = trackDict[iTunesImporterSampleRateKey] as? NSNumber
                cd_track.file_kind          = trackDict[iTunesImporterKindKey] as? String
                cd_track.comments           = trackDict[iTunesImporterCommentsKey] as? String
                cd_track.date_last_played   = trackDict[iTunesImporterPlayDateUTCKey] as? NSDate
                cd_track.date_last_played   = trackDict[iTunesImporterPlayDateKey] as? NSDate
                cd_track.date_added         = trackDict[iTunesImporterDateAddedKey] as? NSDate
                cd_track.size               = trackDict[iTunesImporterSizeKey] as? NSNumber
                cd_track.disc_number        = trackDict[iTunesImporterDiscNumberKey] as? NSNumber
                cd_track.location           = trackDict[iTunesImporterLocationKey] as? String
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
                if let artistName           = trackDict[iTunesImporterArtistNameKey] as? String {
                    if let addedArtist = self.addedArtists[artistName] {
                        cd_track.artist = addedArtist
                    } else if let artistFromParentContext = checkIfArtistExists(artistName) {
                        cd_track.artist = subContext.object(with: artistFromParentContext.objectID) as? Artist
                    } else {
                        let newArtist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: subContext) as! Artist
                        newArtist.name = artistName
                        newArtist.id = rootLibrary!.next_artist_id
                        rootLibrary!.next_artist_id = rootLibrary!.next_artist_id!.intValue + 1 as NSNumber
                        cd_track.artist = newArtist
                        self.addedArtists[artistName] = newArtist
                    }
                }
                if let albumName            = trackDict[iTunesImporterAlbumNameKey] as? String {
                    if let addedAlbum = self.addedAlbums[albumName] {
                        cd_track.album = addedAlbum
                    } else if let albumFromParentContext = checkIfAlbumExists(albumName) {
                        cd_track.album = subContext.object(with: albumFromParentContext.objectID) as? Album
                    } else {
                        let newAlbum = NSEntityDescription.insertNewObject(forEntityName: "Album", into: subContext) as! Album
                        newAlbum.name = albumName
                        newAlbum.id = rootLibrary!.next_album_id
                        rootLibrary!.next_album_id = rootLibrary!.next_album_id!.intValue + 1 as NSNumber
                        cd_track.album = newAlbum
                        self.addedAlbums[albumName] = newAlbum
                    }
                }
                if let albumArtistName      = trackDict[iTunesImporterAlbumArtistKey] as? String {
                    if let addedArtist = self.addedArtists[albumArtistName] {
                        cd_track.album?.album_artist = addedArtist
                    } else if let artistFromParentContext = checkIfArtistExists(albumArtistName) {
                        cd_track.album?.album_artist = artistFromParentContext
                    } else {
                        let newArtist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: subContext) as! Artist
                        newArtist.name = albumArtistName
                        newArtist.id = rootLibrary!.next_artist_id
                        rootLibrary!.next_artist_id = rootLibrary!.next_artist_id!.intValue + 1 as NSNumber
                        cd_track.album?.album_artist = newArtist
                        self.addedArtists[albumArtistName] = newArtist
                    }
                }
                if let composerName         = trackDict[iTunesImporterComposerKey] as? String {
                    if let addedComposer = self.addedComposers[composerName] {
                        cd_track.composer = addedComposer
                    } else if let composerFromParentContext = checkIfComposerExists(composerName) {
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
                    var dateComponents = DateComponents()
                    dateComponents.year = year
                    dateComponents .calendar = Calendar(identifier: .gregorian)
                    cd_track.album?.release_date = dateComponents.date! as NSDate
                }
                if let releaseDate              = trackDict[iTunesImporterReleaseDateKey] as? NSDate {
                    if cd_track.album?.release_date == nil {
                        cd_track.album?.release_date = releaseDate
                    }
                }
                cd_track.album?.is_compilation = trackDict[iTunesImporterCompilationKey] as? NSNumber
                DispatchQueue.main.async {
                    visualUpdateHandler?.increment(thingsDone: index)
                }
                index += 1
            }
        }
        
        //create playlists
        let playlistsHeader: SourceListItem? = {
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "SourceListItem")
            let pr = NSPredicate(format: "name == 'Playlists' AND is_header == true")
            fr.predicate = pr
            do {
                let res = try managedContext.fetch(fr) as! [SourceListItem]
                return subContext.object(with: res[0].objectID) as! SourceListItem
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
                for stupidDict in playlistItems {
                    let trackID = (stupidDict as AnyObject).object(forKey: "Track ID") as! Int
                    if addedTracks[trackID]?.view != nil {
                        cd_playlist.addToTracks(addedTracks[trackID]!.view!)
                    }
                }
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
        for order in cachedOrders!.values.map({return subContext.object(with: $0.objectID) as! CachedOrder}){
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
            }
        }
    }
}
