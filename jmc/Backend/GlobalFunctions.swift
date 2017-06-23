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
/*fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
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
}*/


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

func getAllMiscellaneousAlbumFiles(for album: Album) -> [String] {
    var albumFiles = [String?]()
    albumFiles.append(album.primary_art?.artwork_location)
    if let otherArt = album.other_art {
        albumFiles.append(contentsOf: otherArt.map({return ($0 as! AlbumArtwork).artwork_location}))
    }
    if let otherFiles = album.other_files {
        albumFiles.append(contentsOf: otherFiles.map({return ($0 as! AlbumFile).location}))
    }
    return albumFiles.flatMap({return $0})
}

//mark sort descriptors
var artistSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_artist", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "sort_album", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "track_num", ascending:true), NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))]

var artistSortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "artist_order", ascending: true)
var artistDescendingSortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "artist_descending_order", ascending: true)

//global user defaults
let DEFAULTS_SAVED_COLUMNS_STRING = "savedColumns"
let DEFAULTS_SAVED_COLUMNS_STRING_CONSOLIDATOR = "consolidatorSavedColumns"
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

let DEFAULT_TEMPLATE_TOKEN_ARRAY: [OrganizationFieldToken] = [
    OrganizationFieldToken(string: "/"),
    OrganizationFieldToken(string: "Album Artist"),
    OrganizationFieldToken(string: "/"),
    OrganizationFieldToken(string: "Album"),
    OrganizationFieldToken(string: "/"),
    OrganizationFieldToken(string: "Disc-Track #"),
    OrganizationFieldToken(string: " "),
    OrganizationFieldToken(string: "Title")
]

let COMPILATION_TOKEN_ARRAY: [OrganizationFieldToken] = [
    OrganizationFieldToken(string: "/Compilations/"),
    OrganizationFieldToken(string: "Album"),
    OrganizationFieldToken(string: "/"),
    OrganizationFieldToken(string: "Disc-Track #"),
    OrganizationFieldToken(string: " "),
    OrganizationFieldToken(string: "Artist"),
    OrganizationFieldToken(string: " - "),
    OrganizationFieldToken(string: "Title")
]

let COMPILATION_PREDICATE: NSPredicate = NSPredicate(format: "track.album.is_compilation == true")

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
var kAlbumArtistKey = "albumartist"
var kComposerKey = "composer"
var kReleaseDateKey = "dateReleased"
var kIsCompilationKey = "isCompilation"
var kTotalTracksKey = "totalTracks"

//errors
var kFileAddErrorMetadataNotYetPopulated = "Failure getting file metadata"

//other
var kDeleteEventText = "Are you sure you want to remove the selected tracks from your library?"
var jmcDarkAppearanceOption = "isDark"

var jmcNameCachedOrderName = "Name"
var jmcArtistCachedOrderName = "Artist"
var jmcDateAddedCachedOrderName = "Date Added"
var jmcDateReleasedCachedOrderName = "Date Released"
var jmcAlbumCachedOrderName = "Album"
var jmcKindCachedOrderName = "Kind"
var jmcGenreCachedOrderName = "Genre"
var jmcAlbumArtistCachedOrderName = "Album Artist"
var jmcComposerCachedOrderName = "Composer"

let iTunesImporterBPMKey = "BPM"
let iTunesImporterMovementNameKey = "Movement Name"
let iTunesImporterMovementNumKey = "Movement Number"
let iTunesImporterTrackTypeKey = "Track Type"
let iTunesImporterSkipDateKey = "Skip Date"
let iTunesImporterSampleRateKey = "Sample Rate"
let iTunesImporterKindKey = "Kind"
let iTunesImporterCommentsKey = "Comments"
let iTunesImporterPlayDateUTCKey = "Play Date UTC"
let iTunesImporterPlayDateKey = "Play Date"
let iTunesImporterDateAddedKey = "Date Added"
let iTunesImporterSizeKey = "Size"
let iTunesImporterDiscNumberKey = "Disc Number"
let iTunesImporterLocationKey = "Location"
let iTunesImporterArtistNameKey = "Artist"
let iTunesImporterAlbumNameKey = "Album"
let iTunesImporterTrackNumberKey = "Track Number"
let iTunesImporterNameKey = "Name"
let iTunesImporterAlbumArtistKey = "Album Artist"
let iTunesImporterSkipCountKey = "Skip Count"
let iTunesImporterPlayCountKey = "Play Count"
let iTunesImporterBitRateKey = "Bit Rate"
let iTunesImporterTotalTimeKey = "Total Time"
let iTunesImporterDateModifiedKey = "Date Modified"
let iTunesImporterSortAlbumKey = "Sort Album"
let iTunesImporterGenreKey = "Genre"
let iTunesImporterRatingKey = "Rating"
let iTunesImporterSortNameKey = "Sort Name"
let iTunesImporterReleaseDateKey = "Release Date"
let iTunesImporterYearKey = "Year"
let iTunesImporterComposerKey = "Composer"
let iTunesImporterSortComposerKey = "Sort Composer"
let iTunesImporterDisabledKey = "Disabled"
let iTunesImporterSortArtistKey = "Sort Artist"
let iTunesImporterSortAlbumArtistKey = "Sort Album Artist"
let iTunesImporterCompilationKey = "Compilation"
let iTunesImporterTrackIDKey = "Track ID"


