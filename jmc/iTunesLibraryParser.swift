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
    
    let playlistImportConstant = 1
    let songImportConstant = 10
    let sortImportConstant = 10
    
    
    init(path: String) throws {
        libDict = NSMutableDictionary(contentsOfFile: path)!
        XMLPlaylistArray = libDict.object(forKey: "Playlists") as! NSArray
        XMLMasterPlaylistDict = XMLPlaylistArray[0] as! NSDictionary
        XMLMasterPlaylistTrackArray = XMLMasterPlaylistDict.object(forKey: "Playlist Items") as! NSArray
        XMLTrackDictionaryDictionary = libDict.object(forKey: "Tracks") as! NSDictionary
        numSongs = XMLMasterPlaylistTrackArray.count
        print(numSongs)
        numSorts = numSongs * numCachedSorts
        numPlaylists = XMLPlaylistArray.count
    }
    
    func instanceCheck(_ entity: String, instance: String, instanceName: Int, context: NSManagedObjectContext) -> NSManagedObject?
    {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        request.predicate = NSPredicate(format: "\(instance) == \(instanceName)")
        
        do {
            let fetchedRecords = try context.fetch(request) as! [NSManagedObject]
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
    
    func importSortUIUpdate(_ index: Int) {
        if index % sortImportConstant == 0 {
            DispatchQueue.main.async {
                self.numDoneSorts += self.sortImportConstant
            }
        }
    }
    func importPlaylistUIUpdate(_ index: Int) {
        if index % playlistImportConstant == 0 {
            DispatchQueue.main.async {
                self.numImportedPlaylists += self.playlistImportConstant
            }
        }
    }
    func importSongUIUpdate(_ index: Int) {
        if index % sortImportConstant == 0 {
            DispatchQueue.main.async {
                self.numImportedSongs += self.songImportConstant
            }
        }
    }
    
    func makeLibrary(library: Library?) {
        print("itunes parser here about to do stuff")
        managedContext.undoManager?.beginUndoGrouping()
        print("3")
        for item in self.XMLMasterPlaylistTrackArray {
            //cd_library_master_playlist.addTracksObject(cd_track)
            let id = ((item as AnyObject).object(forKey: "Track ID") as AnyObject).description
            let XMLTrackDict = self.XMLTrackDictionaryDictionary.object(forKey: id!)
            let cd_track = NSEntityDescription.insertNewObject(forEntityName: "Track", into: managedContext) as! Track
            var name, sort_name, artist, sort_artist, composer, sort_composer, album, sort_album, file_kind, genre, kind, comments, search_field, album_artist, location, movement_name, sort_album_artist: String
            var track_id, track_num, time, size, bit_rate, sample_rate, play_count, skip_count, rating, disc_num, movement_number, bpm, year: Int
            var date_released, date_modified, date_added, date_last_played, date_last_skipped: Date
            var status, compilation: Bool
            var placeholderArtist: Artist?
            var placeholderAlbum: Album?
            cd_track.library = library
            if ((XMLTrackDict! as AnyObject).object(forKey: "Track ID") != nil) {
                track_id = (XMLTrackDict! as AnyObject).object(forKey: "Track ID") as! Int
                cd_track.id = track_id as NSNumber?
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "BPM") != nil) {
                bpm = (XMLTrackDict! as AnyObject).object(forKey: "BPM") as! Int
                cd_track.bpm = bpm as NSNumber?
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Movement Name") != nil) {
                movement_name = (XMLTrackDict! as AnyObject).object(forKey: "Movement Name") as! String
                cd_track.movement_name = movement_name
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Movement Number") != nil) {
                movement_number = (XMLTrackDict! as AnyObject).object(forKey: "Movement Number") as! Int
                cd_track.movement_number = movement_number as NSNumber?
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Track Type") != nil) {
                kind = (XMLTrackDict! as AnyObject).object(forKey: "Track Type") as! String
                cd_track.file_kind = kind
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Skip Date") != nil) {
                date_last_skipped = (XMLTrackDict! as AnyObject).object(forKey: "Skip Date") as! Date
                cd_track.date_last_skipped = date_last_skipped as NSDate
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Sample Rate") != nil) {
                sample_rate = (XMLTrackDict! as AnyObject).object(forKey: "Sample Rate") as! Int
                cd_track.sample_rate = sample_rate as NSNumber?
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Kind") != nil) {
                file_kind = (XMLTrackDict! as AnyObject).object(forKey: "Kind") as! String
                cd_track.file_kind = file_kind
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Comments") != nil) {
                comments = (XMLTrackDict! as AnyObject).object(forKey: "Comments") as! String
                cd_track.comments = comments
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Play Date UTC") != nil) {
                date_last_played = (XMLTrackDict! as AnyObject).object(forKey: "Play Date UTC") as! Date
                cd_track.date_last_played = date_last_played as NSDate
            }
            else if ((XMLTrackDict! as AnyObject).object(forKey: "Play Date") != nil) {
                date_last_played = (XMLTrackDict! as AnyObject).object(forKey: "Play Date") as! Date
                cd_track.date_last_played = date_last_played as NSDate
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Date Added") != nil) {
                date_added = (XMLTrackDict! as AnyObject).object(forKey: "Date Added") as! Date
                cd_track.date_added = date_added as NSDate
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Size") != nil) {
                size = (XMLTrackDict! as AnyObject).object(forKey: "Size") as! Int
                cd_track.size = size as NSNumber?
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Disc Number") != nil) {
                disc_num = (XMLTrackDict! as AnyObject).object(forKey: "Disc Number") as! Int
                cd_track.disc_number = disc_num as NSNumber?
            }

            if ((XMLTrackDict! as AnyObject).object(forKey: "Location") != nil) {
                location = (XMLTrackDict as AnyObject).object(forKey: "Location") as! String
                cd_track.location = location
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Artist") != nil) {
                artist = (XMLTrackDict! as AnyObject).object(forKey: "Artist") as! String
                if self.addedArtists.object(forKey: artist) != nil {
                    placeholderArtist = self.addedArtists.object(forKey: artist) as! Artist
                    cd_track.artist = placeholderArtist
                }
                else {
                    let new_artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: managedContext) as! Artist
                    new_artist.name = artist
                    cd_track.artist = new_artist
                    new_artist.id = library?.next_artist_id
                    library?.next_artist_id = Int(library!.next_artist_id!) + 1 as NSNumber
                    placeholderArtist = new_artist
                    self.addedArtists.setValue(new_artist, forKey: artist)
                }
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Album") != nil) {
                album = (XMLTrackDict! as AnyObject).object(forKey: "Album") as! String
                if (self.addedAlbums.object(forKey: album) != nil) {
                    let the_album = self.addedAlbums.object(forKey: album)
                    placeholderArtist?.addAlbumsObject(the_album as! Album)
                    placeholderAlbum = the_album as! Album
                    cd_track.album = the_album as! Album
                    
                }
                else {
                    let new_album = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
                    new_album.name = album
                    cd_track.album = new_album
                    new_album.id = library?.next_album_id
                    library?.next_album_id = Int(library!.next_album_id!) + 1 as NSNumber
                    placeholderAlbum = new_album
                    self.addedAlbums.setValue(new_album, forKey: album)
                }
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Track Number") != nil) {
                track_num = (XMLTrackDict! as AnyObject).object(forKey: "Track Number") as! Int
                cd_track.track_num = track_num as NSNumber?
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Name") != nil) {
                name = (XMLTrackDict! as AnyObject).object(forKey: "Name") as! String
                cd_track.name = name
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Album Artist") != nil) {
                album_artist = (XMLTrackDict! as AnyObject).object(forKey: "Album Artist") as! String
                if self.addedArtists.object(forKey: album_artist) != nil {
                    let the_album_artist = self.addedArtists.object(forKey: album_artist) as! Artist
                    placeholderAlbum?.album_artist = the_album_artist
                }
                else {
                    let new_album_artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: managedContext) as! Artist
                    new_album_artist.name = album_artist
                    placeholderAlbum?.album_artist = new_album_artist
                    new_album_artist.id = library?.next_artist_id
                    library?.next_artist_id = Int(library!.next_artist_id!) + 1 as NSNumber
                    self.addedArtists.setValue(new_album_artist, forKey: album_artist)
                }
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Skip Count") != nil) {
                skip_count = (XMLTrackDict! as AnyObject).object(forKey: "Skip Count") as! Int
                cd_track.skip_count = skip_count as NSNumber?
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Play Count") != nil) {
                play_count = (XMLTrackDict! as AnyObject).object(forKey: "Play Count") as! Int
                cd_track.play_count = play_count as NSNumber?
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Bit Rate") != nil) {
                bit_rate = (XMLTrackDict! as AnyObject).object(forKey: "Bit Rate") as! Int
                cd_track.bit_rate = bit_rate as NSNumber?
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Total Time") != nil) {
                time = (XMLTrackDict! as AnyObject).object(forKey: "Total Time") as! Int
                cd_track.time = time as NSNumber?
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Date Modified") != nil) {
                date_modified = (XMLTrackDict! as AnyObject).object(forKey: "Date Modified") as! Date
                cd_track.date_modified = date_modified as NSDate
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Sort Album") != nil) {
                sort_album = (XMLTrackDict! as AnyObject).object(forKey: "Sort Album") as! String
                cd_track.sort_album = sort_album
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Genre") != nil) {
                genre = (XMLTrackDict! as AnyObject).object(forKey: "Genre") as! String
                cd_track.genre = genre
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Rating") != nil) {
                rating = (XMLTrackDict! as AnyObject).object(forKey: "Rating") as! Int
                cd_track.rating = rating as NSNumber?
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Sort Name") != nil) {
                sort_name = (XMLTrackDict! as AnyObject).object(forKey: "Sort Name") as! String
                cd_track.sort_name = sort_name
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Release Date") != nil) {
                date_released = (XMLTrackDict! as AnyObject).object(forKey: "Release Date") as! Date
                cd_track.album?.release_date = date_released
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Year") != nil) {
                year = (XMLTrackDict! as AnyObject).object(forKey: "Year") as! Int
                var date = DateComponents()
                date.year = year
                cd_track.album?.release_date = (date as NSDateComponents).date
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Composer") != nil) {
                composer = (XMLTrackDict! as AnyObject).object(forKey: "Composer") as! String
                if self.addedComposers.object(forKey: composer) != nil {
                    let the_composer = self.addedComposers.object(forKey: composer)
                    cd_track.composer = the_composer as! Composer
                }
                else {
                    let new_composer = NSEntityDescription.insertNewObject(forEntityName: "Composer", into: managedContext) as! Composer
                    new_composer.name = composer
                    cd_track.composer = new_composer
                    new_composer.id = library?.next_composer_id
                    library?.next_composer_id = Int(library!.next_composer_id!) + 1 as NSNumber
                    self.addedComposers.setValue(new_composer, forKey: composer)
                }
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Sort Composer") != nil) {
                sort_composer = (XMLTrackDict! as AnyObject).object(forKey: "Sort Composer") as! String
                cd_track.sort_composer = sort_composer
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Disabled") != nil) {
                status = (XMLTrackDict! as AnyObject).object(forKey: "Disabled") as! Bool
                cd_track.status = status as NSNumber?
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Sort Artist") != nil) {
                sort_artist = (XMLTrackDict! as AnyObject).object(forKey: "Sort Artist") as! String
                cd_track.sort_artist = sort_artist
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Sort Album Artist") != nil) {
                sort_album_artist = (XMLTrackDict! as AnyObject).object(forKey: "Sort Album Artist") as! String
                cd_track.sort_album_artist = sort_album_artist
            }
            if ((XMLTrackDict! as AnyObject).object(forKey: "Compilation") != nil) {
                compilation = (XMLTrackDict! as AnyObject).object(forKey: "Compilation") as! Bool
                cd_track.album?.is_compilation = compilation as NSNumber?
            }
            search_field = ""
            self.numImportedSongs += 1
            self.importSongUIUpdate(self.numImportedSongs)
            let new_track_view = NSEntityDescription.insertNewObject(forEntityName: "TrackView", into: managedContext) as! TrackView
            new_track_view.track = cd_track
        }
        DispatchQueue.main.async {
            self.doneSongs = true
            self.numSorts = self.numCachedSorts * self.numSongs
        }
        print("beginning sort")
        let poop = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
        var song_array = NSArray()
        poop.sortDescriptors = artistSortDescriptors
        let before = Date()
        do {
            try song_array = managedContext.fetch(poop) as NSArray
        }
        catch {
            print("err")
        }
        DispatchQueue.main.async {
            self.numImportedSongs = self.numSongs
        }
        let after = Date()
        let diff = after.timeIntervalSince(before)
        print(diff)
        print(song_array.count)
        song_array = song_array.sortedArray(using: #selector(Track.compareArtist)) as NSArray
        let cachedArtistOrder = checkIfCachedOrderExists("Artist")
        for (index, item) in song_array.enumerated() {
            (item as! Track).view!.addOrdersObject(cachedArtistOrder!)
            (item as! Track).view?.artist_order = index as NSNumber?
            self.importSortUIUpdate(index)
        }
        
        /*song_array = song_array.sortedArrayUsingSelector(#selector(Track.compareArtistDescending))
        let cachedArtistDescendingOrder = checkIfCachedOrderExists("Artist Descending")
        for (index, item) in song_array.enumerate() {
            (item as! Track).view!.addOrdersObject(cachedArtistDescendingOrder!)
            (item as! Track).view?.artist_descending_order = index
            self.importSortUIUpdate(index)
        }*/
        
        let cachedAlbumOrder = checkIfCachedOrderExists("Album")
        song_array = song_array.sortedArray(using: #selector(Track.compareAlbum)) as NSArray
        for (index, item) in song_array.enumerated() {
            (item as! Track).view!.addOrdersObject(cachedAlbumOrder!)
            (item as! Track).view?.album_order = index as NSNumber?
            self.importSortUIUpdate(index)
        }
        
        /*let cachedAlbumDescendingOrder = checkIfCachedOrderExists("Album Descending")
        song_array = song_array.sortedArrayUsingSelector(#selector(Track.compareAlbumDescending))
        for (index, item) in song_array.enumerate() {
            (item as! Track).view!.addOrdersObject(cachedAlbumDescendingOrder!)
            (item as! Track).view?.album_descending_order = index
            self.importSortUIUpdate(index)
        }*/
        
        let dateAddedOrder = checkIfCachedOrderExists("Date Added")
        song_array = song_array.sortedArray(using: #selector(Track.compareDateAdded)) as NSArray
        for (index, item) in song_array.enumerated() {
            (item as! Track).view!.addOrdersObject(dateAddedOrder!)
            (item as! Track).view?.date_added_order = index as NSNumber?
            self.importSortUIUpdate(index)
        }
        
        song_array = song_array.sortedArray(using: #selector(Track.compareAlbumArtist)) as NSArray
        let cachedAlbumArtistOrder = checkIfCachedOrderExists("Album Artist")
        for (index, item) in song_array.enumerated() {
            (item as! Track).view!.addOrdersObject(cachedAlbumArtistOrder!)
            (item as! Track).view?.album_artist_order = index as NSNumber?
            self.importSortUIUpdate(index)
        }
        
        /*song_array = song_array.sortedArrayUsingSelector(#selector(Track.compareAlbumArtistDescending))
        let cachedAlbumArtistDescendingOrder = checkIfCachedOrderExists("Album Artist Descending")
        for (index, item) in song_array.enumerate() {
            (item as! Track).view!.addOrdersObject(cachedAlbumArtistDescendingOrder!)
            (item as! Track).view?.album_artist_descending_order = index
            self.importSortUIUpdate(index)
        }*/
        
        song_array = song_array.sortedArray(using: #selector(Track.compareKind)) as NSArray
        let cachedKindOrder = checkIfCachedOrderExists("Kind")
        for (index, item) in song_array.enumerated() {
            (item as! Track).view!.addOrdersObject(cachedKindOrder!)
            (item as! Track).view?.kind_order = index as NSNumber?
            self.importSortUIUpdate(index)
        }
        
        song_array = song_array.sortedArray(using: #selector(Track.compareDateReleased)) as NSArray
        let cachedDateReleasedOrder = checkIfCachedOrderExists("Date Released")
        for (index, item) in song_array.enumerated() {
            (item as! Track).view!.addOrdersObject(cachedDateReleasedOrder!)
            (item as! Track).view?.release_date_order = index as NSNumber?
            self.importSortUIUpdate(index)
        }
        
        song_array = song_array.sortedArray(using: #selector(Track.compareGenre)) as NSArray
        let cachedGenreOrder = checkIfCachedOrderExists("Genre")
        for (index, item) in song_array.enumerated() {
            (item as! Track).view!.addOrdersObject(cachedGenreOrder!)
            (item as! Track).view?.genre_order = index as NSNumber?
            self.importSortUIUpdate(index)
        }
        
        song_array = song_array.sortedArray(using: #selector(Track.compareName)) as NSArray
        let cachedNameOrder = checkIfCachedOrderExists("Name")
        for (index, item) in song_array.enumerated() {
            (item as! Track).view!.addOrdersObject(cachedNameOrder!)
            (item as! Track).view?.name_order = index as NSNumber?
            self.importSortUIUpdate(index)
        }
        

        print("done sorting")
        DispatchQueue.main.async {
            self.doneSorting = true
        }
        
        do {
            try managedContext.save()
            print("done saving main context")
        } catch {
            print("error: \(error)")
        }
        
        //create playlists
        for playlistDict in self.XMLPlaylistArray {
            let thing = playlistDict as AnyObject
            let cd_playlist = NSEntityDescription.insertNewObject(forEntityName: "SongCollection", into: managedContext) as! SongCollection
            cd_playlist.name = (playlistDict as AnyObject).object(forKey: "Name") as? String
            cd_playlist.id = thing.object(forKey: "Playlist ID") as? NSNumber
            let playlistItems: NSArray
            if ((playlistDict as AnyObject).object(forKey: "Playlist Items") != nil) {
                playlistItems = (playlistDict as AnyObject).object(forKey: "Playlist Items") as! NSArray
                var track_list = [Int]()
                for stupidDict in playlistItems {
                    let trackID = (stupidDict as AnyObject).object(forKey: "Track ID") as! Int
                    track_list.append(trackID)
                }
                cd_playlist.track_id_list = track_list as NSObject?
            }
            
            let playlistsHeader: SourceListItem? = {
                let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "SourceListItem")
                let pr = NSPredicate(format: "name == 'Playlists' AND is_header == true")
                fr.predicate = pr
                do {
                    let res = try managedContext.fetch(fr) as! [SourceListItem]
                    return res[0]
                } catch {
                    print(error)
                }
                return nil
            }()

            //create source list item for playlist
            let cd_playlist_source_list_item = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
            cd_playlist_source_list_item.parent = playlistsHeader!
            cd_playlist_source_list_item.name = cd_playlist.name
            cd_playlist_source_list_item.playlist = managedContext.object(with: cd_playlist.objectID) as? SongCollection
            //cd_playlist_source_list_item.library = cd_library
            self.importPlaylistUIUpdate(self.numImportedPlaylists)
        }
        
        do {
            try managedContext.save()
            print("done saving main context")
        } catch {
            print("error: \(error)")
        }
        
        
        //get requisite next IDs
        let highestTrackID = (getInstanceWithHighestIDForEntity("Track") as! Track).id
        library?.next_track_id = highestTrackID
        
        let highestPlaylistID = (getInstanceWithHighestIDForEntity("SongCollection") as! SongCollection).id
        library?.next_playlist_id = highestPlaylistID
        
        managedContext.undoManager?.endUndoGrouping()
        
        DispatchQueue.main.async {
            self.doneEverything = true
            print("ituens parser done clause")
        }
    }
}
