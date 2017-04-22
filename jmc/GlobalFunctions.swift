//
//  CertainGlobalFunctions.swift
//  minimalTunes
//
//  Created by John Moody on 7/9/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

//houses functions for editing tags, re-cacheing sorts

import Cocoa
import CoreData
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


var managedContext = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext

func saveContext() {
    do {
        try managedContext.save()
    } catch {
        print(error)
    }
}

var globalRootLibrary = {() -> Library? in
    let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Library")
    let predicate = NSPredicate(format: "parent == nil")
    fetchReq.predicate = predicate
    do {
        let result = try managedContext.fetch(fetchReq)[0] as! Library
        return result
    } catch {
        return nil
    }
}()

var globalRootLibrarySourceListItem = {() -> SourceListItem? in
    print("creating global root library source list item")
    let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "SourceListItem")
    let predicate = NSPredicate(format: "library == %@", globalRootLibrary!)
    fetchReq.predicate = predicate
    do {
        let result = try managedContext.fetch(fetchReq)[0] as! SourceListItem
        return result
    } catch {
        return nil
    }
}()

func getAllLibraries() -> [Library]? {
    let request = NSFetchRequest<Library>(entityName: "Library")
    request.predicate = NSPredicate(format: "parent != nil")
    do {
        let result = try managedContext.fetch(request)
        return result
    } catch {
        print(error)
        return nil
    }
}

func getLibrary(withName name: String) -> [Library]? {
    let request = NSFetchRequest<Library>(entityName: "Library")
    let predicate = NSPredicate(format: "name == %@", name)
    request.predicate = predicate
    do {
        let result = try managedContext.fetch(request)
        return result
    } catch {
        print(error)
        return nil
    }
}

//mark sort descriptors
var artistSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_artist", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "sort_album", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "track_num", ascending:true), NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))]

var artistSortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "artist_order", ascending: true)
var artistDescendingSortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "artist_descending_order", ascending: true)

//global user defaults
let DEFAULTS_SAVED_COLUMNS_STRING = "savedColumns"
let DEFAULTS_CHECK_ALBUM_DIRECTORY_FOR_ART_STRING = "checkForArt"
let DEFAULTS_DATE_SORT_GRANULARITY = 500.0
let DEFAULTS_CHECK_EMBEDDED_ARTWORK_STRING = "checkEmbeddedArtwork"
let DEFAULTS_ARE_INITIALIZED_STRING = "importantDefaultsAreInitialized"
let DEFAULTS_SHUFFLE_STRING = "shuffle"
let DEFAULTS_REPEAT_STRING = "willRepeat"
let DEFAULTS_NEW_NETWORK_TRACK = "newNetworkTrack"
let DEFAULTS_CURRENT_EQ_STRING = "currentEQ"
let DEFAULTS_VOLUME_STRING = "currentVolume"
let DEFAULTS_PLAYLIST_SORT_DESCRIPTOR_STRING = "defaultPlaylistSortDescriptor"
let DEFAULTS_LIBRARY_SORT_DESCRIPTOR_STRING = "defaultsLibrarySortDescriptor"
let DEFAULTS_SHARING_STRING = "sharesLibrary"
let DEFAULTS_IS_EQ_ENABLED_STRING = "isEQEnabled?"
let DEFAULTS_SHOWS_ARTWORK_STRING = "showsArtwork"

//library-specific user defaults
//destroy all of these, make them attributes of library in CD
/*let DEFAULTS_WATCHES_DIRECTORIES_FOR_NEW_FILES = "watchesDirectories"
let DEFAULTS_MONITORS_DIRECTORIES_GENERALLY = "monitorsDirectories"
let DEFAULTS_RENAMES_FILES_STRING = "renamesFiles"
let DEFAULTS_LIBRARY_ORGANIZATION_TYPE_STRING = "organizationType"
let DEFAULTS_LIBRARY_PATH_STRING = "libraryPath"
let DEFAULTS_LIBRARY_NAME_STRING = "libraryName"
 
*/

var kBitRateKey = "bitRate"
var kBPMKey = "beatsPerMinute"
var kCommentsKey = "comments"
var kDateAddedKey = "dateAdded"
var kDateLastPlayedKey = "dateLastPlayed"
var kDateLastSkippedKey = "dateLastSkipped"
var kDateModifiedKey = "dateModified"
var kDiscNumberKey = "discNumber"
var kEqualizerPresetKey = "equalizerPreset"
var kFileKindKey = "fileKind"
var kGenreKey = "genre"
var kIDKey = "id"
var kIsNetworkKey = "isNetwork"
var kIsPlayingKey = "isPlaying"
var kLocationKey = "location"
var kMovementNameKey = "movementName"
var kMovementNumKey = "movementNumber"
var kNameKey = "name"
var kPlayCountKey = "playCount"
var kRatingKey = "rating"
var kSampleRateKey = "sampleRate"
var kSizeKey = "size"
var kSkipCountKey = "skipCount"
var kSortAlbumKey = "sortAlbum"
var kSortAlbumArtistKey = "sortAlbumArtist"
var kSortArtistKey = "sortArtist"
var kSortComposerKey = "sortComposer"
var kSortNameKey = "sortName"
var kStatusKey = "status"
var kTimeKey = "time"
var kTrackNumKey = "trackNumber"
//rels
var kAlbumKey = "album"
var kArtistKey = "artist"
var kAlbumArtistKey = "albumArtist"
var kComposerKey = "composer"
var kReleaseDateKey = "dateReleased"
var kIsCompilationKey = "isCompilation"
var kTotalTracksKey = "totalTracks"