let fieldsToCachedOrdersDictionary: NSDictionary = [
    "date_added" : "Date Added",
    "date_released" : "Date Released",
    "artist" : "Artist",
    "album" : "Album",
    "album_artist" : "Album Artist",
    "kind" : "Kind",
    "genre" : "Genre"
]



//other constants
var LIBRARY_MOVES_DESCRIPTION = "Added media will be moved into a subdirectory of this directory"
var LIBRARY_COPIES_DESCRIPTION = "Added media will be copied into a subdirectory of this directory"
var LIBRARY_DOES_NOTHING_DESCRIPTION = "Added media will not be organized"
let NO_ORGANIZATION_TYPE = 0
let MOVE_ORGANIZATION_TYPE = 1
let COPY_ORGANIZATION_TYPE = 2
let UNKNOWN_ARTIST_STRING = "Unknown Artist"
let UNKNOWN_ALBUM_STRING = "Unknown Album"
let UNKNOWN_ALBUM_ARTIST_STRING = "Various Artists"
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

func numberOfTracksInsideDirectory(with url: URL) -> Int {
    let absString = url.absoluteString
    return (globalRootLibrary!.tracks as! Set<Track>).filter({return ($0.location ?? "").localizedCaseInsensitiveContains(absString)}).count
}

var cachedOrders: [String : CachedOrder]? = {
    print("accessing cached orders")
    var result = [String : CachedOrder]()
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedOrder")
    do {
        let list = try managedContext.fetch(request) as! [CachedOrder]
        for order in list {
            result[order.order!] = order
            //order.mutableCachedOrder = order.track_views!.mutableCopy() as! NSMutableOrderedSet
        }
        return result
    } catch {
        print(error)
        return nil
    }
}()

func validateStringForFilename(_ string: String) -> String {
    //needed?
    let newString = String(string.characters.map({
        $0 == "/" ? ":" : $0
    }))
    return newString
}

func volumeIsAvailable(volume: Volume) -> Bool {
    let fileManager = FileManager.default
    let libraryPath = URL(string: volume.location!)!.path
    var isDirectory = ObjCBool(booleanLiteral: false)
    return fileManager.fileExists(atPath: libraryPath, isDirectory: &isDirectory) && isDirectory.boolValue
}

func getNonMatchingTracks(library: Library, visualUpdateHandler: ProgressBarController?) -> [DisparateTrack] {
    let templateBundle = library.organization_template
    DispatchQueue.main.async {
        visualUpdateHandler?.prepareForNewTask(actionName: "Checking organization template for", thingName: "tracks", thingCount: library.tracks!.count)
    }
    var index = 0
    let result = (library.tracks as! Set<Track>).flatMap({track -> DisparateTrack? in
        if let location = track.location {
            if let currentURL = URL(string: location) {
                let potentialURL = templateBundle!.match(track).getURL(for: track, withExtension: currentURL.pathExtension)!
                DispatchQueue.main.async {
                    visualUpdateHandler?.increment(thingsDone: index)
                    index += 1
                }
                if potentialURL != currentURL {
                    return DisparateTrack(track: track, potentialURL: potentialURL)
                } else {
                    return nil
                }
            }
        }
        DispatchQueue.main.async {
            visualUpdateHandler?.increment(thingsDone: index)
            index += 1
        }
        return nil
    })
    return result
}

