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
            print("3")
            for item in self.XMLMasterPlaylistTrackArray {
                let cd_track = NSEntityDescription.insertNewObjectForEntityForName("Track", inManagedObjectContext: self.moc) as! Track
                //cd_library_master_playlist.addTracksObject(cd_track)
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
                if (XMLTrackDict!.objectForKey("Compilation") != nil) {
                    compilation = XMLTrackDict!.objectForKey("Compilation") as! Bool
                    cd_track.album?.is_compilation = compilation
                }
                search_field = ""
                self.numImportedSongs += 1
                self.importSongUIUpdate(self.numImportedSongs)
                let new_track_view = NSEntityDescription.insertNewObjectForEntityForName("TrackView", inManagedObjectContext: self.moc) as! TrackView
                new_track_view.track = cd_track
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.doneSongs = true
                self.numSorts = self.numCachedSorts * self.numSongs
            }
            print("beginning sort")
            let poop = NSFetchRequest(entityName: "Track")
            var song_array = NSArray()
            poop.sortDescriptors = artistSortDescriptors
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
            song_array = song_array.sortedArrayUsingSelector(#selector(Track.compareArtist))
            let cachedArtistOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: self.moc) as! CachedOrder

            for (index, item) in song_array.enumerate() {
                (item as! Track).view!.addOrdersObject(cachedArtistOrder)
                (item as! Track).view?.artist_order = index
                self.importSortUIUpdate(index)
            }
            cachedArtistOrder.order = "Artist"
            
            let cachedAlbumOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: self.moc) as! CachedOrder
            song_array = song_array.sortedArrayUsingSelector(#selector(Track.compareAlbum(_:)))
            for (index, item) in song_array.enumerate() {
                (item as! Track).view!.addOrdersObject(cachedAlbumOrder)
                (item as! Track).view?.album_order = index
                self.importSortUIUpdate(index)
            }
            cachedAlbumOrder.order = "Album"
            
            let dateAddedOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: self.moc) as! CachedOrder
            song_array = song_array.sortedArrayUsingSelector(#selector(Track.compareDateAdded(_:)))
            for (index, item) in song_array.enumerate() {
                (item as! Track).view!.addOrdersObject(dateAddedOrder)
                (item as! Track).view?.date_added_order = index
                self.importSortUIUpdate(index)
            }
            dateAddedOrder.order = "Date Added"
            
            song_array = song_array.sortedArrayUsingSelector(#selector(Track.compareAlbumArtist(_:)))
            let cachedAlbumArtistOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: self.moc) as! CachedOrder
            for (index, item) in song_array.enumerate() {
                (item as! Track).view!.addOrdersObject(cachedAlbumArtistOrder)
                (item as! Track).view?.album_artist_order = index
                self.importSortUIUpdate(index)
            }
            cachedAlbumArtistOrder.order = "Album Artist"
            
            song_array = song_array.sortedArrayUsingSelector(#selector(Track.compareKind(_:)))
            let cachedKindOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: self.moc) as! CachedOrder
            for (index, item) in song_array.enumerate() {
                (item as! Track).view!.addOrdersObject(cachedKindOrder)
                (item as! Track).view?.kind_order = index
                self.importSortUIUpdate(index)
            }
            cachedKindOrder.order = "Kind"
            
            song_array = song_array.sortedArrayUsingSelector(#selector(Track.compareDateReleased(_:)))
            let cachedDateReleasedOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: self.moc) as! CachedOrder
            for (index, item) in song_array.enumerate() {
                (item as! Track).view!.addOrdersObject(cachedDateReleasedOrder)
                (item as! Track).view?.release_date_order = index
                self.importSortUIUpdate(index)
            }
            cachedDateReleasedOrder.order = "Date Released"
            
            song_array = song_array.sortedArrayUsingSelector(#selector(Track.compareGenre(_:)))
            let cachedGenreOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: self.moc) as! CachedOrder
            for (index, item) in song_array.enumerate() {
                (item as! Track).view!.addOrdersObject(cachedGenreOrder)
                (item as! Track).view?.genre_order = index
                self.importSortUIUpdate(index)
            }
            cachedGenreOrder.order = "Genre"
            
            song_array = song_array.sortedArrayUsingSelector(#selector(Track.compareName(_:)))
            let cachedNameOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: self.moc) as! CachedOrder
            for (index, item) in song_array.enumerate() {
                (item as! Track).view!.addOrdersObject(cachedNameOrder)
                (item as! Track).view?.name_order = index
                self.importSortUIUpdate(index)
            }
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
                
                let playlistsHeader: SourceListItem? = {
                    let fr = NSFetchRequest(entityName: "SourceListItem")
                    let pr = NSPredicate(format: "name == 'Playlists' AND is_header == true")
                    fr.predicate = pr
                    do {
                        let res = try managedContext.executeFetchRequest(fr) as! [SourceListItem]
                        return res[0]
                    } catch {
                        print(error)
                    }
                    return nil
                }()

                //create source list item for playlist
                let cd_playlist_source_list_item = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: self.moc) as! SourceListItem
                cd_playlist_source_list_item.parent = playlistsHeader!
                cd_playlist_source_list_item.name = cd_playlist.name
                cd_playlist_source_list_item.playlist = cd_playlist
                //cd_playlist_source_list_item.library = cd_library
                self.importPlaylistUIUpdate(self.numImportedPlaylists)
            }
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