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
    dynamic var numSongs: Int
    dynamic var numImportedSongs: Int = 0
    dynamic var numPlaylists: Int
    dynamic var numImportedPlaylists: Int = 0
    dynamic var numSorts: Int
    dynamic var numDoneSorts: Int = 0
    dynamic var doneSongs: Bool = false
    dynamic var doneSorting: Bool = false
    dynamic var donePlaylists: Bool = false
    dynamic var doneEverything: Bool = false
    let numCachedSorts = 6
    
    var moc: NSManagedObjectContext = {() -> NSManagedObjectContext in
        let mainContext = (NSApplication.sharedApplication().delegate as? AppDelegate)?.managedObjectContext
        let subContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        subContext.parentContext = mainContext
        return subContext
    }()
    
    let playlistImportConstant = 1
    let songImportConstant = 10
    let sortImportConstant = 10
    
    var artistSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_artist", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "sort_album", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "track_num", ascending:true), NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))]
    var albumSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_album", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "track_num", ascending: true), NSSortDescriptor(key: "sort_name", ascending:true, selector: #selector(NSString.localizedStandardCompare(_:)))]
    //var albumSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_album", ascending: true)]
    var dateAddedSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "date_added", ascending: true, selector: #selector(NSDate.compare(_:))), NSSortDescriptor(key: "sort_artist", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "sort_album", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "track_num", ascending:true)]
    var nameSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_name", ascending:true, selector: #selector(NSString.localizedStandardCompare(_:)))]
    var timeSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "time", ascending: true), NSSortDescriptor(key: "sort_name", ascending:true, selector: #selector(NSString.localizedStandardCompare(_:)))]
    
    
    init(path: String) throws {
        libDict = NSMutableDictionary(contentsOfFile: path)!
        XMLPlaylistArray = libDict.objectForKey("Playlists") as! NSArray
        XMLMasterPlaylistDict = XMLPlaylistArray[0] as! NSDictionary
        XMLMasterPlaylistTrackArray = XMLMasterPlaylistDict.objectForKey("Playlist Items") as! NSArray
        XMLTrackDictionaryDictionary = libDict.objectForKey("Tracks") as! NSDictionary
        numSongs = XMLMasterPlaylistTrackArray.count
        print(numSongs)
        numSorts = numSongs * numCachedSorts
        numPlaylists = XMLPlaylistArray.count
    }
    
    func instanceCheck(entity: String, instance: String, instanceName: Int, context: NSManagedObjectContext) -> NSManagedObject?
    {
        let request = NSFetchRequest(entityName: entity)
        request.predicate = NSPredicate(format: "\(instance) == \(instanceName)")
        
        do {
            let fetchedRecords = try context.executeFetchRequest(request) as! [NSManagedObject]
            if fetchedRecords.count == 0 {
                return nil
            }
            return fetchedRecords[0]
        } catch {
            // failure
            return nil
        }
    }
    
    var addedArtists = NSMutableDictionary()
    var addedAlbums = NSMutableDictionary()
    var addedComposers = NSMutableDictionary()
    var addedGenres = NSMutableDictionary()
    
    func importSortUIUpdate(index: Int) {
        if index % sortImportConstant == 0 {
            dispatch_async(dispatch_get_main_queue()) {
                self.numDoneSorts += self.sortImportConstant
            }
        }
    }
    func importPlaylistUIUpdate(index: Int) {
        if index % playlistImportConstant == 0 {
            dispatch_async(dispatch_get_main_queue()) {
                self.numImportedPlaylists += self.playlistImportConstant
            }
        }
    }
    func importSongUIUpdate(index: Int) {
        if index % sortImportConstant == 0 {
            dispatch_async(dispatch_get_main_queue()) {
                self.numImportedSongs += self.songImportConstant
            }
        }
    }
    
    func makeLibrary() {
        print("itunes parser here about to do stuff")
        
        moc.undoManager?.beginUndoGrouping()
        moc.performBlock() {
         
            //create the library entity
            let cd_library = NSEntityDescription.insertNewObjectForEntityForName("Library", inManagedObjectContext: self.moc) as! Library
            print("1")
            
            //create source list headers
            let cd_library_header = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: self.moc) as! SourceListItem
            cd_library_header.is_header = true
            cd_library_header.name = "Library"
            cd_library_header.sort_order = 0
            let cd_playlists_header = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: self.moc) as! SourceListItem
            cd_playlists_header.is_header = true
            cd_playlists_header.name = "Playlists"
            cd_playlists_header.sort_order = 2
            let cd_shared_header = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: self.moc) as! SourceListItem
            cd_shared_header.is_header = true
            cd_shared_header.name = "Shared Libraries"
            cd_shared_header.sort_order = 1
            print("2")
            
            //create column browser headers
            
            //create master playlist source list item
            let cd_library_master_playlist_source_item = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: self.moc) as! SourceListItem
            cd_library_master_playlist_source_item.parent = cd_library_header
            cd_library_master_playlist_source_item.name = "Music"
            cd_library_master_playlist_source_item.library = cd_library
            
            //create the master playlist
            let cd_library_master_playlist = NSEntityDescription.insertNewObjectForEntityForName("SongCollection", inManagedObjectContext: self.moc) as! SongCollection
            cd_library_master_playlist.name = "Master Playlist"
            
            //attach the master playlist to the master playlist source list entity
            cd_library_master_playlist.if_master_list_item = cd_library_master_playlist_source_item
            cd_library_master_playlist.if_master_library = cd_library
            print("3")
            for item in self.XMLMasterPlaylistTrackArray {
                let cd_track = NSEntityDescription.insertNewObjectForEntityForName("Track", inManagedObjectContext: self.moc) as! Track
                cd_library_master_playlist.addTracksObject(cd_track)
                let id = item.objectForKey("Track ID")?.description
                let XMLTrackDict = self.XMLTrackDictionaryDictionary.objectForKey(id!)
                var name, sort_name, artist, sort_artist, composer, sort_composer, album, sort_album, file_kind, genre, kind, comments, search_field, album_artist, location, movement_name, sort_album_artist: String
                var track_id, track_num, time, size, bit_rate, sample_rate, play_count, skip_count, rating, disc_num, movement_number, bpm, year: Int
                var date_released, date_modified, date_added, date_last_played, date_last_skipped: NSDate
                var status, compilation: Bool
                var placeholderArtist: Artist?
                var placeholderAlbum: Album?
                
                if (XMLTrackDict!.objectForKey("Track ID") != nil) {
                    track_id = XMLTrackDict!.objectForKey("Track ID") as! Int
                    cd_track.id = track_id
                }
                if (XMLTrackDict!.objectForKey("BPM") != nil) {
                    bpm = XMLTrackDict!.objectForKey("BPM") as! Int
                    cd_track.bpm = bpm
                }
                if (XMLTrackDict!.objectForKey("Movement Name") != nil) {
                    movement_name = XMLTrackDict!.objectForKey("Movement Name") as! String
                    cd_track.movement_name = movement_name
                }
                if (XMLTrackDict!.objectForKey("Movement Number") != nil) {
                    movement_number = XMLTrackDict!.objectForKey("Movement Number") as! Int
                    cd_track.movement_number = movement_number
                }
                if (XMLTrackDict!.objectForKey("Track Type") != nil) {
                    kind = XMLTrackDict!.objectForKey("Track Type") as! String
                    cd_track.file_kind = kind
                }
                if (XMLTrackDict!.objectForKey("Skip Date") != nil) {
                    date_last_skipped = XMLTrackDict!.objectForKey("Skip Date") as! NSDate
                    cd_track.date_last_skipped = date_last_skipped
                }
                if (XMLTrackDict!.objectForKey("Sample Rate") != nil) {
                    sample_rate = XMLTrackDict!.objectForKey("Sample Rate") as! Int
                    cd_track.sample_rate = sample_rate
                }
                if (XMLTrackDict!.objectForKey("Kind") != nil) {
                    file_kind = XMLTrackDict!.objectForKey("Kind") as! String
                    cd_track.file_kind = file_kind
                }
                if (XMLTrackDict!.objectForKey("Comments") != nil) {
                    comments = XMLTrackDict!.objectForKey("Comments") as! String
                    cd_track.comments = comments
                }
                if (XMLTrackDict!.objectForKey("Play Date UTC") != nil) {
                    date_last_played = XMLTrackDict!.objectForKey("Play Date UTC") as! NSDate
                    cd_track.date_last_played = date_last_played
                }
                else if (XMLTrackDict!.objectForKey("Play Date") != nil) {
                    date_last_played = XMLTrackDict!.objectForKey("Play Date") as! NSDate
                    cd_track.date_last_played = date_last_played
                }
                if (XMLTrackDict!.objectForKey("Date Added") != nil) {
                    date_added = XMLTrackDict!.objectForKey("Date Added") as! NSDate
                    cd_track.date_added = date_added
                }
                if (XMLTrackDict!.objectForKey("Size") != nil) {
                    size = XMLTrackDict!.objectForKey("Size") as! Int
                    cd_track.size = size
                }
                if (XMLTrackDict!.objectForKey("Disc Number") != nil) {
                    disc_num = XMLTrackDict!.objectForKey("Disc Number") as! Int
                    cd_track.disc_number = disc_num
                }

                if (XMLTrackDict!.objectForKey("Location") != nil) {
                    location = XMLTrackDict?.objectForKey("Location") as! String
                    cd_track.location = location
                }
                if (XMLTrackDict!.objectForKey("Artist") != nil) {
                    artist = XMLTrackDict!.objectForKey("Artist") as! String
                    if self.addedArtists.objectForKey(artist) != nil {
                        placeholderArtist = self.addedArtists.objectForKey(artist) as! Artist
                        cd_track.artist = placeholderArtist
                    }
                    else {
                        let new_artist = NSEntityDescription.insertNewObjectForEntityForName("Artist", inManagedObjectContext: self.moc) as! Artist
                        new_artist.name = artist
                        cd_track.artist = new_artist
                        placeholderArtist = new_artist
                        self.addedArtists.setValue(new_artist, forKey: artist)
                    }
                }
                if (XMLTrackDict!.objectForKey("Album") != nil) {
                    album = XMLTrackDict!.objectForKey("Album") as! String
                    if (self.addedAlbums.objectForKey(album) != nil) {
                        let the_album = self.addedAlbums.objectForKey(album)
                        placeholderArtist?.addAlbumsObject(the_album as! Album)
                        placeholderAlbum = the_album as! Album
                        cd_track.album = the_album as! Album
                        
                    }
                    else {
                        let new_album = NSEntityDescription.insertNewObjectForEntityForName("Album", inManagedObjectContext: self.moc) as! Album
                        new_album.name = album
                        cd_track.album = new_album
                        placeholderAlbum = new_album
                        self.addedAlbums.setValue(new_album, forKey: album)
                    }
                }
                if (XMLTrackDict!.objectForKey("Track Number") != nil) {
                    track_num = XMLTrackDict!.objectForKey("Track Number") as! Int
                    cd_track.track_num = track_num
                }
                if (XMLTrackDict!.objectForKey("Name") != nil) {
                    name = XMLTrackDict!.objectForKey("Name") as! String
                    cd_track.name = name
                }
                if (XMLTrackDict!.objectForKey("Album Artist") != nil) {
                    album_artist = XMLTrackDict!.objectForKey("Album Artist") as! String
                    if self.addedArtists.objectForKey(album_artist) != nil {
                        let the_album_artist = self.addedArtists.objectForKey(album_artist) as! Artist
                        placeholderAlbum?.album_artist = the_album_artist
                    }
                    else {
                        let new_album_artist = NSEntityDescription.insertNewObjectForEntityForName("Artist", inManagedObjectContext: self.moc) as! Artist
                        new_album_artist.name = album_artist
                        placeholderAlbum?.album_artist = new_album_artist
                        self.addedArtists.setValue(new_album_artist, forKey: album_artist)
                    }
                }
                if (XMLTrackDict!.objectForKey("Skip Count") != nil) {
                    skip_count = XMLTrackDict!.objectForKey("Skip Count") as! Int
                    cd_track.skip_count = skip_count
                }
                if (XMLTrackDict!.objectForKey("Play Count") != nil) {
                    play_count = XMLTrackDict!.objectForKey("Play Count") as! Int
                    cd_track.play_count = play_count
                }
                if (XMLTrackDict!.objectForKey("Bit Rate") != nil) {
                    bit_rate = XMLTrackDict!.objectForKey("Bit Rate") as! Int
                    cd_track.bit_rate = bit_rate
                }
                if (XMLTrackDict!.objectForKey("Total Time") != nil) {
                    time = XMLTrackDict!.objectForKey("Total Time") as! Int
                    cd_track.time = time
                }
                if (XMLTrackDict!.objectForKey("Date Modified") != nil) {
                    date_modified = XMLTrackDict!.objectForKey("Date Modified") as! NSDate
                    cd_track.date_modified = date_modified
                }
                if (XMLTrackDict!.objectForKey("Sort Album") != nil) {
                    sort_album = XMLTrackDict!.objectForKey("Sort Album") as! String
                    cd_track.sort_album = sort_album
                }
                else {
                    if cd_track.album != nil {
                        cd_track.sort_album = (cd_track.album! as Album).name
                    }
                }
                if (XMLTrackDict!.objectForKey("Genre") != nil) {
                    genre = XMLTrackDict!.objectForKey("Genre") as! String
                    if self.addedGenres.objectForKey(genre) != nil {
                        let the_genre = self.addedGenres.objectForKey(genre)
                        cd_track.genre = the_genre as! Genre
                    }
                    else {
                        let new_genre = NSEntityDescription.insertNewObjectForEntityForName("Genre", inManagedObjectContext: self.moc) as! Genre
                        new_genre.name = genre
                        cd_track.genre = new_genre
                        self.addedGenres.setValue(new_genre, forKey: genre)
                    }
                }
                if (XMLTrackDict!.objectForKey("Rating") != nil) {
                    rating = XMLTrackDict!.objectForKey("Rating") as! Int
                    cd_track.rating = rating
                }
                if (XMLTrackDict!.objectForKey("Sort Name") != nil) {
                    sort_name = XMLTrackDict!.objectForKey("Sort Name") as! String
                    cd_track.sort_name = sort_name
                }
                else {
                    cd_track.sort_name = cd_track.name
                }
                if (XMLTrackDict!.objectForKey("Release Date") != nil) {
                    date_released = XMLTrackDict!.objectForKey("Release Date") as! NSDate
                    cd_track.album?.release_date = date_released
                }
                if (XMLTrackDict!.objectForKey("Year") != nil) {
                    year = XMLTrackDict!.objectForKey("Year") as! Int
                    let date = NSDateComponents()
                    date.year = year
                    cd_track.album?.release_date = date.date
                }
                if (XMLTrackDict!.objectForKey("Composer") != nil) {
                    composer = XMLTrackDict!.objectForKey("Composer") as! String
                    if self.addedComposers.objectForKey(composer) != nil {
                        let the_composer = self.addedComposers.objectForKey(composer)
                        cd_track.composer = the_composer as! Composer
                    }
                    else {
                        let new_composer = NSEntityDescription.insertNewObjectForEntityForName("Composer", inManagedObjectContext: self.moc) as! Composer
                        new_composer.name = composer
                        cd_track.composer = new_composer
                        self.addedComposers.setValue(new_composer, forKey: composer)
                    }
                }
                if (XMLTrackDict!.objectForKey("Sort Composer") != nil) {
                    sort_composer = XMLTrackDict!.objectForKey("Sort Composer") as! String
                    cd_track.sort_composer = sort_composer
                }
                if (XMLTrackDict!.objectForKey("Disabled") != nil) {
                    status = XMLTrackDict!.objectForKey("Disabled") as! Bool
                    cd_track.status = status
                }
                if (XMLTrackDict!.objectForKey("Sort Artist") != nil) {
                    sort_artist = XMLTrackDict!.objectForKey("Sort Artist") as! String
                    cd_track.sort_artist = sort_artist
                }
                if (XMLTrackDict!.objectForKey("Sort Album Artist") != nil) {
                    sort_album_artist = XMLTrackDict!.objectForKey("Sort Album Artist") as! String
                    cd_track.sort_album_artist = sort_album_artist
                }
                //why was this ever here?
                /*else {
                    if (cd_track.artist != nil) {
                        cd_track.sort_artist = (cd_track.artist! as Artist).name
                    }
                }*/
                if (XMLTrackDict!.objectForKey("Compilation") != nil) {
                    compilation = XMLTrackDict!.objectForKey("Compilation") as! Bool
                    cd_track.album?.is_compilation = compilation
                }
                search_field = ""
                self.numImportedSongs += 1
                self.importSongUIUpdate(self.numImportedSongs)
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.doneSongs = true
                self.numSorts = self.numCachedSorts * self.numSongs
            }
            print("beginning sort")
            let poop = NSFetchRequest(entityName: "Track")
            var song_array = NSArray()
            poop.sortDescriptors = self.artistSortDescriptors
            let before = NSDate()
            do {
                try song_array = self.moc.executeFetchRequest(poop)
            }
            catch {
                print("err")
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.numImportedSongs = self.numSongs
            }
            let after = NSDate()
            let diff = after.timeIntervalSinceDate(before)
            print(diff)
            print(song_array.count)
            let cachedArtistOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: self.moc) as! CachedOrder
            let newCachedArtistOrder = NSEntityDescription.insertNewObjectForEntityForName("NewCachedOrder", inManagedObjectContext: self.moc) as! NewCachedOrder
            var newCachedArtistIDArray = [Int]()
            for (index, item) in song_array.enumerate() {
                (item as! Track).addOrdersObject(cachedArtistOrder)
                newCachedArtistIDArray.append(Int((item as! Track).id!))
                self.importSortUIUpdate(index)
            }
            newCachedArtistOrder.id_array = newCachedArtistIDArray
            newCachedArtistOrder.filtered_id_array = newCachedArtistIDArray
            newCachedArtistOrder.order = "Artist"
            cachedArtistOrder.order = "Artist"
            let cachedAlbumOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: self.moc) as! CachedOrder
            let newCachedAlbumOrder = NSEntityDescription.insertNewObjectForEntityForName("NewCachedOrder", inManagedObjectContext: self.moc) as! NewCachedOrder
            var newCachedAlbumIDArray = [Int]()
            song_array = song_array.sortedArrayUsingDescriptors(self.albumSortDescriptors)
            for (index, item) in song_array.enumerate() {
                (item as! Track).addOrdersObject(cachedAlbumOrder)
                newCachedAlbumIDArray.append(Int((item as! Track).id!))
                self.importSortUIUpdate(index)
            }
            newCachedAlbumOrder.id_array = newCachedAlbumIDArray
            newCachedAlbumOrder.filtered_id_array = newCachedAlbumIDArray
            newCachedAlbumOrder.order = "Album"
            cachedAlbumOrder.order = "Album"
            let dateAddedOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: self.moc) as! CachedOrder
            let newCachedDateAddedOrder = NSEntityDescription.insertNewObjectForEntityForName("NewCachedOrder", inManagedObjectContext: self.moc) as! NewCachedOrder
            var newCachedDateAddedIDArray = [Int]()
            song_array = song_array.sortedArrayUsingDescriptors(self.dateAddedSortDescriptors)
            for (index, item) in song_array.enumerate() {
                (item as! Track).addOrdersObject(dateAddedOrder)
                newCachedDateAddedIDArray.append(Int((item as! Track).id!))
                self.importSortUIUpdate(index)
            }
            newCachedDateAddedOrder.id_array = newCachedDateAddedIDArray
            newCachedDateAddedOrder.filtered_id_array = newCachedDateAddedIDArray
            newCachedDateAddedOrder.order = "Date Added"
            dateAddedOrder.order = "Date Added"
            song_array = song_array.sortedArrayUsingDescriptors(self.timeSortDescriptors)
            let cachedTimeOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: self.moc) as! CachedOrder
            let newCachedTimeOrder = NSEntityDescription.insertNewObjectForEntityForName("NewCachedOrder", inManagedObjectContext: self.moc) as! NewCachedOrder
            var newCachedTimeIDArray = [Int]()
            for (index, item) in song_array.enumerate() {
                (item as! Track).addOrdersObject(cachedTimeOrder)
                newCachedTimeIDArray.append(Int((item as! Track).id!))
                self.importSortUIUpdate(index)
            }
            newCachedTimeOrder.id_array = newCachedTimeIDArray
            newCachedTimeOrder.filtered_id_array = newCachedTimeIDArray
            newCachedTimeOrder.order = "Time"
            cachedTimeOrder.order = "Time"
            
            song_array = song_array.sortedArrayUsingDescriptors(self.nameSortDescriptors)
            let cachedNameOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: self.moc) as! CachedOrder
            let newCachedNameOrder = NSEntityDescription.insertNewObjectForEntityForName("NewCachedOrder", inManagedObjectContext: self.moc) as! NewCachedOrder
            var newCachedNameIDArray = [Int]()
            for (index, item) in song_array.enumerate() {
                (item as! Track).addOrdersObject(cachedNameOrder)
                newCachedNameIDArray.append(Int((item as! Track).id!))
                self.importSortUIUpdate(index)
            }
            newCachedNameOrder.id_array = newCachedNameIDArray
            newCachedNameOrder.filtered_id_array = newCachedNameIDArray
            newCachedNameOrder.order = "Name"
            cachedNameOrder.order = "Name"

            print("done sorting")
            dispatch_async(dispatch_get_main_queue()) {
                self.doneSorting = true
            }
            
            //create playlists
            for playlistDict in self.XMLPlaylistArray {
                let cd_playlist = NSEntityDescription.insertNewObjectForEntityForName("SongCollection", inManagedObjectContext: self.moc) as! SongCollection
                cd_playlist.name = playlistDict.objectForKey("Name") as? String
                cd_playlist.id = playlistDict.objectForKey("Playlist ID") as! Int
                let playlistItems: NSArray
                if (playlistDict.objectForKey("Playlist Items") != nil) {
                    playlistItems = playlistDict.objectForKey("Playlist Items") as! NSArray
                    var track_list = [Int]()
                    for stupidDict in playlistItems {
                        let trackID = stupidDict.objectForKey("Track ID") as! Int
                        track_list.append(trackID)
                    }
                    cd_playlist.track_id_list = track_list
                }

                //create source list item for playlist
                let cd_playlist_source_list_item = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: self.moc) as! SourceListItem
                cd_playlist_source_list_item.parent = cd_playlists_header
                cd_playlist_source_list_item.name = cd_playlist.name
                cd_playlist_source_list_item.playlist = cd_playlist
                cd_playlist_source_list_item.library = cd_library
                self.importPlaylistUIUpdate(self.numImportedPlaylists)
            }
            
            //create shared library examples
            let cd_shared_library = NSEntityDescription.insertNewObjectForEntityForName("SharedLibrary", inManagedObjectContext: self.moc) as! SharedLibrary
            cd_shared_library.address = "example 1"
            
            let cd_shared_library_source_list_item = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: self.moc) as! SourceListItem
            cd_shared_library_source_list_item.is_network = true
            cd_shared_library_source_list_item.name = "Example Shared Library"
            cd_shared_library_source_list_item.parent = cd_shared_header
            
            let cd_shared_library_two = NSEntityDescription.insertNewObjectForEntityForName("SharedLibrary", inManagedObjectContext: self.moc) as! SharedLibrary
            cd_shared_library_two.address = "example 2"
            
            let cd_shared_library_source_list_item_two = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: self.self.moc) as! SourceListItem
            cd_shared_library_source_list_item_two.is_network = true
            cd_shared_library_source_list_item_two.name = "Example Shared Library 2"
            cd_shared_library_source_list_item_two.parent = cd_shared_header
            self.self.moc.undoManager?.endUndoGrouping()
            do {
                try self.moc.save()
                print("done saving subcontext")
            } catch {
                print("error: \(error)")
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.doneEverything = true
                print("ituens parser done clause")
            }
        }
    }
}