func changeVolumeLocation(volume: Volume, newLocation: URL) {
    let oldVolumeURL = URL(string: volume.location!)!
    let oldVolumeURLAbsoluteString = oldVolumeURL.absoluteString
    let newAbsoluteString = newLocation.absoluteString
    for track in globalRootLibrary!.tracks! as! Set<Track> {
        let url = URL(string: track.location!)!
        let trackVolume = getVolumeOfURL(url: url)
        if trackVolume == oldVolumeURL {
            track.location = track.location!.replacingOccurrences(of: oldVolumeURLAbsoluteString, with: newAbsoluteString, options: .anchored, range: nil)
        }
    }
    if let watchDirs = globalRootLibrary?.watch_dirs as? [URL] {
        var newWatchDirs = [URL]()
        for url in watchDirs {
            let watchDirVolume = getVolumeOfURL(url: url)
            if watchDirVolume == oldVolumeURL {
                let oldWatchDirAbsoluteString = url.absoluteString
                let newURLAbsoluteString = oldWatchDirAbsoluteString.replacingOccurrences(of: oldVolumeURLAbsoluteString, with: newAbsoluteString, options: .anchored, range: nil)
                newWatchDirs.append(URL(string: newURLAbsoluteString)!)
            } else {
                newWatchDirs.append(url)
            }
        }
        globalRootLibrary?.watch_dirs = newWatchDirs as NSArray
    }
}

func changeLibraryCentralMediaFolder(library: Library, newLocation: URL) {
    library.organization_template?.default_template?.base_url_string = newLocation.absoluteString
}

func getVolumeOfURL(url: URL) -> URL {
    do {
        let key = URLResourceKey.volumeURLKey
        let resourceValues = try url.resourceValues(forKeys: Set([key]))
        let volURL = resourceValues.volume
        return volURL!.standardizedFileURL
    } catch {
        print(error)
        fatalError()
    }
}

func checkIfVolumeExists(withURL url: URL) -> Volume? {
    let fetch = NSFetchRequest<Volume>(entityName: "Volume")
    let predicate = NSPredicate(format: "location == %@", url.absoluteString)
    fetch.predicate = predicate
    do {
        let results = try managedContext.fetch(fetch)
        if results.count > 0 {
            return results[0]
        } else {
            return nil
        }
    } catch {
        print(error)
        return nil
    }
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
    } else if UTTypeConformsTo(uti, kUTTypePDF) {
        return "pdf"
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

let DEFAULT_COLUMN_VISIBILITY_DICTIONARY_CONSOLIDATOR: [String : Int] = [
    "album" : 1,
    "artist" : 0,
    "bit_rate" : 1,
    "comments" : 1,
    "composer" : 1,
    "date_added" : 1,
    "date_last_played" : 1,
    "date_last_skipped" : 1,
    "date_modified" : 1,
    "date_released" : 1,
    "disc_number" : 1,
    "equalizer_preset" : 1,
    "file_kind" : 1,
    "genre" : 1,
    "is_enabled" : 1,
    "is_playing" : 1,
    "movement_name" : 1,
    "movement_number" : 1,
    "name" : 0,
    "play_count" : 1,
    "playlist_number" : 1,
    "rating" : 1,
    "sample_rate" : 1,
    "size" : 1,
    "skip_count" : 1,
    "sort_album" : 1,
    "sort_album_artist" : 1,
    "sort_artist" : 1,
    "sort_composer" : 1,
    "sort_name" : 1,
    "time" : 1,
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

func createMD5HashOf(data: Data) -> String {
    //only used for images, to test data equality
    var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    data.withUnsafeBytes { bytes in
        CC_MD5(bytes, CC_LONG(data.count), &digest)
    }
    let hashData = Data(bytes: digest)
    let hashString = hashData.base64EncodedString()
    return hashString
}

func getFileType(image: Data) -> String? {
    guard let imageSource = CGImageSourceCreateWithData(image as NSData, [:] as NSDictionary) else { return nil }
    guard let uniformTypeIdentifier = CGImageSourceGetType(imageSource) else { return nil }
    return getImageExtension(uniformTypeIdentifier)
}

func getFileTypeFrom(url: URL) -> String? {
    guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, [:] as NSDictionary) else {
        return nil
    }
    guard let uniformTypeIdentifier = CGImageSourceGetType(imageSource) else {
        return nil
    }
    return getImageExtension(uniformTypeIdentifier)
}

func getUTIFrom(url: URL) -> CFString? {
    guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, [:] as NSDictionary) else {
        return nil
    }
    guard let uniformTypeIdentifier = CGImageSourceGetType(imageSource) else {
        return nil
    }
    return uniformTypeIdentifier
}