//errors
var kFileAddErrorMetadataNotYetPopulated = "Failure getting file metadata"

//other
var kDeleteEventText = "Are you sure you want to remove the selected tracks from your library?"
var jmcDarkAppearanceOption = "isDark"



//other constants
var LIBRARY_MOVES_DESCRIPTION = "Added media will be moved into a subdirectory of this directory"
var LIBRARY_COPIES_DESCRIPTION = "Added media will be copied into a subdirectory of this directory"
var LIBRARY_DOES_NOTHING_DESCRIPTION = "Added media will not be organized"
let NO_ORGANIZATION_TYPE = 0
let MOVE_ORGANIZATION_TYPE = 1
let COPY_ORGANIZATION_TYPE = 2
let UNKNOWN_ARTIST_STRING = "Unknown Artist"
let UNKNOWN_ALBUM_STRING = "Unknown Album"
let NO_FILENAME_STRING = "_"
let MIN_SONG_BAR_WIDTH_FRACTION: CGFloat = 0.174
let MIN_VOLUME_BAR_WIDTH_FRACTION: CGFloat = 0.03
let MIN_SEARCH_BAR_WIDTH_FRACTION: CGFloat = 0.145
let MAX_VOLUME_BAR_WIDTH_FRACTION: CGFloat = 0.101
let MIN_DISTANCE_BETWEEN_VOLUME_AND_SONG_BAR_FRACTION: CGFloat = 0.025

let SOURCE_FETCH_REQUEST = NSFetchRequest<NSFetchRequestResult>(entityName: "SourceListItem")
let TRACK_FETCH_REQUEST = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
let TRACK_VIEW_FETCH_REQUEST = NSFetchRequest<NSFetchRequestResult>(entityName: "TrackView")
let ALBUM_FETCH_REQUEST = NSFetchRequest<NSFetchRequestResult>(entityName: "Album")
let ARTIST_FETCH_REQUEST = NSFetchRequest<NSFetchRequestResult>(entityName: "Artist")
let COMPOSER_FETCH_REQUEST = NSFetchRequest<NSFetchRequestResult>(entityName: "Composer")
let SONG_COLLECTION_FETCH_REQUEST = NSFetchRequest<NSFetchRequestResult>(entityName: "SongCollection")

let IS_NETWORK_PREDICATE = NSPredicate(format: "is_network == %@", NSNumber(booleanLiteral: true))

let BATCH_PURGE_NETWORK_FETCH_REQUESTS: [NSFetchRequest<NSFetchRequestResult>] = [COMPOSER_FETCH_REQUEST, ARTIST_FETCH_REQUEST, ALBUM_FETCH_REQUEST, TRACK_VIEW_FETCH_REQUEST, TRACK_FETCH_REQUEST, SOURCE_FETCH_REQUEST, SONG_COLLECTION_FETCH_REQUEST]

func purgeCurrentlyPlaying() {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
    let predicate = NSPredicate(format: "is_playing == true")
    fetchRequest.predicate = predicate
    do {
        let results = try managedContext.fetch(fetchRequest) as! [Track]
        for result in results {
            result.is_playing = nil
        }
    } catch {
        print("error retrieving currently playing tracks: \(error)")
    }
}

let VALID_ARTWORK_TYPE_EXTENSIONS = ["jpg", "png", "tiff", "gif", "pdf"]
let VALID_FILE_TYPES = ["aac", "adts", "ac3", "aif", "aiff", "aifc", "caf", "mp3", "mp4", "m4a", "snd", "au", "sd2", "wav", "alac", "flac"]

//sample FLAC metadata dictionary

/*
 ENCODER=X Lossless Decoder 20141129
 TITLE=Eclectrocution
 ARTIST=Bill Fox
 ALBUM=I Stayed Up All Night Listening To Records
 GENRE=Indie Rock
 TRACKNUMBER=2
 TRACKTOTAL=25
 TOTALTRACKS=25
 DISCNUMBER=1
 DISCTOTAL=1
 TOTALDISCS=1
 DATE=1998
 COMPILATION=1
 iTunes_CDDB_1=75103619+311472+25+150+9731+23810+36286+50728+66415+81858+91382+107925+122484+146228+161584+166009+176768+187971+208201+215013+222961+225471+248084+257280+264597+276543+287590+301997
 REPLAYGAIN_TRACK_GAIN=-9.94 dB
 REPLAYGAIN_TRACK_PEAK=0.99163818

 */

