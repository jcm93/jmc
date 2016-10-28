//
//  CertainGlobalFunctions.swift
//  minimalTunes
//
//  Created by John Moody on 7/9/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

//houses functions for editing tags, re-cacheing sorts, finding album artwork
//hopefully it will house nothing, eventually

import Cocoa
import CoreData

var managedContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

//mark sort descriptors
var artistSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_artist", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "sort_album", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "track_num", ascending:true), NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))]

let fieldsToCachedOrdersDictionary: NSDictionary = [
    "date_added" : "Date Added",
    "date_released" : "Date Released",
    "artist" : "Artist",
    "album" : "Album",
    "album_artist" : "Album Artist",
    "kind" : "Kind",
    "genre" : "Genre"
]

let sharedLibraryNamesDictionary = NSMutableDictionary()

extension Track {
    @objc func compareArtist(other: Track) -> NSComparisonResult {
        let self_artist_name = (self.sort_artist != nil) ? self.sort_artist : self.artist?.name
        let other_artist_name = (other.sort_artist != nil) ? other.sort_artist : other.artist?.name
        guard self_artist_name != nil && other_artist_name != nil else {
            return (self_artist_name == other_artist_name) ? .OrderedSame : (self_artist_name != nil) ? .OrderedAscending : .OrderedDescending
        }
        let artist_comparison = self_artist_name!.localizedStandardCompare(other_artist_name!)
        if artist_comparison == .OrderedSame {
            let self_album_name = self.sort_album != nil ? self.sort_album : self.album?.name
            let other_album_name = other.sort_album != nil ? other.sort_album : other.album?.name
            guard self_album_name != nil && other_album_name != nil else {
                return (self_album_name == other_album_name) ? .OrderedSame : (self_album_name != nil) ? .OrderedAscending : .OrderedDescending
            }
            let album_comparison = self_album_name!.localizedStandardCompare(other_album_name!)
            if album_comparison == .OrderedSame {
                let self_track_num = self.track_num
                let other_track_num = self.track_num
                guard self_track_num != nil && other_track_num != nil else {
                    return (self_track_num == other_track_num) ? .OrderedSame : (self_track_num != nil) ? .OrderedAscending : .OrderedDescending
                }
                if self_track_num == other_track_num {
                    let self_name = self.sort_name != nil ? self.sort_name : self.name
                    let other_name = other.sort_name != nil ? other.sort_name : other.name
                    guard self_name != nil && other_name != nil else {
                        return (self_name == other_name) ? .OrderedSame : (self_name != nil) ? .OrderedAscending : .OrderedDescending
                    }
                    return self_name!.localizedStandardCompare(other_name!)
                } else {
                    return self_track_num!.compare(other_track_num!)
                }
            } else {
                return album_comparison
            }
        } else {
            return artist_comparison
        }
    }
    
    @objc func compareAlbum(other: Track) -> NSComparisonResult {
        let self_album_name = self.sort_album != nil ? self.sort_album : self.album?.name
        let other_album_name = other.sort_album != nil ? other.sort_album : other.album?.name
        guard self_album_name != nil && other_album_name != nil else {
            return (self_album_name == other_album_name) ? .OrderedSame : (self_album_name != nil) ? .OrderedAscending : .OrderedDescending
        }
        let album_comparison = self_album_name!.localizedStandardCompare(other_album_name!)
        if album_comparison == .OrderedSame {
            let self_artist_name = (self.sort_artist != nil) ? self.sort_artist : self.artist?.name
            let other_artist_name = (other.sort_artist != nil) ? other.sort_artist : other.artist?.name
            guard self_artist_name != nil && other_artist_name != nil else {
                return (self_artist_name == other_artist_name) ? .OrderedSame : (self_artist_name != nil) ? .OrderedAscending : .OrderedDescending
            }
            let artist_comparison = self_artist_name!.localizedStandardCompare(other_artist_name!)
            if artist_comparison == .OrderedSame {
                let self_track_num = self.track_num
                let other_track_num = self.track_num
                guard self_track_num != nil && other_track_num != nil else {
                    return (self_track_num == other_track_num) ? .OrderedSame : (self_track_num != nil) ? .OrderedAscending : .OrderedDescending
                }
                if self_track_num == other_track_num {
                    let self_name = self.sort_name != nil ? self.sort_name : self.name
                    let other_name = other.sort_name != nil ? other.sort_name : other.name
                    guard self_name != nil && other_name != nil else {
                        return (self_name == other_name) ? .OrderedSame : (self_name != nil) ? .OrderedAscending : .OrderedDescending
                    }
                    return self_name!.localizedStandardCompare(other_name!)
                } else {
                    return self_track_num!.compare(other_track_num!)
                }
            } else {
                return artist_comparison
            }
        } else {
            return album_comparison
        }
    }
    