var jmcUnknownArtist = {() -> Artist in
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Artist")
    let predicate = NSPredicate(format: "id == 1")
    request.predicate = predicate
    do {
        let result = try managedContext.fetch(request) as! [Artist]
        return result[0]
    } catch {
        let unknownArtist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: managedContext) as! Artist
        unknownArtist.id = 1
        unknownArtist.name = "Unknown Artist"
        return unknownArtist
    }
}

var jmcUnknownAlbum = {() -> Album in
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Album")
    let predicate = NSPredicate(format: "id == 1")
    request.predicate = predicate
    do {
        let result = try managedContext.fetch(request) as! [Album]
        return result[0]
    } catch {
        let unknownAlbum = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
        unknownAlbum.id = 1
        unknownAlbum.name = "Unknown Album"
        return unknownAlbum
    }
}

var jmcUnknownComposer = {() -> Composer in
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Composer")
    let predicate = NSPredicate(format: "id == 1")
    request.predicate = predicate
    do {
        let result = try managedContext.fetch(request) as! [Composer]
        return result[0]
    } catch {
        let unknownComposer = NSEntityDescription.insertNewObject(forEntityName: "Composer", into: managedContext) as! Composer
        unknownComposer.id = 1
        unknownComposer.name = "Unknown Composer"
        return unknownComposer
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

func checkIfAlbumExists(withName name: String, withArtist artist: Artist) -> Album? {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Album")
    let predicate = NSPredicate(format: "name == %@ and album_artist == %@", name, artist)
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
        if sortName != nil && sortName != name {
            track.sort_name = sortName
        }
    }
}

func editMovementName(_ tracks: [Track]?, name: String) {
    for track in tracks! {
        track.movement_name = name
    }
}

func editMovementNum(_ tracks: [Track]?, num: Int) {
    for track in tracks! {
        track.movement_number = num as NSNumber
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
        new_artist.id = globalRootLibrary?.next_artist_id
        globalRootLibrary!.next_artist_id = Int(globalRootLibrary!.next_artist_id!) + 1 as NSNumber
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
        new_composer.id = globalRootLibrary?.next_composer_id
        globalRootLibrary!.next_composer_id = Int(globalRootLibrary!.next_composer_id!) + 1 as NSNumber
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
    print(albumName)
    guard let tracks = tracks else { return }
    var artistTrackDictionary = [Artist : [Track]]()
    for track in tracks {
        if artistTrackDictionary[track.artist!] == nil {
            artistTrackDictionary[track.artist!] = [Track]()
        }
        artistTrackDictionary[track.artist!]?.append(track)
    }
    for (artist, tracks) in artistTrackDictionary {
        if let albumCheck = checkIfAlbumExists(withName: albumName, withArtist: artist) {
            for track in tracks {
                track.album = albumCheck
                let albumName = albumCheck.name!
                let sortAlbumName = getSortName(albumName)
                if sortAlbumName != albumName {
                    track.sort_album = sortAlbumName
                }
            }
        } else {
            let new_album = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
            new_album.name = albumName
            new_album.id = globalRootLibrary?.next_album_id
            new_album.album_artist = artist
            globalRootLibrary!.next_album_id = Int(globalRootLibrary!.next_album_id!) + 1 as NSNumber
            let sortAlbumName = getSortName(albumName)
            for track in tracks {
                track.album = new_album
                if sortAlbumName != albumName {
                    track.sort_album = sortAlbumName
                }
            }
        }
    }
}

func editAlbumArtist(_ tracks: [Track]?, albumArtistName: String) {
    guard let tracks = tracks else { return }
    print(albumArtistName)
    let artistCheck = checkIfArtistExists(albumArtistName)
    let albums = Set(tracks.map({return $0.album!}))
    var nameAlbumDictionary = [String : [Album]]()
    for album in albums {
        if nameAlbumDictionary[album.name!] == nil {
            nameAlbumDictionary[album.name!] = [Album]()
        }
        nameAlbumDictionary[album.name!]!.append(album)
    }
    var combinedAlbums = [Album]()
    for (_, albums) in nameAlbumDictionary {
        combinedAlbums.append(albums.reduce(albums.first!) {
            return combineAlbums($0, $1)
        })
    }
    if artistCheck != nil {
        for album in combinedAlbums {
            album.album_artist = artistCheck!
            let artistName = artistCheck!.name!
            let sortArtistName = getSortName(artistName)
            if sortArtistName != artistName {
                for track in album.tracks as! Set<Track> {
                    track.sort_album_artist = sortArtistName
                }
            }
        }
    } else {
        let new_artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: managedContext) as! Artist
        new_artist.name = albumArtistName
        new_artist.id = globalRootLibrary?.next_artist_id
        globalRootLibrary!.next_artist_id = Int(globalRootLibrary!.next_artist_id!) + 1 as NSNumber
        let sortArtistName = getSortName(albumArtistName)
        for album in combinedAlbums {
            album.album_artist = new_artist
        }
        for track in tracks {
            if sortArtistName != albumArtistName {
                track.sort_album_artist = sortArtistName
            }
        }
    }
}

func combineAlbums(_ firstAlbum: Album, _ secondAlbum: Album) -> Album {
    //combine primary artwork
    if firstAlbum.primary_art != nil {
        if secondAlbum.primary_art != nil {
            firstAlbum.addToOther_art(secondAlbum.primary_art!)
        }
    } else {
        if secondAlbum.primary_art != nil {
            firstAlbum.primary_art = secondAlbum.primary_art
        }
    }
    //combine secondary artwork
    if let secondOtherArt = secondAlbum.other_art, secondOtherArt.count > 0 {
        if firstAlbum.primary_art == nil {
            firstAlbum.primary_art = secondAlbum.other_art?.firstObject as! AlbumArtwork
        } else {
            firstAlbum.addToOther_art(secondAlbum.other_art!)
        }
    }
    //combine other files
    if let secondOtherFiles = secondAlbum.other_files, secondOtherFiles.count > 0 {
        firstAlbum.addToOther_files(secondAlbum.other_files!)
    }
    
    //combine tracks
    for track in secondAlbum.tracks as! Set<Track> {
        track.album = firstAlbum
    }
    
    return firstAlbum
}

func notEnablingUndo(stuff: (Void) -> Void) {
    managedContext.processPendingChanges()
    managedContext.undoManager?.disableUndoRegistration()
    stuff()
    managedContext.processPendingChanges()
    managedContext.undoManager?.enableUndoRegistration()
}

func withUndoBlock(name: String, stuff: (Void) -> Void) {
    managedContext.undoManager?.beginUndoGrouping()
    stuff()
    managedContext.undoManager?.endUndoGrouping()
    managedContext.undoManager?.setActionName(name)
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

func editReleaseDate(_ tracks: [Track]?, date: JMDate) {
    if tracks != nil {
        for album in Set(tracks!.flatMap({return $0.album})) {
            album.release_date = date
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

let keyToCachedOrderDictionary = [
    "artist_order" : "Artist",
    "album_order" : "Album",
    "date_added_order": "Date Added",
    "name_order" : "Name",
    "album_artist_order" : "Album Artist",
    "genre_order" : "Genre",
    "kind_order" : "Kind",
    "release_date_order" : "Date Released",
    "composer_order" : "Composer"
]

func fixIndicesImmutable(order: CachedOrder) {
    notEnablingUndo {
        var key: String
        switch order.order! {
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
        for (index, trackView) in order.track_views!.enumerated() {
            (trackView as AnyObject).setValue(index, forKey: key)
        }
        order.needs_update = false
    }
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


func reorderForTracks(_ tracks: [Track], cachedOrder: CachedOrder, subContext: NSManagedObjectContext?) {
    let actualTracks = subContext != nil ? tracks : tracks.map({return managedContext.object(with: $0.objectID) as! Track})
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
    if let cachedOrderTrackViews = cachedOrder.track_views, actualTracks.count > cachedOrderTrackViews.count {
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
        cachedOrder.needs_update = true
        cachedOrder.track_views = NSMutableOrderedSet(array: newTracks.map({return ($0 as! Track).view!}))
    } else {
        let mutableVersion = cachedOrder.track_views!.mutableCopy() as! NSMutableOrderedSet
        mutableVersion.removeObjects(in: actualTracks.map({return $0.view!}))
        for track in actualTracks {
            let index = insert(mutableVersion, track: track.view!, isGreater: comparator)
            print("index is \(index)")
            mutableVersion.insert(track.view!, at: index)
        }
        cachedOrder.track_views = mutableVersion
        cachedOrder.needs_update = true
    }
}