let fieldsToCachedOrdersDictionary: NSDictionary = [
    "date_added" : "Date Added",
    "date_released" : "Date Released",
    "artist" : "Artist",
    "album" : "Album",
    "album_artist" : "Album Artist",
    "kind" : "Kind",
    "genre" : "Genre"
]

func validateStringForFilename(_ string: String) -> String {
    //needed?
    let newString = String(string.characters.map({
        $0 == "/" ? ":" : $0
    }))
    return newString
}

func libraryIsAvailable(library: Library) -> Bool {
    let fileManager = FileManager.default
    let libraryPath = URL(string: library.volume_url_string!)!.path
    var isDirectory = ObjCBool(booleanLiteral: false)
    if fileManager.fileExists(atPath: libraryPath, isDirectory: &isDirectory) && isDirectory.boolValue {
        library.is_available = true
        return true
    } else {
        library.is_available = false
        return false
    }
}

func changeLibraryLocation(library: Library, newLocation: URL) {
    let oldURL = URL(string: library.volume_url_string!)!
    let oldPath = oldURL.absoluteString
    let newPath = newLocation.absoluteString
    var badLocationCount = 0
    for track in (library.tracks! as! Set<Track>) {
        guard track.location!.hasPrefix(oldPath) else {badLocationCount += 1; continue}
        track.location = track.location!.replacingOccurrences(of: oldPath, with: newPath, options: .anchored, range: nil)
    }
    if var watchDirs = library.watch_dirs as? [URL] {
        if watchDirs.contains(oldURL) {
            watchDirs.remove(at: watchDirs.index(of: oldURL)!)
            watchDirs.append(newLocation)
            library.watch_dirs = watchDirs as NSArray
        }
    }
    print("number of invalid locations: \(badLocationCount)")
    library.volume_url_string = newLocation.absoluteString
}

func getImageExtension(_ uti: CFString) -> String? {
    if UTTypeConformsTo(uti, kUTTypeImage) {
        if UTTypeConformsTo(uti, kUTTypeJPEG) {
            return "jpg"
        } else if UTTypeConformsTo(uti, kUTTypeJPEG2000) {
            return "jpg"
        } else if UTTypeConformsTo(uti, kUTTypeTIFF) {
            return "tiff"
        } else if UTTypeConformsTo(uti, kUTTypePICT) {
            return "pict"
        } else if UTTypeConformsTo(uti, kUTTypeGIF) {
            return "gif"
        } else if UTTypeConformsTo(uti, kUTTypePNG) {
            return "png"
        } else if UTTypeConformsTo(uti, kUTTypeQuickTimeImage) {
            return "qtif"
        } else if UTTypeConformsTo(uti, kUTTypeAppleICNS) {
            return "icns"
        } else if UTTypeConformsTo(uti, kUTTypeBMP) {
            return "bmp"
        } else if UTTypeConformsTo(uti, kUTTypeICO) {
            return "ico"
        } else {
            return nil
        }
    } else {
        return nil
    }
}