    @objc func compareAlbumArtist(other: Track) -> NSComparisonResult {
        let self_album_artist_name = self.sort_album_artist != nil ? self.sort_album_artist : self.album?.album_artist?.name != nil ? self.album?.album_artist?.name : self.sort_artist != nil ? self.sort_artist : self.artist?.name
        let other_album_artist_name = other.sort_album_artist != nil ? other.sort_album_artist : other.album?.album_artist?.name != nil ? other.album?.album_artist?.name : other.sort_artist != nil ? other.sort_artist : self.artist?.name
        guard self_album_artist_name != nil && other_album_artist_name != nil else {
            return (self_album_artist_name == other_album_artist_name) ? .OrderedSame : (self_album_artist_name != nil) ? .OrderedAscending : .OrderedDescending
        }
        let album_artist_comparison = self_album_artist_name!.localizedStandardCompare(other_album_artist_name!)
        if album_artist_comparison == .OrderedSame {
            let self_album_name = (self.sort_album != nil) ? self.sort_album : self.album?.name
            let other_album_name = (other.sort_album != nil) ? other.sort_album : other.album?.name
            guard self_album_name != nil && other_album_name != nil else {
                return (self_album_name == other_album_name) ? .OrderedSame : (self_album_name != nil) ? .OrderedAscending : .OrderedDescending
            }
            let album_comparison = self_album_name!.localizedStandardCompare(other_album_name!)
            if album_comparison == .OrderedSame {
                let self_track_num = self.track_num
                let other_track_num = self.track_num
                guard self_track_num != nil && other_track_num != nil else {
                    return (self_track_num == other_track_num) ? .OrderedSame : (self_track_num != nil) ? .OrderedAscending : .OrderedDescending
                }
                if self_track_num == other_track_num {
                    let self_name = self.sort_name != nil ? self.sort_name : self.name
                    let other_name = other.sort_name != nil ? other.sort_name : other.name
                    guard self_name != nil && other_name != nil else {
                        return (self_name == other_name) ? .OrderedSame : (self_name != nil) ? .OrderedAscending : .OrderedDescending
                    }
                    return self_name!.localizedStandardCompare(other_name!)
                } else {
                    return self_track_num!.compare(other_track_num!)
                }
            } else {
                return album_comparison
            }
        } else {
            return album_artist_comparison
        }
    }
    
    @objc func compareGenre(other: Track) -> NSComparisonResult {
        let self_genre_name = self.genre?.name
        let other_genre_name = other.genre?.name
        guard self_genre_name != nil && other_genre_name != nil else {
            return (self_genre_name == other_genre_name) ? .OrderedSame : (self_genre_name != nil) ? .OrderedAscending : .OrderedDescending
        }
        let genre_comparison = self_genre_name!.localizedStandardCompare(other_genre_name!)
        if genre_comparison == .OrderedSame {
            return self.compareArtist(other)
        } else {
            return genre_comparison
        }
    }
    
    @objc func compareKind(other: Track) -> NSComparisonResult {
        let self_kind_name = self.file_kind
        let other_kind_name = other.file_kind
        guard self_kind_name != nil && other_kind_name != nil else {
            return (self_kind_name == other_kind_name) ? .OrderedSame : (self_kind_name != nil) ? .OrderedAscending : .OrderedDescending
        }
        let kind_comparison = self_kind_name!.localizedStandardCompare(other_kind_name!)
        if kind_comparison == .OrderedSame {
            return self.compareArtist(other)
        } else {
            return kind_comparison
        }
    }
    
