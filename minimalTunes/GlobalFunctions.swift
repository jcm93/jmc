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

let defaultSortPrefixDictionary: NSMutableDictionary = [
    "the " : "",
    "a " : "",
    "an " : "",
]

let sharedLibraryNamesDictionary = NSMutableDictionary()

extension Track {
    @objc func compareArtist(other: Track) -> NSComparisonResult {
        let self_artist_name = (self.sort_artist != nil) ? self.sort_artist : self.artist?.name
        let other_artist_name = (other.sort_artist != nil) ? other.sort_artist : other.artist?.name
        let artist_comparison: NSComparisonResult
        if self_artist_name == nil || other_artist_name == nil {
            artist_comparison = (self_artist_name == other_artist_name) ? .OrderedSame : (other_artist_name != nil) ? .OrderedAscending : .OrderedDescending
        } else {
            artist_comparison = self_artist_name!.localizedStandardCompare(other_artist_name!)
        }
        if artist_comparison == .OrderedSame {
            let self_album_name = self.sort_album != nil ? self.sort_album : self.album?.name
            let other_album_name = other.sort_album != nil ? other.sort_album : other.album?.name
            let album_comparison: NSComparisonResult
            if self_album_name == nil || other_album_name == nil {
                album_comparison = (self_album_name == other_album_name) ? .OrderedSame : (other_album_name != nil) ? .OrderedAscending : .OrderedDescending
            } else {
                album_comparison = self_album_name!.localizedStandardCompare(other_album_name!)
            }
            if album_comparison == .OrderedSame {
                let self_track_num = self.track_num
                let other_track_num = other.track_num
                guard self_track_num != nil && other_track_num != nil else {
                    return (self_track_num == other_track_num) ? .OrderedSame : (other_track_num != nil) ? .OrderedAscending : .OrderedDescending
                }
                if self_track_num == other_track_num {
                    let self_name = self.sort_name != nil ? self.sort_name : self.name
                    let other_name = other.sort_name != nil ? other.sort_name : other.name
                    guard self_name != nil && other_name != nil else {
                        return (self_name == other_name) ? .OrderedSame : (other_name != nil) ? .OrderedAscending : .OrderedDescending
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
        let album_comparison: NSComparisonResult
        if self_album_name == nil || other_album_name == nil {
            album_comparison = (self_album_name == other_album_name) ? .OrderedSame : (other_album_name != nil) ? .OrderedAscending : .OrderedDescending
        } else {
            album_comparison = self_album_name!.localizedStandardCompare(other_album_name!)
        }
        if album_comparison == .OrderedSame {
            let self_artist_name = (self.sort_artist != nil) ? self.sort_artist : self.artist?.name
            let other_artist_name = (other.sort_artist != nil) ? other.sort_artist : other.artist?.name
            let artist_comparison: NSComparisonResult
            if self_artist_name == nil || other_artist_name == nil {
                artist_comparison = (self_artist_name == other_artist_name) ? .OrderedSame : (other_artist_name != nil) ? .OrderedAscending : .OrderedDescending
            } else {
                artist_comparison = self_artist_name!.localizedStandardCompare(other_artist_name!)
            }
            if artist_comparison == .OrderedSame {
                let self_track_num = self.track_num
                let other_track_num = other.track_num
                let track_num_comparison: NSComparisonResult
                if self_track_num == nil || other_track_num == nil {
                    track_num_comparison = (self_track_num == other_track_num) ? .OrderedSame : (other_track_num != nil) ? .OrderedAscending : .OrderedDescending
                } else {
                    track_num_comparison = self_track_num!.compare(other_track_num!)
                }
                if track_num_comparison == .OrderedSame {
                    let self_name = self.sort_name != nil ? self.sort_name : self.name
                    let other_name = other.sort_name != nil ? other.sort_name : other.name
                    if self_name == nil || other_name == nil {
                        return (self_name == other_name) ? .OrderedSame : (other_name != nil) ? .OrderedAscending : .OrderedDescending
                    } else {
                        return self_name!.localizedStandardCompare(other_name!)
                    }
                } else {
                    return track_num_comparison
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
        let album_artist_comparison: NSComparisonResult
        if self_album_artist_name == nil || other_album_artist_name == nil {
            album_artist_comparison = (self_album_artist_name == other_album_artist_name) ? .OrderedSame : (other_album_artist_name != nil) ? .OrderedAscending : .OrderedDescending
        } else {
            album_artist_comparison = self_album_artist_name!.localizedStandardCompare(other_album_artist_name!)
        }
        if album_artist_comparison == .OrderedSame {
            let self_album_name = (self.sort_album != nil) ? self.sort_album : self.album?.name
            let other_album_name = (other.sort_album != nil) ? other.sort_album : other.album?.name
            let album_comparison: NSComparisonResult
            if self_album_name == nil || other_album_name == nil {
                album_comparison = (self_album_name == other_album_name) ? .OrderedSame : (other_album_name != nil) ? .OrderedAscending : .OrderedDescending
            } else {
                album_comparison = self_album_name!.localizedStandardCompare(other_album_name!)
            }
            if album_comparison == .OrderedSame {
                let self_track_num = self.track_num
                let other_track_num = other.track_num
                let track_num_comparison: NSComparisonResult
                if self_track_num == nil || other_track_num == nil {
                    track_num_comparison = (self_track_num == other_track_num) ? .OrderedSame : (other_track_num != nil) ? .OrderedAscending : .OrderedDescending
                } else {
                    track_num_comparison = self_track_num!.compare(other_track_num!)
                }
                if track_num_comparison == .OrderedSame {
                    let self_name = self.sort_name != nil ? self.sort_name : self.name
                    let other_name = other.sort_name != nil ? other.sort_name : other.name
                    if self_name == nil || other_name == nil {
                        return (self_name == other_name) ? .OrderedSame : (other_name != nil) ? .OrderedAscending : .OrderedDescending
                    }
                    return self_name!.localizedStandardCompare(other_name!)
                } else {
                    return track_num_comparison
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
        let genre_comparison: NSComparisonResult
        if self_genre_name == nil || other_genre_name == nil {
            genre_comparison = (self_genre_name == other_genre_name) ? .OrderedSame : (other_genre_name != nil) ? .OrderedAscending : .OrderedDescending
        } else {
            genre_comparison = self_genre_name!.localizedStandardCompare(other_genre_name!)
        }
        if genre_comparison == .OrderedSame {
            return self.compareArtist(other)
        } else {
            return genre_comparison
        }
    }
    
    @objc func compareKind(other: Track) -> NSComparisonResult {
        let self_kind_name = self.file_kind
        let other_kind_name = other.file_kind
        let kind_comparison: NSComparisonResult
        if self_kind_name == nil || other_kind_name == nil {
            kind_comparison = (self_kind_name == other_kind_name) ? .OrderedSame : (other_kind_name != nil) ? .OrderedAscending : .OrderedDescending
        } else {
            kind_comparison = self_kind_name!.localizedStandardCompare(other_kind_name!)
        }
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
            return (self_date_added == other_date_added) ? .OrderedSame : (other_date_added != nil) ? .OrderedAscending : .OrderedDescending
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
            return (self_date_released == other_date_released) ? .OrderedSame : (other_date_released != nil) ? .OrderedAscending : .OrderedDescending
        }
        let date_released_comparison = self_date_released!.compare(other_date_released!)
        if date_released_comparison == .OrderedSame {
            return self.compareArtist(other)
        } else {
            return date_released_comparison
        }
    }
    
    @objc func compareName(other: Track) -> NSComparisonResult {
        let self_name = self.name
        let other_name = other.name
        let name_comparison: NSComparisonResult
        if self_name == nil || other_name == nil {
            name_comparison = (self_name == other_name) ? .OrderedSame : (other_name != nil) ? .OrderedAscending : .OrderedDescending
        } else {
            name_comparison = self_name!.compare(other_name!)
        }
        if name_comparison == .OrderedSame {
            return self.compareArtist(other)
        } else {
            return name_comparison
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

//other constants
let LIBRARY_ORGANIZATION_TYPE_STRING = "organizationType"
let NO_ORGANIZATION_TYPE = 0
let MOVE_ORGANIZATION_TYPE = 1
let COPY_ORGANIZATION_TYPE = 2
let UNKNOWN_ARTIST_STRING = "Unknown Artist"
let UNKNOWN_ALBUM_STRING = "Unknown Album"

let VALID_ARTWORK_TYPE_EXTENSIONS = [".jpg", ".png", ".tiff", ".gif", ".pdf"]


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

func getSortName(name: String?) -> String? {
    //todo fix for defaults
    var sortName = name
    if name != nil {
        for prefix in defaultSortPrefixDictionary.allKeys {
            if name!.lowercaseString.hasPrefix(prefix as! String) {
                let range = name!.startIndex...name!.startIndex.advancedBy((prefix as! String).characters.count)
                sortName!.removeRange(range)
                return sortName
            }
        }
    }
    return sortName
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

func editName(tracks: [Track]?, name: String) {
    let sortName = getSortName(name)
    for track in tracks! {
        track.name = name
        if sortName != name {
            track.sort_name = sortName
        }
    }
}

func editArtist(tracks: [Track]?, artistName: String) {
    print(artistName)
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    let artistCheck = checkIfArtistExists(artistName)
    if artistCheck != nil {
        for track in tracks! {
            track.artist = artistCheck!
            let artistName = artistCheck!.name!
            let sortArtistName = getSortName(artistName)
            if sortArtistName != artistName {
                track.sort_artist = sortArtistName
            }
        }
    } else {
        let new_artist = NSEntityDescription.insertNewObjectForEntityForName("Artist", inManagedObjectContext: managedContext) as! Artist
        new_artist.name = artistName
        let sortArtistName = getSortName(artistName)
        for track in tracks! {
            track.artist = new_artist
            if sortArtistName != artistName {
                track.sort_artist = sortArtistName
            }
        }
    }
}

func editComposer(tracks: [Track]?, composerName: String) {
    print(composerName)
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    let composerCheck = checkIfComposerExists(composerName)
    if composerCheck != nil {
        for track in tracks! {
            track.composer = composerCheck!
            let sortComposerName = getSortName(composerName)
            if sortComposerName != composerName {
                track.sort_composer = sortComposerName
            }
        }
    } else {
        let new_composer = NSEntityDescription.insertNewObjectForEntityForName("Composer", inManagedObjectContext: managedContext) as! Composer
        new_composer.name = composerName
        let sortComposerName = getSortName(composerName)
        for track in tracks! {
            track.composer = new_composer
            if sortComposerName != composerName {
                track.sort_composer = sortComposerName
            }
        }
    }
}

func editGenre(tracks: [Track]?, genreName: String) {
    print(genreName)
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    let genreCheck = checkIfGenreExists(genreName)
    if genreCheck != nil {
        for track in tracks! {
            track.genre = genreCheck!
        }
    } else {
        let new_genre = NSEntityDescription.insertNewObjectForEntityForName("Genre", inManagedObjectContext: managedContext) as! Genre
        new_genre.name = genreName
        for track in tracks! {
            track.genre = new_genre
        }
    }
}

func editAlbum(tracks: [Track]?, albumName: String) {
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    print(albumName)
    var album: Album?
    let albumCheck = checkIfAlbumExists(albumName)
    if albumCheck != nil {
        album = albumCheck!
        for track in tracks! {
            print("old album name: \(track.sort_album)")
            track.album = albumCheck!
            let albumName = albumCheck!.name!
            let sortAlbumName = getSortName(albumName)
            if sortAlbumName != albumName {
                track.sort_album = sortAlbumName
            }
            print("new album name: \(track.sort_album)")
        }
    } else {
        let new_album = NSEntityDescription.insertNewObjectForEntityForName("Album", inManagedObjectContext: managedContext) as! Album
        new_album.name = albumName
        let sortAlbumName = getSortName(albumName)
        for track in tracks! {
            track.album = new_album
            if sortAlbumName != albumName {
                track.sort_album = sortAlbumName
            }
        }
        album = new_album
    }
    let artists = tracks!.map( {return $0.artist!} )
    let unique_artists = Array(Set(artists))
    for artist in unique_artists {
        artist.addAlbumsObject(album!)
    }
}

func editAlbumArtist(tracks: [Track]?, albumArtistName: String) {
    print(albumArtistName)
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    let artistCheck = checkIfArtistExists(albumArtistName)
    if artistCheck != nil {
        for track in tracks! {
            track.album?.album_artist = artistCheck!
            let artistName = artistCheck!.name!
            let sortArtistName = getSortName(artistName)
            if sortArtistName != artistName {
                track.sort_album_artist = sortArtistName
            }
        }
    } else {
        let new_artist = NSEntityDescription.insertNewObjectForEntityForName("Artist", inManagedObjectContext: managedContext) as! Artist
        new_artist.name = albumArtistName
        let sortArtistName = getSortName(albumArtistName)
        let unique_albums = Set(tracks!.map({return $0.album!}))
        for album in unique_albums {
            album.album_artist = new_artist
        }
        for track in tracks! {
            if sortArtistName != albumArtistName {
                track.sort_album_artist = sortArtistName
            }
        }
    }
}

func editTrackNum(tracks: [Track]?, num: Int) {
    if tracks != nil {
        for track in tracks! {
            track.track_num = num
        }
    }
}

func editTrackNumOf(tracks: [Track]?, num: Int) {
    if tracks != nil {
        let unique_albums = Set(tracks!.map({return $0.album!}))
        for album in unique_albums {
            album.track_count = num
        }
    }
}

func editDiscNum(tracks: [Track]?, num: Int) {
    if tracks != nil {
        for track in tracks! {
            track.disc_number = num
        }
    }
}

func editDiscNumOf(tracks: [Track]?, num: Int) {
    if tracks != nil {
        let unique_albums = Set(tracks!.map({return $0.album!}))
        for album in unique_albums {
            album.disc_count = num
        }
    }
}

func editComments(tracks: [Track]?, comments: String) {
    if tracks != nil {
        for track in tracks! {
            track.comments = comments
        }
    }
}

func editRating(tracks: [Track]?, rating: Int) {
    if tracks != nil {
        for track in tracks! {
            track.rating = rating
        }
    }
}

func editIsComp(tracks: [Track]?, isComp: Bool) {
    if tracks != nil {
        let unique_albums = Set(tracks!.map({return $0.album!}))
        for album in unique_albums {
            album.is_compilation = isComp
        }
    }
}

func insert(tracks: NSOrderedSet, track: TrackView, isGreater: (Track -> Track -> NSComparisonResult)) -> Int {
    var high: Int = tracks.count - 1
    var low: Int = 0
    var index: Int
    while (low <= high) {
        index = (low + high) / 2
        let result = isGreater(track.track!)((tracks[index] as! TrackView).track!)
        if result == .OrderedAscending {
            low = index + 1
        }
        else if result == .OrderedDescending {
            high = index - 1
        }
        else {
            return index
        }
    }
    return low
}

func fixIndices(set: NSMutableOrderedSet, index: Int, order: String) {
    let trackView = (set[index] as! TrackView)
    var testIndex = index + 1
    let key: String
    switch order {
    case "Artist":
        key = "artist_order"
    case "Album":
        key = "album_order"
    case "Date Added":
        key = "date_added_order"
    case "Name":
        key = "name_order"
    case "Album Artist":
        key = "album_artist_order"
    case "Genre":
        key = "genre_order"
    case "Kind":
        key = "kind_order"
    case "Date Released":
        key = "release_date_order"
    default:
        key = "poop"
    }
    trackView.setValue(index, forKey: key)
    var firstIndex = index
    while (testIndex < set.count && (set[testIndex].valueForKey(key) as! Int) <= (set[firstIndex].valueForKey(key) as! Int)) {
        let currentValue = set[testIndex].valueForKey(key) as! Int
        set[testIndex].setValue(currentValue + 1, forKey: key)
        firstIndex = firstIndex + 1
        testIndex = testIndex + 1
    }
}


func reorderForTracks(tracks: [Track], cachedOrder: CachedOrder) {
    print("reordering for tracks for cached order \(cachedOrder.order!)")
    var comparator: (Track) -> (Track) -> NSComparisonResult
    switch cachedOrder.order! {
    case "Artist":
        comparator = Track.compareArtist
    case "Album":
        comparator = Track.compareAlbum
    case "Date Added":
        comparator = Track.compareDateAdded
    case "Name":
        comparator = Track.compareName
    case "Date Released":
        comparator = Track.compareDateReleased
    case "Album Artist":
        comparator = Track.compareAlbumArtist
    case "Genre":
        comparator = Track.compareGenre
    case "Kind":
        comparator = Track.compareKind
    default:
        comparator = Track.compareArtist
    }
    let fuckYou = cachedOrder.track_views!.mutableCopy() as! NSMutableOrderedSet
    for track in tracks {
        fuckYou.removeObject(track.view!)
    }
    for track in tracks {
        let index = insert(fuckYou, track: track.view!, isGreater: comparator)
        fuckYou.insertObject(track.view!, atIndex: index)
        fixIndices(fuckYou, index: index, order: cachedOrder.order!)
    }
    cachedOrder.track_views = fuckYou.copy() as? NSOrderedSet
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






