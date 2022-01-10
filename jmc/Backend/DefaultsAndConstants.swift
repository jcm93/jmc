//
//  DefaultsAndConstants.swift
//  jmc
//
//  Created by John Moody on 9/7/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

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
let DEFAULTS_NUM_PAST_TRACKS = "numPastTracks"
let DEFAULTS_ARTWORK_SHOWS_SELECTED = "artShowsSelected"
let DEFAULTS_TABLE_SKIP_SHOWS_NEW_TRACK = "tableSkipShowsNewTrack"
let DEFAULTS_TABLE_SORT_BEHAVIOR = "tableSortBehavior"
let DEFAULTS_TRACK_PLAY_REGISTER_POINT = "registerTrackPlayPoint"
let DEFAULTS_TRACK_QUEUE_VISIBLE = "queueVisible"
let DEFAULTS_SCROBBLES = "scrobbles"
var DEFAULTS_DURATION_SHOWS_TIME_REMAINING = "durationShowsTimeRemaining"
let DEFAULTS_DOESNT_ASKS_DELETE_PLAYLIST = "doesntAskBeforeRemovingTracksFromPlaylist"
let DEFAULTS_LAST_SELECTED_ARTIST_ROW = "lastSelectedArtistRowArtistView"
let DEFAULTS_VIEW_TYPE_STRING = "libraryViewType"

enum TableSortBehavior: Int {
    case followsNothing, followsSelection, followsCurrentTrack
}

let DEFAULTS_INITIAL_DEFAULTS: [String : Any] = [
    DEFAULTS_SHUFFLE_STRING : true,
    DEFAULTS_VOLUME_STRING : 1.0,
    DEFAULTS_IS_EQ_ENABLED_STRING : 1,
    DEFAULTS_SHOWS_ARTWORK_STRING : true,
    DEFAULTS_CHECK_EMBEDDED_ARTWORK_STRING : true,
    DEFAULTS_CHECK_ALBUM_DIRECTORY_FOR_ART_STRING : true,
    DEFAULTS_SHARING_STRING : true,
    DEFAULTS_NUM_PAST_TRACKS : 3,
    DEFAULTS_ARTWORK_SHOWS_SELECTED : true,
    DEFAULTS_TABLE_SKIP_SHOWS_NEW_TRACK : false,
    DEFAULTS_TABLE_SORT_BEHAVIOR : 0,
    DEFAULTS_TRACK_PLAY_REGISTER_POINT : 0.75,
    DEFAULTS_TRACK_QUEUE_VISIBLE : true,
    DEFAULTS_SCROBBLES : true
]

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
let LIBRARY_MOVES_DESCRIPTION = "Added media will be moved into a subdirectory of this directory"
let LIBRARY_COPIES_DESCRIPTION = "Added media will be copied into a subdirectory of this directory"
let LIBRARY_DOES_NOTHING_DESCRIPTION = "Added media will not be organized"
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
let SOURCE_LIST_ITEM_VIEW_TYPE_SONGS = 0
let SOURCE_LIST_ITEM_VIEW_TYPE_ARTISTS = 1

let CUE_SHEET_UTI_STRING = "com.goldenhawk.cdrwin-cuesheet"

let SOURCE_FETCH_REQUEST = NSFetchRequest<NSFetchRequestResult>(entityName: "SourceListItem")
let TRACK_FETCH_REQUEST = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
let TRACK_VIEW_FETCH_REQUEST = NSFetchRequest<NSFetchRequestResult>(entityName: "TrackView")
let ALBUM_FETCH_REQUEST = NSFetchRequest<NSFetchRequestResult>(entityName: "Album")
let ARTIST_FETCH_REQUEST = NSFetchRequest<NSFetchRequestResult>(entityName: "Artist")
let COMPOSER_FETCH_REQUEST = NSFetchRequest<NSFetchRequestResult>(entityName: "Composer")
let SONG_COLLECTION_FETCH_REQUEST = NSFetchRequest<NSFetchRequestResult>(entityName: "SongCollection")

let IS_NETWORK_PREDICATE = NSPredicate(format: "is_network == %@", NSNumber(booleanLiteral: true))

let BATCH_PURGE_NETWORK_FETCH_REQUESTS: [NSFetchRequest<NSFetchRequestResult>] = [COMPOSER_FETCH_REQUEST, ARTIST_FETCH_REQUEST, ALBUM_FETCH_REQUEST, TRACK_VIEW_FETCH_REQUEST, TRACK_FETCH_REQUEST, SOURCE_FETCH_REQUEST, SONG_COLLECTION_FETCH_REQUEST]
let VALID_ARTWORK_TYPE_EXTENSIONS = ["jpg", "png", "tiff", "gif", "pdf"]
let VALID_FILE_TYPES = ["aac", "adts", "ac3", "aif", "aiff", "aifc", "caf", "mp3", "mp4", "m4a", "snd", "au", "sd2", "wav", "alac", "flac"]


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
    "artist" : 1,
    "album_artist" : 1,
    "album_by_artist" : 0,
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
    "album_artist" : 1,
    "album_by_artist" : 0,
    "artist" : 1,
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