    @objc func compareDateAdded(other: Track) -> NSComparisonResult {
        let self_date_added = self.date_added
        let other_date_added = other.date_added
        guard self_date_added != nil && other_date_added != nil else {
            return (self_date_added == other_date_added) ? .OrderedSame : (self_date_added != nil) ? .OrderedAscending : .OrderedDescending
        }
        let dateDifference = self_date_added!.timeIntervalSinceDate(other_date_added!)
        let comparison: NSComparisonResult = (abs(dateDifference) < DEFAULTS_DATE_SORT_GRANULARITY) ? .OrderedSame : (dateDifference > 0) ? .OrderedAscending : .OrderedDescending
        if comparison == .OrderedSame {
            return self.compareArtist(other)
        } else {
            return comparison
        }
    }
    
    @objc func compareDateReleased(other: Track) -> NSComparisonResult {
        let self_date_released = self.album?.release_date
        let other_date_released = other.album?.release_date
        guard self_date_released != nil && other_date_released != nil else {
            return (self_date_released == other_date_released) ? .OrderedSame : (self_date_released != nil) ? .OrderedAscending : .OrderedDescending
        }
        let date_released_comparison = self_date_released!.compare(other_date_released!)
        if date_released_comparison == .OrderedSame {
            return self.compareArtist(other)
        } else {
            return date_released_comparison
        }
    }

}


/*var albumSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_album", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "track_num", ascending: true), NSSortDescriptor(key: "sort_name", ascending:true, selector: #selector(NSString.localizedStandardCompare(_:)))]
//var albumSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_album", ascending: true)]
var dateAddedSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "date_added", ascending: true, selector: #selector(NSDate.compare(_:))), NSSortDescriptor(key: "sort_artist", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "sort_album", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "track_num", ascending:true)]
var nameSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_name", ascending:true, selector: #selector(NSString.localizedStandardCompare(_:)))]
var timeSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "time", ascending: true), NSSortDescriptor(key: "sort_name", ascending:true, selector: #selector(NSString.localizedStandardCompare(_:)))]*/


//mark user defaults
let DEFAULTS_SAVED_COLUMNS_STRING = "savedColumns"
let DEFAULTS_LIBRARY_PATH_STRING = "libraryPath"
let DEFAULTS_LIBRARY_NAME_STRING = "libraryName"
let DEFAULTS_DATE_SORT_GRANULARITY = 500.0


func checkIfArtistExists(name: String) -> Artist? {
    let request = NSFetchRequest(entityName: "Artist")
    let predicate = NSPredicate(format: "name == %@", name)
    request.predicate = predicate
    do {
        let result = try managedContext.executeFetchRequest(request) as! [Artist]
        if result.count > 0 {
            return result[0]
        } else {
            return nil
        }
    } catch {
        print("error checking artist: \(error)")
        return nil
    }
}

func checkIfAlbumExists(name: String) -> Album? {
    let request = NSFetchRequest(entityName: "Album")
    let predicate = NSPredicate(format: "name == %@", name)
    request.predicate = predicate
    do {
        let result = try managedContext.executeFetchRequest(request) as! [Album]
        if result.count > 0 {
            return result[0]
        } else {
            return nil
        }
    } catch {
        print("error checking album: \(error)")
        return nil
    }
}

func checkIfComposerExists(name: String) -> Composer? {
    let request = NSFetchRequest(entityName: "Composer")
    let predicate = NSPredicate(format: "name == %@", name)
    request.predicate = predicate
    do {
        let result = try managedContext.executeFetchRequest(request) as! [Composer]
        if result.count > 0 {
            return result[0]
        } else {
            return nil
        }
    } catch {
        print("error checking copmoser: \(error)")
        return nil
    }
}