let equalizerDefaultsDictionary: NSDictionary = [
    "Flat" : [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
]

let defaultSortPrefixDictionary: NSMutableDictionary = [
    "the " : "",
    "a " : "",
    "an " : "",
]

let DEFAULT_COLUMN_VISIBILITY_DICTIONARY: [String : Int] = [
    "album" : 0,
    "artist" : 0,
    "bit_rate" : 0,
    "comments" : 0,
    "composer" : 1,
    "date_added" : 0,
    "date_last_played" : 0,
    "date_last_skipped" : 0,
    "date_modified" : 0,
    "date_released" : 0,
    "disc_number" : 1,
    "equalizer_preset" : 1,
    "file_kind" : 0,
    "genre" : 0,
    "is_enabled" : 1,
    "is_playing" : 0,
    "movement_name" : 1,
    "movement_number" : 1,
    "name" : 0,
    "play_count" : 0,
    "playlist_number" : 1,
    "rating" : 1,
    "sample_rate" : 0,
    "size" : 0,
    "skip_count" : 1,
    "sort_album" : 1,
    "sort_album_artist" : 1,
    "sort_artist" : 1,
    "sort_composer" : 1,
    "sort_name" : 1,
    "time" : 0,
    "track_num" : 0,
]


func shuffleArray(_ array: [AnyObject]) -> [AnyObject]? {
    guard array.count > 0 else {return nil}
    var newArray = array
    for i in 0..<array.count - 1 {
        let j = Int(arc4random_uniform(UInt32(array.count - i))) + i
        guard i != j else {continue}
        swap(&newArray[i], &newArray[j])
    }
    return newArray
}

func shuffleMutableOrderedSet(_ mos: inout NSMutableOrderedSet) {
    guard mos.count > 0 else {return}
    for i in 0..<mos.count - 1 {
        let j = Int(arc4random_uniform(UInt32(mos.count - i))) + i
        guard i != j else {continue}
        swap(&mos[i], &mos[j])
    }
}

func getTrackWithID(_ id: Int) -> Track? {
    let fetch_req = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
    let pred = NSPredicate(format: "id == \(id)")
    fetch_req.predicate = pred
    let result: Track? = {() -> Track? in
        do {
            let trackList = try managedContext.fetch(fetch_req) as? [Track]
            if trackList!.count > 0 {
                return trackList![0]
            } else {
                return nil
            }
        }
        catch {
            return nil
        }
    }()
    return result
}

func getNetworkTrackWithID(_ id: Int) -> Track? {
    let fetch_req = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
    let pred = NSPredicate(format: "id == \(id) && is_network == true")
    fetch_req.predicate = pred
    let result: Track? = {() -> Track? in
        do {
            return try (managedContext.fetch(fetch_req) as! [Track])[0]
        }
        catch {
            return nil
        }
    }()
    return result
}


let sharedLibraryNamesDictionary = NSMutableDictionary()

extension Track {
    @objc func compareArtist(_ other: Track) -> ComparisonResult {
        let self_artist_name = (self.sort_artist != nil) ? self.sort_artist : self.artist?.name
        let other_artist_name = (other.sort_artist != nil) ? other.sort_artist : other.artist?.name
        let artist_comparison: ComparisonResult
        if self_artist_name == nil || other_artist_name == nil {
            artist_comparison = (self_artist_name == other_artist_name) ? .orderedSame : (other_artist_name != nil) ? .orderedAscending : .orderedDescending
        } else {
            artist_comparison = self_artist_name!.localizedStandardCompare(other_artist_name!)
        }
        if artist_comparison == .orderedSame {
            let self_album_name = self.sort_album != nil ? self.sort_album : self.album?.name
            let other_album_name = other.sort_album != nil ? other.sort_album : other.album?.name
            let album_comparison: ComparisonResult
            if self_album_name == nil || other_album_name == nil {
                album_comparison = (self_album_name == other_album_name) ? .orderedSame : (other_album_name != nil) ? .orderedAscending : .orderedDescending
            } else {
                album_comparison = self_album_name!.localizedStandardCompare(other_album_name!)
            }
            if album_comparison == .orderedSame {
                let self_disc_num = self.disc_number
                let other_disc_num = other.disc_number
                let disc_num_comparison: ComparisonResult
                if self_disc_num == nil || other_disc_num == nil {
                    disc_num_comparison = (self_disc_num == other_disc_num) ? .orderedSame : (other_disc_num != nil) ? .orderedAscending : .orderedDescending
                } else {
                    disc_num_comparison = self_disc_num!.compare(other_disc_num!)
                }
                if disc_num_comparison == .orderedSame {
                    let self_track_num = self.track_num
                    let other_track_num = other.track_num
                    let track_num_comparison: ComparisonResult
                    if self_track_num == nil || other_track_num == nil {
                         track_num_comparison = (self_track_num == other_track_num) ? .orderedSame : (other_track_num != nil) ? .orderedAscending : .orderedDescending
                    } else {
                        track_num_comparison = self_track_num!.compare(other_track_num!)
                    }
                    if track_num_comparison == .orderedSame {
                        let self_name = self.sort_name != nil ? self.sort_name : self.name
                        let other_name = other.sort_name != nil ? other.sort_name : other.name
                        guard self_name != nil && other_name != nil else {
                            return (self_name == other_name) ? .orderedSame : (other_name != nil) ? .orderedAscending : .orderedDescending
                        }
                        return self_name!.localizedStandardCompare(other_name!)
                    } else {
                        return track_num_comparison
                    }
                } else {
                    return disc_num_comparison
                }
            } else {
                return album_comparison
            }
        } else {
            return artist_comparison
        }
    }
    
    @objc func compareAlbum(_ other: Track) -> ComparisonResult {
        let self_album_name = self.sort_album != nil ? self.sort_album : self.album?.name
        let other_album_name = other.sort_album != nil ? other.sort_album : other.album?.name
        let album_comparison: ComparisonResult
        if self_album_name == nil || other_album_name == nil {
            album_comparison = (self_album_name == other_album_name) ? .orderedSame : (other_album_name != nil) ? .orderedAscending : .orderedDescending
        } else {
            album_comparison = self_album_name!.localizedStandardCompare(other_album_name!)
        }
        if album_comparison == .orderedSame {
            let self_artist_name = (self.sort_artist != nil) ? self.sort_artist : self.artist?.name
            let other_artist_name = (other.sort_artist != nil) ? other.sort_artist : other.artist?.name
            let artist_comparison: ComparisonResult
            if self_artist_name == nil || other_artist_name == nil {
                artist_comparison = (self_artist_name == other_artist_name) ? .orderedSame : (other_artist_name != nil) ? .orderedAscending : .orderedDescending
            } else {
                artist_comparison = self_artist_name!.localizedStandardCompare(other_artist_name!)
            }
            if artist_comparison == .orderedSame {
                let self_disc_num = self.disc_number
                let other_disc_num = other.disc_number
                let disc_num_comparison: ComparisonResult
                if self_disc_num == nil || other_disc_num == nil {
                    disc_num_comparison = (self_disc_num == other_disc_num) ? .orderedSame : (other_disc_num != nil) ? .orderedAscending : .orderedDescending
                } else {
                    disc_num_comparison = self_disc_num!.compare(other_disc_num!)
                }
                if disc_num_comparison == .orderedSame {
                    let self_track_num = self.track_num
                    let other_track_num = other.track_num
                    let track_num_comparison: ComparisonResult
                    if self_track_num == nil || other_track_num == nil {
                        track_num_comparison = (self_track_num == other_track_num) ? .orderedSame : (other_track_num != nil) ? .orderedAscending : .orderedDescending
                    } else {
                        track_num_comparison = self_track_num!.compare(other_track_num!)
                    }
                    if track_num_comparison == .orderedSame {
                        let self_name = self.sort_name != nil ? self.sort_name : self.name
                        let other_name = other.sort_name != nil ? other.sort_name : other.name
                        guard self_name != nil && other_name != nil else {
                            return (self_name == other_name) ? .orderedSame : (other_name != nil) ? .orderedAscending : .orderedDescending
                        }
                        return self_name!.localizedStandardCompare(other_name!)
                    } else {
                        return track_num_comparison
                    }
                } else {
                    return disc_num_comparison
                }            } else {
                return artist_comparison
            }
        } else {
            return album_comparison
        }
    }
    
    @objc func compareAlbumArtist(_ other: Track) -> ComparisonResult {
        let self_album_artist_name = self.sort_album_artist != nil ? self.sort_album_artist : self.album?.album_artist?.name != nil ? self.album?.album_artist?.name : self.sort_artist != nil ? self.sort_artist : self.artist?.name
        let other_album_artist_name = other.sort_album_artist != nil ? other.sort_album_artist : other.album?.album_artist?.name != nil ? other.album?.album_artist?.name : other.sort_artist != nil ? other.sort_artist : self.artist?.name
        let album_artist_comparison: ComparisonResult
        if self_album_artist_name == nil || other_album_artist_name == nil {
            album_artist_comparison = (self_album_artist_name == other_album_artist_name) ? .orderedSame : (other_album_artist_name != nil) ? .orderedAscending : .orderedDescending
        } else {
            album_artist_comparison = self_album_artist_name!.localizedStandardCompare(other_album_artist_name!)
        }
        if album_artist_comparison == .orderedSame {
            let self_album_name = (self.sort_album != nil) ? self.sort_album : self.album?.name
            let other_album_name = (other.sort_album != nil) ? other.sort_album : other.album?.name
            let album_comparison: ComparisonResult
            if self_album_name == nil || other_album_name == nil {
                album_comparison = (self_album_name == other_album_name) ? .orderedSame : (other_album_name != nil) ? .orderedAscending : .orderedDescending
            } else {
                album_comparison = self_album_name!.localizedStandardCompare(other_album_name!)
            }
            if album_comparison == .orderedSame {
                let self_disc_num = self.disc_number
                let other_disc_num = other.disc_number
                let disc_num_comparison: ComparisonResult
                if self_disc_num == nil || other_disc_num == nil {
                    disc_num_comparison = (self_disc_num == other_disc_num) ? .orderedSame : (other_disc_num != nil) ? .orderedAscending : .orderedDescending
                } else {
                    disc_num_comparison = self.disc_number!.compare(other_disc_num!)
                }
                if disc_num_comparison == .orderedSame {
                    let self_track_num = self.track_num
                    let other_track_num = other.track_num
                    let track_num_comparison: ComparisonResult
                    if self_track_num == nil || other_track_num == nil {
                        track_num_comparison = (self_track_num == other_track_num) ? .orderedSame : (other_track_num != nil) ? .orderedAscending : .orderedDescending
                    } else {
                        track_num_comparison = self_track_num!.compare(other_track_num!)
                    }
                    if track_num_comparison == .orderedSame {
                        let self_name = self.sort_name != nil ? self.sort_name : self.name
                        let other_name = other.sort_name != nil ? other.sort_name : other.name
                        guard self_name != nil && other_name != nil else {
                            return (self_name == other_name) ? .orderedSame : (other_name != nil) ? .orderedAscending : .orderedDescending
                        }
                        return self_name!.localizedStandardCompare(other_name!)
                    } else {
                        return track_num_comparison
                    }
                } else {
                    return disc_num_comparison
                }            } else {
                return album_comparison
            }
        } else {
            return album_artist_comparison
        }
    }
    
    @objc func compareGenre(_ other: Track) -> ComparisonResult {
        let self_genre_name = self.genre
        let other_genre_name = other.genre
        let genre_comparison: ComparisonResult
        if self_genre_name == nil || other_genre_name == nil {
            genre_comparison = (self_genre_name == other_genre_name) ? .orderedSame : (other_genre_name != nil) ? .orderedAscending : .orderedDescending
        } else {
            genre_comparison = self_genre_name!.localizedStandardCompare(other_genre_name!)
        }
        if genre_comparison == .orderedSame {
            return self.compareArtist(other)
        } else {
            return genre_comparison
        }
    }
    
    @objc func compareKind(_ other: Track) -> ComparisonResult {
        let self_kind_name = self.file_kind
        let other_kind_name = other.file_kind
        let kind_comparison: ComparisonResult
        if self_kind_name == nil || other_kind_name == nil {
            kind_comparison = (self_kind_name == other_kind_name) ? .orderedSame : (other_kind_name != nil) ? .orderedAscending : .orderedDescending
        } else {
            kind_comparison = self_kind_name!.localizedStandardCompare(other_kind_name!)
        }
        if kind_comparison == .orderedSame {
            return self.compareArtist(other)
        } else {
            return kind_comparison
        }
    }
    
    @objc func compareComposer(_ other: Track) -> ComparisonResult {
        let self_composer_name = self.sort_composer != nil ? self.sort_composer : self.composer?.name
        let other_composer_name = other.sort_composer != nil ? other.sort_composer : other.composer?.name
        let composer_comparison: ComparisonResult
        if self_composer_name == nil || other_composer_name == nil {
            composer_comparison = (self_composer_name == other_composer_name) ? .orderedSame : (other_composer_name != nil) ? .orderedAscending : .orderedDescending
        } else {
            composer_comparison = self_composer_name!.localizedStandardCompare(other_composer_name!)
        }
        if composer_comparison == .orderedSame {
            return self.compareArtist(other)
        } else {
            return composer_comparison
        }
    }
    
    @objc func compareDateAdded(_ other: Track) -> ComparisonResult {
        let self_date_added = self.date_added
        let other_date_added = other.date_added
        guard self_date_added != nil && other_date_added != nil else {
            return (self_date_added == other_date_added) ? .orderedSame : (other_date_added != nil) ? .orderedAscending : .orderedDescending
        }
        let dateDifference = self_date_added!.timeIntervalSince(other_date_added! as Date)
        let comparison: ComparisonResult = (abs(dateDifference) < DEFAULTS_DATE_SORT_GRANULARITY) ? .orderedSame : (dateDifference > 0) ? .orderedAscending : .orderedDescending
        if comparison == .orderedSame {
            return self.compareArtist(other)
        } else {
            return comparison
        }
    }
    
    @objc func compareDateReleased(_ other: Track) -> ComparisonResult {
        let self_date_released = self.album?.release_date
        let other_date_released = other.album?.release_date
        guard self_date_released != nil && other_date_released != nil else {
            return (self_date_released == other_date_released) ? .orderedSame : (other_date_released != nil) ? .orderedAscending : .orderedDescending
        }
        let date_released_comparison = self_date_released!.compare(other_date_released! as Date)
        if date_released_comparison == .orderedSame {
            return self.compareArtist(other)
        } else {
            return date_released_comparison
        }
    }
    
    @objc func compareName(_ other: Track) -> ComparisonResult {
        let self_name = self.sort_name != nil ? self.sort_name : self.name
        let other_name = other.sort_name != nil ? other.sort_name : other.name
        let name_comparison: ComparisonResult
        if self_name == nil || other_name == nil {
            name_comparison = (self_name == other_name) ? .orderedSame : (other_name != nil) ? .orderedAscending : .orderedDescending
        } else {
            name_comparison = self_name!.compare(other_name!)
        }
        if name_comparison == .orderedSame {
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

func shuffle_array(_ array: inout [Int]) {
    guard array.count > 0 else {return}
    for i in 0..<array.count - 1 {
        let j = Int(arc4random_uniform(UInt32(array.count - i))) + i
        guard i != j else {continue}
        swap(&array[i], &array[j])
    }
}

func checkIfArtistExists(_ name: String) -> Artist? {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Artist")
    let predicate = NSPredicate(format: "name == %@", name)
    request.predicate = predicate
    do {
        let result = try managedContext.fetch(request) as! [Artist]
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

func checkIfAlbumExists(_ name: String) -> Album? {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Album")
    let predicate = NSPredicate(format: "name == %@", name)
    request.predicate = predicate
    do {
        let result = try managedContext.fetch(request) as! [Album]
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

func checkIfComposerExists(_ name: String) -> Composer? {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Composer")
    let predicate = NSPredicate(format: "name == %@", name)
    request.predicate = predicate
    do {
        let result = try managedContext.fetch(request) as! [Composer]
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

func checkIfCachedOrderExists(_ name: String) -> CachedOrder? {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedOrder")
    let predicate = NSPredicate(format: "order == %@", name)
    request.predicate = predicate
    do {
        let result = try managedContext.fetch(request) as! [CachedOrder]
        if result.count > 0 {
            return result[0]
        } else {
            return nil
        }
    } catch {
        print("error checking cached order: \(error)")
        return nil
    }
}


func getSortName(_ name: String?) -> String? {
    var sortName = name
    if name != nil {
        for prefix in defaultSortPrefixDictionary.allKeys {
            if name!.lowercased().hasPrefix(prefix as! String) {
                let range = name!.startIndex...name!.characters.index(name!.startIndex, offsetBy: (prefix as! String).characters.count - 1)
                sortName!.removeSubrange(range)
                return sortName
            }
        }
    }
    return nil
}

func getTimeAsString(_ time: TimeInterval) -> String? {
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

func editName(_ tracks: [Track]?, name: String) {
    let sortName = getSortName(name)
    for track in tracks! {
        track.name = name
        if sortName != name {
            track.sort_name = sortName
        }
    }
}

func addIDsAndMakeNonNetwork(_ track: Track) {
    let library = {() -> Library? in
        let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Library")
        let predicate = NSPredicate(format: "is_network == nil OR is_network == false")
        fetchReq.predicate = predicate
        do {
            let result = try managedContext.fetch(fetchReq)[0] as! Library
            return result
        } catch {
            return nil
        }
    }()
    track.id = Int(library!.next_track_id!) as NSNumber?
    library!.next_track_id = Int(library!.next_track_id!) + 1 as NSNumber
    if track.album?.is_network == true {
        track.album?.is_network = false
        track.album?.id = library?.next_album_id
        library!.next_album_id = Int(library!.next_album_id!) + 1 as NSNumber
    }
    if track.artist?.is_network == true {
        track.artist?.is_network = false
        track.artist?.id = library?.next_artist_id
        library!.next_artist_id = Int(library!.next_artist_id!) + 1 as NSNumber
    }
    if track.composer?.is_network == true {
        track.composer?.is_network = false
        track.composer?.id = library?.next_composer_id
        library!.next_composer_id = Int(library!.next_composer_id!) + 1 as NSNumber
    }
}

func getInstanceWithHighestIDForEntity(_ entityName: String) -> NSManagedObject? {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
    fetchRequest.fetchLimit = 1
    let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
    fetchRequest.sortDescriptors = [sortDescriptor]
    do {
        let result = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
        return result[0]
    } catch {
        print("error getting instance with highest id: \(error)")
    }
    return nil
}

func editArtist(_ tracks: [Track]?, artistName: String) {
    print(artistName)
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.shared().delegate
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
        let new_artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: managedContext) as! Artist
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

func editComposer(_ tracks: [Track]?, composerName: String) {
    print(composerName)
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.shared().delegate
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
        let new_composer = NSEntityDescription.insertNewObject(forEntityName: "Composer", into: managedContext) as! Composer
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

func editAlbum(_ tracks: [Track]?, albumName: String) {
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.shared().delegate
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
        let new_album = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
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

func editAlbumArtist(_ tracks: [Track]?, albumArtistName: String) {
    print(albumArtistName)
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.shared().delegate
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
        let new_artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: managedContext) as! Artist
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

func editTrackNum(_ tracks: [Track]?, num: Int) {
    if tracks != nil {
        for track in tracks! {
            track.track_num = num as NSNumber?
        }
    }
}

func editTrackNumOf(_ tracks: [Track]?, num: Int) {
    if tracks != nil {
        let unique_albums = Set(tracks!.map({return $0.album!}))
        for album in unique_albums {
            album.track_count = num as NSNumber?
        }
    }
}

func editDiscNum(_ tracks: [Track]?, num: Int) {
    if tracks != nil {
        for track in tracks! {
            track.disc_number = num as NSNumber?
        }
    }
}

func editDiscNumOf(_ tracks: [Track]?, num: Int) {
    if tracks != nil {
        let unique_albums = Set(tracks!.map({return $0.album!}))
        for album in unique_albums {
            album.disc_count = num as NSNumber?
        }
    }
}

func editComments(_ tracks: [Track]?, comments: String) {
    if tracks != nil {
        for track in tracks! {
            track.comments = comments
        }
    }
}

func editGenre(_ tracks: [Track]?, genre: String) {
    if tracks != nil {
        for track in tracks! {
            track.genre = genre
        }
    }
}

func editRating(_ tracks: [Track]?, rating: Int) {
    if tracks != nil {
        for track in tracks! {
            track.rating = rating as NSNumber?
        }
    }
}

func editIsComp(_ tracks: [Track]?, isComp: Bool) {
    if tracks != nil {
        let unique_albums = Set(tracks!.map({return $0.album!}))
        for album in unique_albums {
            album.is_compilation = isComp as NSNumber?
        }
    }
}

func editSortName(_ tracks: [Track]?, sortName: String) {
    if tracks != nil {
        for track in tracks! {
            track.sort_name = sortName
        }
    }
}

func editSortArtist(_ tracks: [Track]?, sortArtist: String) {
    if tracks != nil {
        for track in tracks! {
            track.sort_name = sortArtist
        }
    }
}

func editSortAlbum(_ tracks: [Track]?, sortAlbum: String) {
    if tracks != nil {
        for track in tracks! {
            track.sort_album = sortAlbum
        }
    }
}

func editSortAlbumArtist(_ tracks: [Track]?, sortAlbumArtist: String) {
    if tracks != nil {
        for track in tracks! {
            track.sort_album_artist = sortAlbumArtist
        }
    }
}

func editSortComposer(_ tracks: [Track]?, sortComposer: String) {
    if tracks != nil {
        for track in tracks! {
            track.sort_composer = sortComposer
        }
    }
}

func insert(_ tracks: NSOrderedSet, track: TrackView, isGreater: ((Track) -> (Track) -> ComparisonResult)) -> Int {
    var high: Int = tracks.count - 1
    var low: Int = 0
    var index: Int
    while (low <= high) {
        index = (low + high) / 2
        let result = isGreater(track.track!)((tracks[index] as! TrackView).track!)
        if result == .orderedDescending {
            low = index + 1
        }
        else if result == .orderedAscending {
            high = index - 1
        }
        else {
            return index
        }
    }
    return low
}

func fixIndices(_ set: NSMutableOrderedSet, index: Int, order: String) {
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
    case "Composer":
        key = "composer_order"
    default:
        key = "poop"
    }
    trackView.setValue(index, forKey: key)
    var firstIndex = index
    while (testIndex < set.count && ((set[testIndex] as AnyObject).value(forKey: key) as! Int) <= ((set[firstIndex] as AnyObject).value(forKey: key) as! Int)) {
        let currentValue = (set[testIndex] as AnyObject).value(forKey: key) as! Int
        (set[testIndex] as AnyObject).setValue(currentValue + 1, forKey: key)
        firstIndex = firstIndex + 1
        testIndex = testIndex + 1
    }
}

func testFixIndices(_ set: NSMutableOrderedSet, order: String) {
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
    case "Composer":
        key = "composer_order"
    default:
        key = "poop"
    }
    var index = 0
    for track in set {
        (track as AnyObject).setValue(index, forKey: key)
        index += 1
    }
}


func reorderForTracks(_ tracks: [Track], cachedOrder: CachedOrder) {
    let actualTracks = tracks.map({return managedContext.object(with: $0.objectID) as! Track})
    print("reordering for tracks for cached order \(cachedOrder.order!)")
    let comparator: (Track) -> (Track) -> ComparisonResult
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
    case "Composer":
        comparator = Track.compareComposer
    default:
        comparator = Track.compareArtist
    }
    if actualTracks.count > cachedOrder.track_views?.count {
        let allTracks = (cachedOrder.track_views!.array as! [TrackView]).map({return $0.track!}) + actualTracks as NSArray
        let newTracks: NSArray
        let key: String
        switch cachedOrder.order! {
        case "Artist":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareArtist)) as NSArray
            key = "artist_order"
        case "Album":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareAlbum)) as NSArray
            key = "album_order"
        case "Date Added":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareDateAdded)) as NSArray
            key = "date_added_order"
        case "Name":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareName)) as NSArray
            key = "name_order"
        case "Date Released":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareDateReleased)) as NSArray
            key = "release_date_order"
        case "Album Artist":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareAlbumArtist)) as NSArray
            key = "album_artist_order"
        case "Genre":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareGenre)) as NSArray
            key = "genre_order"
        case "Kind":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareKind)) as NSArray
            key = "kind_order"
        case "Composer":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareComposer)) as NSArray
            key = "composer_order"
        default:
            newTracks = allTracks.sortedArray(using: #selector(Track.compareArtist)) as NSArray
            key = "artist_order"
        }
        var index = 0
        for track in newTracks.map({return ($0 as! Track).view!}) {
            track.setValue(index, forKey: key)
            index += 1
        }
        cachedOrder.track_views = NSOrderedSet(array: newTracks.map({return ($0 as AnyObject).view!}) as! [TrackView])
    } else {
        let mutableVersion = cachedOrder.track_views!.mutableCopy() as! NSMutableOrderedSet
        for track in actualTracks {
            mutableVersion.remove(track.view!)
        }
        for track in actualTracks {
            let index = insert(mutableVersion, track: track.view!, isGreater: comparator)
            print("index is \(index)")
            mutableVersion.insert(track.view!, at: index)
            //fixIndices(mutableVersion, index: index, order: cachedOrder.order!)
        }
        testFixIndices(mutableVersion, order: cachedOrder.order!)
        cachedOrder.track_views = mutableVersion.copy() as? NSOrderedSet
    }
}

func addSecondaryArtForTrack(_ track: Track, art: Data, albumDirectoryPath: String) -> Track {
    let artHash = art.hashValue
    let newArtwork = NSEntityDescription.insertNewObject(forEntityName: "AlbumArtwork", into: managedContext) as! AlbumArtwork
    newArtwork.image_hash = artHash as NSNumber?
    if track.album!.other_art != nil {
        let contains: Bool = {
            for album in track.album!.other_art!.art! {
                if (album as! AlbumArtwork).image_hash == (artHash as NSNumber) {
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
    let artTIFF = artImage?.tiffRepresentation
    let artRep = NSBitmapImageRep(data: artTIFF!)
    let artPNG = artRep?.representation(using: .PNG, properties: [:])
    track.album?.primary_art = newArtwork
    print("writing to \(artFilename)")
    do {
        try artPNG?.write(to: URL(fileURLWithPath: artFilename), options: NSData.WritingOptions.atomicWrite)
    }catch {
        print("error writing file: \(error)")
    }
    return track
}