func checkIfGenreExists(name: String) -> Genre? {
    let request = NSFetchRequest(entityName: "Genre")
    let predicate = NSPredicate(format: "name == %@", name)
    request.predicate = predicate
    do {
        let result = try managedContext.executeFetchRequest(request) as! [Genre]
        if result.count > 0 {
            return result[0]
        } else {
            return nil
        }
    } catch {
        print("error checking genre: \(error)")
        return nil
    }
}

class MeTunesDate {
    var date: NSDate
    var is_ambiguous: Bool
    init(date: NSDate, is_ambiguous: Bool) {
        self.date = date
        self.is_ambiguous = is_ambiguous
    }
}

func getTimeAsString(time: NSTimeInterval) -> String? {
    let dongs = Int(time)
    let hr = dongs / 3600
    let min = (dongs - (hr * 3600)) / 60
    let sec = (dongs - (hr * 3600) - (min * 60))
    var stamp = ""
    if (sec < 10) {
        stamp = "\(min):0\(sec)"
    }
    else {
        stamp = "\(min):\(sec)"
    }
    if hr != 0 {
        if (min < 10) {
            stamp = "\(hr):0\(stamp)"
        }
        else {
            stamp = "\(hr):\(stamp)"
        }
    }
    return stamp
}

func editArtist(tracks: [Track]?, artistName: String) {
    print(artistName)
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    let artistCheck: Artist? = {
        let fetch_req = NSFetchRequest(entityName: "Artist")
        let predicate = NSPredicate(format: "name == %@", artistName)
        fetch_req.predicate = predicate
        do {
            let results = try managedContext.executeFetchRequest(fetch_req) as! [Artist]
            if (results.count > 0) {
                return results[0]
            } else {
                return nil
            }
            
        } catch {
            print("error: \(error)")
            return nil
        }
    }()
    if artistCheck != nil {
        for track in tracks! {
            track.artist = artistCheck!
            let artistName = artistCheck!.name!
            var sortArtistName: String
            if artistCheck!.name!.hasPrefix("The ") || artistCheck!.name!.hasPrefix("the ") {
                let range = artistName.startIndex...artistName.startIndex.advancedBy(3)
                sortArtistName = artistName
                sortArtistName.removeRange(range)
            }
            else {
                sortArtistName = artistName
            }
            track.sort_artist = sortArtistName
        }
    } else {
        let new_artist = NSEntityDescription.insertNewObjectForEntityForName("Artist", inManagedObjectContext: managedContext) as! Artist
        new_artist.name = artistName
        var sortArtistName: String
        if artistName.hasPrefix("The ") || artistName.hasPrefix("the ") {
            let range = artistName.startIndex...artistName.startIndex.advancedBy(3)
            sortArtistName = artistName
            sortArtistName.removeRange(range)
            print(sortArtistName)
        }
        else {
            sortArtistName = artistName
        }
        for track in tracks! {
            track.artist = new_artist
            track.sort_artist = sortArtistName
        }
    }
}

func editAlbum(tracks: [Track]?, albumName: String) {
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    print(albumName)
    var album: Album?
    let albumCheck: Album? = {
        let fetch_req = NSFetchRequest(entityName: "Album")
        let predicate = NSPredicate(format: "name == %@", albumName)
        fetch_req.predicate = predicate
        do {
            let results = try managedContext.executeFetchRequest(fetch_req) as! [Album]
            if (results.count > 0) {
                return results[0]
            } else {
                return nil
            }
            
        } catch {
            print("error: \(error)")
            return nil
        }
    }()
    if albumCheck != nil {
        album = albumCheck!
        for track in tracks! {
            print("old album name: \(track.sort_album)")
            track.album = albumCheck!
            let albumName = albumCheck!.name!
            var sortAlbumName: String
            if albumCheck!.name!.hasPrefix("The ") || albumCheck!.name!.hasPrefix("the ") {
                let range = albumName.startIndex...albumName.startIndex.advancedBy(3)
                sortAlbumName = albumName
                sortAlbumName.removeRange(range)
            }
            else {
                sortAlbumName = albumName
            }
            track.sort_album = sortAlbumName
            print("new album name: \(track.sort_album)")
        }
    } else {
        let new_album = NSEntityDescription.insertNewObjectForEntityForName("Album", inManagedObjectContext: managedContext) as! Album
        new_album.name = albumName
        var sort_album_name: String
        if albumName.hasPrefix("The ") || albumName.hasPrefix("the ") {
            let range = albumName.startIndex...albumName.startIndex.advancedBy(3)
            sort_album_name = albumName
            sort_album_name.removeRange(range)
            print(sort_album_name)
        }
        else {
            sort_album_name = albumName
        }
        for track in tracks! {
            print("old album name: \(track.sort_album)")
            track.album = new_album
            track.sort_album = sort_album_name
            print("new album name: \(track.sort_album)")
        }
        album = new_album
    }
    let artists = tracks!.map( {return $0.artist!} )
    let unique_artists = Array(Set(artists))
    for artist in unique_artists {
        artist.addAlbumsObject(album!)
    }
}

func isGreaterArtist(a: Track, b: Track) -> Bool? {
    if a.artist == nil {
        return false
    }
    if b.artist == nil {
        return true
    }
    let artistComp = a.sort_artist!.localizedStandardCompare(b.sort_artist!)
    switch artistComp {
    case .OrderedSame:
        return isGreaterAlbum(a, b: b)
    case .OrderedAscending:
        return false
    case .OrderedDescending:
        return true
    }
}

func isGreaterAlbum(a: Track, b: Track) -> Bool? {
    if a.album == nil {
        return false
    }
    if b.album == nil {
        return true
    }
    let albumComp = a.sort_album!.localizedStandardCompare(b.sort_album!)
    switch albumComp {
    case .OrderedSame:
        return isGreaterTrackNum(a, b: b)
    case .OrderedAscending:
        return false
    case .OrderedDescending:
        return true
    }
}

func isGreaterTrackNum(a: Track, b: Track) -> Bool? {
    if a.track_num == nil {
        return false
    }
    if b.track_num == nil {
        return true
    }
    let trackNumComp = a.track_num!.compare(b.track_num!)
    switch trackNumComp {
    case .OrderedSame:
        return isGreaterName(a, b: b)
    case .OrderedAscending:
        return false
    case .OrderedDescending:
        return true
    }

}

func isGreaterName(a: Track, b: Track) -> Bool? {
    if a.name == nil {
        return false
    }
    if b.name == nil {
        return true
    }
    let nameComp = a.name!.localizedStandardCompare(b.name!)
    print(b.name!)
    switch nameComp {
    case .OrderedAscending:
        return false
    case .OrderedDescending:
        return true
    case .OrderedSame:
        return nil
    }
}

func isGreaterDateAdded(a: Track, b: Track) -> Bool? {
    if a.date_added == nil {
        return false
    }
    if b.date_added == nil {
        return true
    }
    let dateComp = a.date_added!.compare(b.date_added!)
    switch dateComp {
    case .OrderedAscending:
        return false
    case .OrderedDescending:
        return true
    case .OrderedSame:
        return isGreaterArtist(a, b: b)
    }
}

func isGreaterTime(a: Track, b: Track) -> Bool? {
    if a.time == nil {
        return false
    }
    if b.time == nil {
        return true
    }
    let timeComp = a.time!.compare(b.time!)
    switch timeComp {
    case .OrderedAscending:
        return false
    case .OrderedDescending:
        return true
    case .OrderedSame:
        return isGreaterName(a, b: b)
    }
}

func insert(tracks: NSOrderedSet, track: Track, isGreater: (a: Track, b: Track) -> Bool?) -> Int {
    var high: Int = tracks.count - 1
    var low: Int = 0
    var index: Int
    while (low <= high) {
        index = (low + high) / 2
        let result = isGreater(a: track, b: tracks[index] as! Track)
        if result == true {
            low = index + 1
        }
        else if result == false {
            high = index - 1
        }
        else {
            return index
        }
    }
    return low
}


func reorderForTracks(tracks: [Track], cachedOrder: CachedOrder) {
    print("reordering for tracks for cached order \(cachedOrder.order!)")
    var comparator: ((a: Track, b: Track) -> Bool?)?
    switch cachedOrder.order! {
    case "Artist":
        comparator = isGreaterArtist
    case "Album":
        comparator = isGreaterAlbum
    case "Date Added":
        comparator = isGreaterDateAdded
    case "Name":
        comparator = isGreaterName
    case "Time":
        comparator = isGreaterTime
    default:
        comparator = isGreaterArtist
    }
    let fuckYou = cachedOrder.tracks!.mutableCopy() as! NSMutableOrderedSet
    for track in tracks {
        fuckYou.removeObject(track)
    }
    for track in tracks {
        let index = insert(fuckYou, track: track, isGreater: comparator!)
        fuckYou.insertObject(track, atIndex: index)
    }
    cachedOrder.tracks = fuckYou.copy() as? NSOrderedSet
}

func addPrimaryArtForTrack(track: Track, art: NSData, albumDirectoryPath: String) -> Track? {
    print("adding new primary album art")
    guard let artImage = NSImage(data: art) else {return nil}
    let artHash = art.hashValue
    let newArtwork = NSEntityDescription.insertNewObjectForEntityForName("AlbumArtwork", inManagedObjectContext: managedContext) as! AlbumArtwork
    newArtwork.image_hash = artHash
    if track.album!.primary_art != nil {
        let contains: Bool = {
            if track.album?.primary_art?.image_hash == artHash {
                return true
            }
            else {
                return false
            }
        }()
        guard contains != true else {return track}
        if track.album!.other_art != nil {
            let contains: Bool = {
                for album in track.album!.other_art!.art! {
                    if (album as! AlbumArtwork).image_hash == artHash {
                        return true
                    }
                }
                return false
            }()
            guard contains != true else {return track}
            track.album!.other_art!.addArtObject(track.album!.primary_art!)
        }
        else if track.album!.other_art == nil {
            let newArtworkCollection = NSEntityDescription.insertNewObjectForEntityForName("AlbumArtworkCollection", inManagedObjectContext: managedContext) as! AlbumArtworkCollection
            newArtworkCollection.album = track.album!
            newArtworkCollection.addArtObject(track.album!.primary_art!)
        }
    }
    let thing = "/\(artHash).png"
    let artFilename = albumDirectoryPath + thing
    newArtwork.artwork_location = artFilename
    let artTIFF = artImage.TIFFRepresentation
    let artRep = NSBitmapImageRep(data: artTIFF!)
    let artPNG = artRep?.representationUsingType(.NSPNGFileType, properties: [:])
    track.album?.primary_art = newArtwork
    print("writing to \(artFilename)")
    do {
        try artPNG?.writeToFile(artFilename, options: NSDataWritingOptions.AtomicWrite)
    }catch {
        print("error writing file: \(error)")
    }
    return track
}

func addSecondaryArtForTrack(track: Track, art: NSData, albumDirectoryPath: String) -> Track {
    let artHash = art.hashValue
    let newArtwork = NSEntityDescription.insertNewObjectForEntityForName("AlbumArtwork", inManagedObjectContext: managedContext) as! AlbumArtwork
    newArtwork.image_hash = artHash
    if track.album!.other_art != nil {
        let contains: Bool = {
            for album in track.album!.other_art!.art! {
                if (album as! AlbumArtwork).image_hash == artHash {
                    return true
                }
            }
            return false
        }()
        guard contains != true else {return track}
        track.album!.other_art!.addArtObject(track.album!.primary_art!)
    }
    let thing = "/\(artHash).png"
    let artFilename = albumDirectoryPath + thing
    newArtwork.artwork_location = artFilename
    let artImage = NSImage(data: art)
    let artTIFF = artImage?.TIFFRepresentation
    let artRep = NSBitmapImageRep(data: artTIFF!)
    let artPNG = artRep?.representationUsingType(.NSPNGFileType, properties: [:])
    track.album?.primary_art = newArtwork
    print("writing to \(artFilename)")
    do {
        try artPNG?.writeToFile(artFilename, options: NSDataWritingOptions.AtomicWrite)
    }catch {
        print("error writing file: \(error)")
    }
    return track
}






