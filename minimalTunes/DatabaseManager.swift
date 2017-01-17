//
//  DatabaseManager.swift
//  minimalTunes
//
//  Created by John Moody on 6/29/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
import CoreFoundation
import CoreServices
import AVFoundation

func instanceCheck(entity: String, name: String) -> NSManagedObject? {
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    let fetch_req = NSFetchRequest(entityName: entity)
    let predicate = NSPredicate(format: "name == %@", name)
    fetch_req.predicate = predicate
    var results: [NSManagedObject]?
    do {
        results = try managedContext.executeFetchRequest(fetch_req) as! [NSManagedObject]
    } catch {
        print("err: \(error)")
    }
    if results != nil && results!.count > 0 {
        return results![0]
    }
    else {
        return nil
    }
    
}

func getArt(name: String) -> AlbumArtworkCollection? {
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    let fetch_req = NSFetchRequest(entityName: "AlbumArtworkCollection")
    let predicate = NSPredicate(format: "album.name == %@", name)
    fetch_req.predicate = predicate
    var results: [AlbumArtworkCollection]
    do {
        results = try managedContext.executeFetchRequest(fetch_req) as! [AlbumArtworkCollection]
        return results[0]
    } catch {
        print("err: \(error)")
        return nil
    }
}

struct FSError {
    var whichError: Int
}

class FileAddToDatabaseError: NSObject {
    let urlString: String
    let error: String
    init(url: String, error: String) {
        self.urlString = url
        self.error = error
    }
}

class DatabaseManager: NSObject {
    
    var organizesMedia: Bool = true
    let fileManager = NSFileManager.defaultManager()
    
    lazy var cachedOrders: [CachedOrder]? = {
        let fr = NSFetchRequest(entityName: "CachedOrder")
        do {
            let res = try managedContext.executeFetchRequest(fr) as! [CachedOrder]
            return res
        } catch {
            print(error)
            return nil
        }
    }()
    
    func getArtworkFromFile(urlString: String) -> NSData? {
        print("checking for art in file")
        let url = NSURL(string: urlString)
        let mediaObject = AVAsset(URL: url!)
        var art: NSData?
        let commonMeta = mediaObject.commonMetadata
        for metadataItem in commonMeta {
            if metadataItem.commonKey == "artwork" {
                print("found art in file")
                art = metadataItem.value as? NSData
            }
        }
        if art != nil {
            return art
        }
        else {
            return nil
        }
    }
    
    func searchAlbumDirectoryForArt(track: Track) -> NSURL? {
        let locationURL = NSURL(string: track.location!)
        let albumDirectoryURL = locationURL!.URLByDeletingLastPathComponent!
        do {
            let albumDirectoryContents = try fileManager.contentsOfDirectoryAtURL(albumDirectoryURL, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
            let potentialImages = albumDirectoryContents.filter({VALID_ARTWORK_TYPE_EXTENSIONS.contains($0.pathExtension!.lowercaseString)})
            if potentialImages.count > 0 {
                return potentialImages[0]
            } else {
                return nil
            }
        } catch {
            print("error looking in album directory for art: \(error)")
            return nil
        }
    }
    
    func addPrimaryArtForTrack(track: Track, art: NSData) -> Track? {
        print("adding new primary album art")
        let artHash = art.hashValue
        if let currentPrimaryHash = track.album?.primary_art?.image_hash {
            if Int(currentPrimaryHash) == artHash {
                print("artwork collision")
                return nil
            }
        }
        guard let artImage = NSImage(data: art) else {return nil}
        let newArtwork = NSEntityDescription.insertNewObjectForEntityForName("AlbumArtwork", inManagedObjectContext: managedContext) as! AlbumArtwork
        newArtwork.image_hash = artHash
        if track.album?.primary_art != nil {
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
        let artURL = NSURL(string: track.location!)?.URLByDeletingLastPathComponent?.URLByAppendingPathComponent("\(artHash).png")
        newArtwork.artwork_location = artURL!.absoluteString
        let artTIFF = artImage.TIFFRepresentation
        let artRep = NSBitmapImageRep(data: artTIFF!)
        let artPNG = artRep?.representationUsingType(.NSPNGFileType, properties: [:])
        track.album?.primary_art = newArtwork
        do {
            try artPNG?.writeToURL(artURL!, options: NSDataWritingOptions.DataWritingAtomic)
        } catch {
            print("error writing file: \(error)")
        }
        return track
    }
    
    //OK -- discrete
    func moveFileAfterEdit(track: Track) {
        let organizationType = NSUserDefaults.standardUserDefaults().objectForKey(DEFAULTS_LIBRARY_ORGANIZATION_TYPE_STRING) as! Int
        guard organizationType != NO_ORGANIZATION_TYPE else {return}
        let artistFolderName = track.album?.album_artist?.name != nil ? track.album!.album_artist!.name! : track.artist?.name != nil ? track.artist!.name! : UNKNOWN_ARTIST_STRING
        let albumFolderName = track.album?.name != nil ? track.album!.name! : UNKNOWN_ALBUM_STRING
        let trackName: String
        if track.track_num != nil {
            trackName = "\(track.track_num!) \(track.name!)"
        } else {
            trackName = "\(track.name!)"
        }
        let currentLocationURL = NSURL(string: track.location!)
        let fileExtension = currentLocationURL?.pathExtension
        let oldAlbumDirectoryURL = currentLocationURL?.URLByDeletingLastPathComponent
        let newArtistDirectoryURL = currentLocationURL?.URLByDeletingLastPathComponent?.URLByDeletingLastPathComponent?.URLByDeletingLastPathComponent?.URLByAppendingPathComponent(artistFolderName)
        let newAlbumDirectoryURL = newArtistDirectoryURL?.URLByAppendingPathComponent(albumFolderName)
        let newLocationURL = currentLocationURL?.URLByDeletingLastPathComponent?.URLByDeletingLastPathComponent?.URLByDeletingLastPathComponent?.URLByAppendingPathComponent(artistFolderName).URLByAppendingPathComponent(albumFolderName).URLByAppendingPathComponent(trackName).URLByAppendingPathExtension(fileExtension!)
        //check if directories already exist
        do {
            try fileManager.createDirectoryAtURL(newAlbumDirectoryURL!, withIntermediateDirectories: true, attributes: nil)
            try fileManager.moveItemAtURL(currentLocationURL!, toURL: newLocationURL!)
            track.location = newLocationURL?.absoluteString
        } catch {
            print("error moving file: \(error)")
        }
        do {
            let currentAlbumDirectoryContents = try fileManager.contentsOfDirectoryAtURL(oldAlbumDirectoryURL!, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
            if currentAlbumDirectoryContents.count == 1 {
                let lastFileURL = currentAlbumDirectoryContents[0]
                let ext = lastFileURL.pathExtension!.lowercaseString
                if VALID_ARTWORK_TYPE_EXTENSIONS.contains(ext) {
                    let fileName = lastFileURL.lastPathComponent
                    try fileManager.moveItemAtURL(lastFileURL, toURL: (newLocationURL?.URLByDeletingLastPathComponent?.URLByAppendingPathComponent(fileName!))!)
                }
            }
        } catch {
            print("error checking directory: \(error)")
        }
    }
    
    func getMDItemFromURL(url: NSURL) -> MDItem? {
        let item = MDItemCreateWithURL(kCFAllocatorDefault, url)
        return item
    }
    
    func addSortValues(track: Track) {
        track.sort_name = getSortName(track.name)
        track.sort_artist = getSortName(track.artist?.name)
        track.sort_album = getSortName(track.album?.name)
        track.sort_album_artist = getSortName(track.album?.album_artist?.name)
        track.sort_composer = getSortName(track.composer?.name)
    }
    
    func handleDirectoryEnumerationError(url: NSURL, error: NSError) -> Bool {
        print("this is bad! returning true anyway")
        return true
    }
    
    func addTracksFromURLStrings(urlStrings: [String]) -> [FileAddToDatabaseError] {
        var errors = [FileAddToDatabaseError]()
        var addedArtists = [String: Artist]()
        var addedAlbums = [String: Album]()
        var addedComposers = [String: Composer]()
        var addedGenres = [String: Genre]()
        var tracks = [Track]()
        var index = 0
        for urlString in urlStrings {
            var addedArtist: Artist?
            var addedAlbum: Album?
            var addedComposer: Composer?
            var addedGenre: Genre?
            var hasArt = false
            guard let url = NSURL(string: urlString) else {errors.append(FileAddToDatabaseError(url: urlString, error: "Failure constructing NSURL"));continue}
            guard let mediaFileObject = getMDItemFromURL(url) else {errors.append(FileAddToDatabaseError(url: urlString, error: "Failure getting file metadata"));continue}
            let track = NSEntityDescription.insertNewObjectForEntityForName("Track", inManagedObjectContext: managedContext) as! Track
            let trackView = NSEntityDescription.insertNewObjectForEntityForName("TrackView", inManagedObjectContext: managedContext) as! TrackView
            trackView.track = track
            var art: NSData?
            track.sample_rate = MDItemCopyAttribute(mediaFileObject, "kMDItemAudioSampleRate" as CFString) as? Int
            track.date_added = NSDate()
            track.date_modified = MDItemCopyAttribute(mediaFileObject, "kMDItemContentModificationDate") as? NSDate
            track.file_kind = MDItemCopyAttribute(mediaFileObject, "kMDItemKind") as? String
            let bitRateCheck = MDItemCopyAttribute(mediaFileObject, "kMDItemAudioBitRate") as? Int
            if bitRateCheck != nil {
                track.bit_rate = bitRateCheck!/1000
            } else {
                managedContext.deleteObject(track.view!)
                managedContext.deleteObject(track)
                continue
            }
            track.id = library?.next_track_id
            library?.next_track_id = Int(library!.next_track_id!) + 1
            track.status = 0
            track.time = {
                if let time = (MDItemCopyAttribute(mediaFileObject, "kMDItemDurationSeconds") as? Int) {
                    return time * 1000
                } else {
                    return nil
                }
            }()
            track.size = MDItemCopyAttribute(mediaFileObject, "kMDItemFSSize") as! Int
            let name = MDItemCopyAttribute(mediaFileObject, "kMDItemTitle") as? String
            if name != nil {
                track.name = name
            } else {
                track.name = url.URLByDeletingPathExtension!.lastPathComponent!
            }
            track.track_num = MDItemCopyAttribute(mediaFileObject, "kMDItemAudioTrackNumber") as? Int
            if let genreCheck = MDItemCopyAttribute(mediaFileObject, "kMDItemMusicalGenre") as? String {
                if let alreadyAddedGenre = addedGenres[genreCheck] {
                    track.genre = alreadyAddedGenre
                } else {
                    let newGenre = NSEntityDescription.insertNewObjectForEntityForName("Genre", inManagedObjectContext: managedContext) as! Genre
                    newGenre.name = genreCheck
                    newGenre.id = library?.next_genre_id
                    library?.next_genre_id = Int(library!.next_genre_id!) + 1
                    track.genre = newGenre
                    addedGenres[genreCheck] = newGenre
                    addedGenre = newGenre
                }
            }
            if let albumCheck = MDItemCopyAttribute(mediaFileObject, "kMDItemAlbum") as? String {
                if let alreadyAddedAlbum = addedAlbums[albumCheck] {
                    track.album = alreadyAddedAlbum
                } else {
                    let newAlbum = NSEntityDescription.insertNewObjectForEntityForName("Album", inManagedObjectContext: managedContext) as! Album
                    newAlbum.name = albumCheck
                    newAlbum.id = library?.next_album_id
                    library?.next_album_id = Int(library!.next_album_id!) + 1
                    track.album = newAlbum
                    addedAlbums[albumCheck] = newAlbum
                    addedAlbum = newAlbum
                }
            }
            if let artistCheck = MDItemCopyAttribute(mediaFileObject, "kMDItemAuthors") as? [String] {
                let mainArtistCheck = artistCheck[0]
                if let alreadyAddedArtist = addedArtists[mainArtistCheck] {
                    track.artist = alreadyAddedArtist
                } else {
                    let newArtist = NSEntityDescription.insertNewObjectForEntityForName("Artist", inManagedObjectContext: managedContext) as! Artist
                    newArtist.name = mainArtistCheck
                    newArtist.id = library?.next_artist_id
                    library?.next_artist_id = Int(library!.next_artist_id!) + 1
                    track.artist = newArtist
                    addedArtists[mainArtistCheck] = newArtist
                    addedArtist = newArtist
                }
            }
            if let composerCheck = MDItemCopyAttribute(mediaFileObject, "kMDItemComposer") as? String {
                if let alreadyAddedComposer = addedComposers[composerCheck] {
                    track.composer = alreadyAddedComposer
                } else {
                    let newComposer = NSEntityDescription.insertNewObjectForEntityForName("Composer", inManagedObjectContext: managedContext) as! Composer
                    newComposer.name = composerCheck
                    newComposer.id = library?.next_composer_id
                    library?.next_composer_id = Int(library!.next_composer_id!) + 1
                    track.composer = newComposer
                    addedComposers[composerCheck] = newComposer
                    addedComposer = newComposer
                }
            }
            //add sort values
            addSortValues(track)
            autoreleasepool {
                /*var otherMetadataForAlbumArt = AVAsset(URL: url).commonMetadata
                otherMetadataForAlbumArt = otherMetadataForAlbumArt.filter({return $0.commonKey == "artwork"})
                if otherMetadataForAlbumArt.count > 0 {
                    art = otherMetadataForAlbumArt[0].value as? NSData
                    if art != nil {
                        hasArt = true
                    }
                }*/
                if moveFileToAppropriateLocationForTrack(track, currentURL: url) != nil {
                    /*if hasArt == true {
                        addPrimaryArtForTrack(track, art: art!)
                    }*/
                    tracks.append(track)
                } else {
                    print("error moving")
                    errors.append(FileAddToDatabaseError(url: urlString, error: "Couldn't move/copy file to album directory"))
                    managedContext.deleteObject(track)
                    managedContext.deleteObject(trackView)
                    if addedArtist != nil {
                        managedContext.deleteObject(addedArtist!)
                    }
                    if addedGenre != nil {
                        managedContext.deleteObject(addedGenre!)
                    }
                    if addedComposer != nil {
                        managedContext.deleteObject(addedComposer!)
                    }
                    if addedAlbum != nil {
                        managedContext.deleteObject(addedAlbum!)
                    }
                }
            }
            print(index)
            addedArtist = nil
            addedAlbum = nil
            addedGenre = nil
            addedComposer = nil
            index += 1
        }
        for order in cachedOrders! {
            reorderForTracks(tracks, cachedOrder: order)
        }
        do {
            try managedContext.save()
        } catch {
            print(error)
        }
        return errors
    }
    
    func moveFileToAppropriateLocationForTrack(track: Track, currentURL: NSURL) -> NSURL? {
        let fileName = {() -> String in
            switch NSUserDefaults.standardUserDefaults().boolForKey(DEFAULTS_RENAMES_FILES_STRING) {
            case true:
                return validateStringForFilename(self.formFilenameForTrack(track))
            default:
                return currentURL.lastPathComponent!
            }
        }()
        var albumDirectoryURL: NSURL?
        var fileURL: NSURL?
        let orgType = NSUserDefaults.standardUserDefaults().objectForKey(DEFAULTS_LIBRARY_ORGANIZATION_TYPE_STRING)! as! Int
        if orgType == NO_ORGANIZATION_TYPE {
            track.location = currentURL.URLByDeletingLastPathComponent!.URLByAppendingPathComponent(fileName).absoluteString
            fileURL = currentURL
        } else {
            let libraryPathURL = NSURL(fileURLWithPath: NSUserDefaults.standardUserDefaults().objectForKey(DEFAULTS_LIBRARY_PATH_STRING) as! String)
            let albumArtist = validateStringForFilename(track.album?.album_artist?.name != nil ? track.album!.album_artist!.name! : track.artist?.name != nil ? track.artist!.name! : UNKNOWN_ARTIST_STRING)
            let album = validateStringForFilename(track.album?.name != nil ? track.album!.name! : UNKNOWN_ALBUM_STRING)
            albumDirectoryURL = libraryPathURL.URLByAppendingPathComponent(albumArtist).URLByAppendingPathComponent(album)
            do {
                try fileManager.createDirectoryAtURL(albumDirectoryURL!, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("error creating album directory: \(error)")
            }
            do {
                fileURL = albumDirectoryURL?.URLByAppendingPathComponent(fileName)
                if orgType == MOVE_ORGANIZATION_TYPE {
                    try fileManager.moveItemAtURL(currentURL, toURL: fileURL!)
                } else {
                    try fileManager.copyItemAtURL(currentURL, toURL: fileURL!)
                }
                track.location = fileURL?.absoluteString
            } catch {
                print("error while moving/copying files: \(error)")
            }
        }
        return fileURL
    }
    
    func moveFileForNetworkTrackToAppropriateLocationWithData(track: Track, data: NSData) -> Bool {
        let fileName = {() -> String in
            switch NSUserDefaults.standardUserDefaults().boolForKey(DEFAULTS_RENAMES_FILES_STRING) {
            case true:
                return self.formFilenameForTrack(track)
            default:
                return NSURL(string: track.location!)!.lastPathComponent!
            }
        }()
        var albumDirectoryURL: NSURL?
        var fileURL: NSURL?
        let libraryPathURL = NSURL(fileURLWithPath: NSUserDefaults.standardUserDefaults().objectForKey(DEFAULTS_LIBRARY_PATH_STRING) as! String)
        let albumArtist = validateStringForFilename(track.album?.album_artist?.name != nil ? track.album!.album_artist!.name! : track.artist?.name != nil ? track.artist!.name! : UNKNOWN_ARTIST_STRING)
        let album = validateStringForFilename(track.album?.name != nil ? track.album!.name! : UNKNOWN_ALBUM_STRING)
        albumDirectoryURL = libraryPathURL.URLByAppendingPathComponent(albumArtist).URLByAppendingPathComponent(album)
        do {
            try fileManager.createDirectoryAtURL(albumDirectoryURL!, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("error creating album directory: \(error)")
            return false
        }
        do {
            fileURL = albumDirectoryURL?.URLByAppendingPathComponent(fileName)
            try data.writeToURL(fileURL!, options: NSDataWritingOptions.DataWritingAtomic)
            track.location = fileURL?.absoluteString
        } catch {
            print("error while moving/copying files: \(error)")
            return false
        }
        return true
    }
    
    func formFilenameForTrack(track: Track) -> String {
        let discNumberStringRepresentation: String
        if track.disc_number != nil {
            discNumberStringRepresentation = "\(String(track.disc_number))-"
        } else {
            discNumberStringRepresentation = ""
        }
        let trackNumberStringRepresentation: String
        if track.track_num != nil {
            let trackNumber = Int(track.track_num!)
            if trackNumber < 10 {
                trackNumberStringRepresentation = "0\(trackNumber)"
            } else {
                trackNumberStringRepresentation = String(trackNumber)
            }
        } else {
            trackNumberStringRepresentation = ""
        }
        let trackNameString = track.name != nil ? track.name! : ""
        let trackExtension = NSURL(string: track.location!)!.pathExtension!
        var filenameString = "\(discNumberStringRepresentation)\(trackNumberStringRepresentation) \(trackNameString).\(trackExtension)"
        if filenameString == " " {
            filenameString = NO_FILENAME_STRING
        }
        return filenameString
    }
    
    func createFileForNetworkTrack(track: Track, data: NSData, trackMetadata: NSDictionary) -> Bool {
        let newTrack = NSEntityDescription.insertNewObjectForEntityForName("Track", inManagedObjectContext: managedContext) as! Track
        let newTrackView = NSEntityDescription.insertNewObjectForEntityForName("TrackView", inManagedObjectContext: managedContext) as! TrackView
        newTrackView.track = newTrack
        newTrack.id = library?.next_track_id
        newTrack.status = nil
        library?.next_track_id = Int(library!.next_track_id!) + 1
        newTrack.status = 1
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        var addedArtist: Artist?
        var addedAlbum: Album?
        var addedComposer: Composer?
        var addedGenre: Genre?
        var addedAlbumArtist: Artist?
        for field in trackMetadata.allKeys as! [String] {
            switch field {
            case "name":
                newTrack.name = trackMetadata["name"] as? String
                newTrackView.name_order = trackMetadata["name_order"] as? Int
            case "time":
                newTrack.time = trackMetadata["time"] as? NSNumber
            case "artist":
                let artistName = trackMetadata["artist"] as! String
                let artist: Artist = {() -> Artist in
                    let artistCheck = checkIfArtistExists(artistName)
                    if artistCheck == nil {
                        let artist = NSEntityDescription.insertNewObjectForEntityForName("Artist", inManagedObjectContext: managedContext) as! Artist
                        addedArtist = artist
                        artist.name = artistName
                        artist.id = library?.next_artist_id
                        library?.next_artist_id = Int(library!.next_artist_id!) + 1
                        return artist
                    } else {
                        artistCheck?.is_network = nil
                        return artistCheck!
                    }
                }()
                newTrack.artist = artist
                newTrackView.artist_order = trackMetadata["artist_order"] as? Int
            case "album":
                let albumName = trackMetadata["album"] as! String
                let album: Album = {
                    let albumCheck = checkIfAlbumExists(albumName)
                    if albumCheck == nil {
                        let album = NSEntityDescription.insertNewObjectForEntityForName("Album", inManagedObjectContext: managedContext) as! Album
                        addedAlbum = album
                        album.name = albumName
                        album.id = library?.next_album_id
                        library?.next_album_id = Int(library!.next_album_id!) + 1
                        return album
                    } else {
                        albumCheck?.is_network = nil
                        return albumCheck!
                    }
                }()
                newTrack.album = album
                newTrackView.album_order = trackMetadata["album_order"] as? Int
            case "date_added":
                newTrack.date_added = NSDate()
            case "date_modified":
                newTrack.date_modified = dateFormatter.dateFromString(trackMetadata["date_modified"] as! String)
            case "date_released":
                newTrack.album?.release_date = dateFormatter.dateFromString(trackMetadata["date_released"] as! String)
                newTrackView.release_date_order = trackMetadata["release_date_order"] as? Int
            case "comments":
                newTrack.comments = trackMetadata["comments"] as? String
            case "composer":
                let composerName = trackMetadata["composer"] as! String
                let composer: Composer = {
                    let composerCheck = checkIfComposerExists(composerName)
                    if composerCheck == nil {
                        let composer = NSEntityDescription.insertNewObjectForEntityForName("Composer", inManagedObjectContext: managedContext) as! Composer
                        addedComposer = composer
                        composer.name = composerName
                        composer.id = library?.next_composer_id
                        library?.next_composer_id = Int(library!.next_composer_id!) + 1
                        return composer
                    } else {
                        composerCheck?.is_network = nil
                        return composerCheck!
                    }
                }()
                newTrack.composer = composer
            case "disc_number":
                newTrack.disc_number = trackMetadata["disc_number"] as? Int
            case "genre":
                let genreName = trackMetadata["genre"] as! String
                let genre: Genre = {
                    let genreCheck = checkIfGenreExists(genreName)
                    if genreCheck == nil {
                        let genre = NSEntityDescription.insertNewObjectForEntityForName("Genre", inManagedObjectContext: managedContext) as! Genre
                        addedGenre = genre
                        genre.name = genreName
                        genre.id = library?.next_genre_id
                        library?.next_genre_id = Int(library!.next_genre_id!) + 1
                        return genre
                    } else {
                        genreCheck?.is_network = nil
                        return genreCheck!
                    }
                }()
                newTrack.genre = genre
                newTrackView.genre_order = trackMetadata["genre_order"] as? Int
            case "file_kind":
                newTrack.file_kind = trackMetadata["file_kind"] as? String
                newTrackView.kind_order = trackMetadata["kind_order"] as? Int
            case "date_last_played":
                newTrack.date_last_played = dateFormatter.dateFromString(trackMetadata["date_last_played"] as! String)
            case "date_last_skipped":
                newTrack.date_last_skipped = dateFormatter.dateFromString(trackMetadata["date_last_skipped"] as! String)
            case "movement_name":
                newTrack.movement_name = trackMetadata["movement_name"] as? String
            case "movement_number":
                newTrack.movement_number = trackMetadata["movement_number"] as? Int
            case "play_count":
                newTrack.play_count = trackMetadata["play_count"] as? Int
            case "rating":
                newTrack.rating = trackMetadata["rating"] as? Int
            case "bit_rate":
                newTrack.bit_rate = trackMetadata["bit_rate"] as? Int
            case "sample_rate":
                newTrack.sample_rate = trackMetadata["sample_rate"] as? Int
            case "size":
                newTrack.size = trackMetadata["size"] as? Int
            case "skip_count":
                newTrack.skip_count = trackMetadata["skip_count"] as? Int
            case "sort_album":
                newTrack.sort_album = trackMetadata["sort_album"] as? String
            case "sort_album_artist":
                newTrack.sort_album_artist = trackMetadata["sort_album_artist"] as? String
                newTrackView.album_artist_order = trackMetadata["album_artist_order"] as? Int
            case "sort_artist":
                newTrack.sort_artist = trackMetadata["sort_artist"] as? String
            case "sort_composer":
                newTrack.sort_composer = trackMetadata["sort_composer"] as? String
            case "sort_name":
                newTrack.sort_name = trackMetadata["sort_name"] as? String
            case "track_num":
                newTrack.track_num = trackMetadata["track_num"] as? Int
            case "location":
                newTrack.location = trackMetadata["location"] as? String
            case "album_artist":
                let artistName = trackMetadata["album_artist"] as! String
                let artist: Artist = {
                    let artistCheck = checkIfArtistExists(artistName)
                    if artistCheck == nil {
                        let artist = NSEntityDescription.insertNewObjectForEntityForName("Artist", inManagedObjectContext: managedContext) as! Artist
                        addedAlbumArtist = artist
                        artist.name = artistName
                        return artist
                    } else {
                        artistCheck?.is_network = nil
                        return artistCheck!
                    }
                }()
                newTrack.album?.album_artist = artist
            default:
                break
            }
        }
        if moveFileForNetworkTrackToAppropriateLocationWithData(newTrack, data: data) == true {
            for order in cachedOrders! {
                reorderForTracks([newTrack], cachedOrder: order)
            }
        } else {
            managedContext.deleteObject(newTrack)
            managedContext.deleteObject(newTrackView)
            if addedArtist != nil {
                managedContext.deleteObject(addedArtist!)
            }
            if addedGenre != nil {
                managedContext.deleteObject(addedGenre!)
            }
            if addedComposer != nil {
                managedContext.deleteObject(addedComposer!)
            }
            if addedAlbum != nil {
                managedContext.deleteObject(addedAlbum!)
            }
            if addedAlbumArtist != nil {
                managedContext.deleteObject(addedAlbumArtist!)
            }
        }
        return true
    }
    
    func trackDoesNotExist(track: NSDictionary) -> Bool {
        let trackFetch = NSFetchRequest(entityName: "Track")
        let id = track["id"] as! Int
        let trackPredicate = NSPredicate(format: "id == \(id)")
        trackFetch.predicate = trackPredicate
        do {
            let results = try managedContext.executeFetchRequest(trackFetch) as! [Track]
            if results.count > 0 {
                if results[0].location == track["location"] as? String {
                    return false
                }
            } else {
                return true
            }
        } catch {
            print(error)
        }
        return true
    }
    
    func saveStreamingNetworkTrack(track: Track, data: NSData) {
        let fileName = {() -> String in
            switch NSUserDefaults.standardUserDefaults().boolForKey(DEFAULTS_RENAMES_FILES_STRING) {
            case true:
                return self.formFilenameForTrack(track)
            default:
                return NSURL(string: track.location!)!.lastPathComponent!
            }
        }()
        var albumDirectoryURL: NSURL?
        var fileURL: NSURL?
        let libraryPathURL = NSURL(fileURLWithPath: NSUserDefaults.standardUserDefaults().objectForKey(DEFAULTS_LIBRARY_PATH_STRING) as! String)
        let albumArtist = track.album?.album_artist?.name != nil ? track.album!.album_artist!.name! : track.artist?.name != nil ? track.artist!.name! : UNKNOWN_ARTIST_STRING
        let album = track.album?.name != nil ? track.album!.name! : UNKNOWN_ALBUM_STRING
        albumDirectoryURL = libraryPathURL.URLByAppendingPathComponent("tmp").URLByAppendingPathComponent(albumArtist).URLByAppendingPathComponent(album)
        do {
            try fileManager.createDirectoryAtURL(albumDirectoryURL!, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("error creating album directory: \(error)")
        }
        do {
            fileURL = albumDirectoryURL?.URLByAppendingPathComponent(fileName)
            try data.writeToURL(fileURL!, options: NSDataWritingOptions.DataWritingAtomic)
            track.location = fileURL?.absoluteString
        } catch {
            print("error while moving/copying files: \(error)")
        }
    }

    func addTracksForPlaylistData(playlistDictionary: NSDictionary, item: SourceListItem) {
        let library = {() -> Library? in
            let fetchReq = NSFetchRequest(entityName: "Library")
            let predicate = NSPredicate(format: "is_network == nil OR is_network == false")
            fetchReq.predicate = predicate
            do {
                let result = try managedContext.executeFetchRequest(fetchReq)[0] as! Library
                return result
            } catch {
                return nil
            }
        }()
        //get tracks
        let tracks = playlistDictionary["playlist"] as! [NSDictionary]
        let addedArtists = NSMutableDictionary()
        let addedAlbums = NSMutableDictionary()
        let addedComposers = NSMutableDictionary()
        let addedGenres = NSMutableDictionary()
        let addedTracks = NSMutableDictionary()
        var addedTrackViews = [TrackView]()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        for track in tracks {
            guard trackDoesNotExist(track) else {continue}
            let newTrack = NSEntityDescription.insertNewObjectForEntityForName("Track", inManagedObjectContext: managedContext) as! Track
            let newTrackView = NSEntityDescription.insertNewObjectForEntityForName("TrackView", inManagedObjectContext: managedContext) as! TrackView
            newTrackView.is_network = true
            newTrackView.track = newTrack
            newTrack.is_network = true
            newTrack.is_playing = false
            for field in track.allKeys as! [String] {
                let trackArtist: Artist
                switch field {
                case "id":
                    let id = track["id"] as! Int
                    newTrack.id = track["id"] as? Int
                    addedTracks[id] = newTrack
                case "is_enabled":
                    newTrack.status = track["is_enabled"] as? Bool
                case "name":
                    newTrack.name = track["name"] as? String
                    newTrackView.name_order = track["name_order"] as? Int
                case "time":
                    newTrack.time = track["time"] as? NSNumber
                case "artist":
                    let artistName = track["artist"] as! String
                    let artist: Artist = {
                        if addedArtists[artistName] != nil {
                            return addedArtists[artistName] as! Artist
                        } else {
                            let artistCheck = checkIfArtistExists(artistName)
                            if artistCheck == nil {
                                let artist = NSEntityDescription.insertNewObjectForEntityForName("Artist", inManagedObjectContext: managedContext) as! Artist
                                artist.name = artistName
                                artist.id = library?.next_artist_id
                                library?.next_artist_id = Int(library!.next_artist_id!) + 1
                                artist.is_network = true
                                addedArtists[artistName] = artist
                                return artist
                            } else {
                                return artistCheck!
                            }
                        }
                    }()
                    newTrack.artist = artist
                    newTrackView.artist_order = track["artist_order"] as? Int
                    trackArtist = artist
                case "album":
                    let albumName = track["album"] as! String
                    let album: Album = {
                        if addedAlbums[albumName] != nil {
                            return addedAlbums[albumName] as! Album
                        } else {
                            let albumCheck = checkIfAlbumExists(albumName)
                            if albumCheck == nil {
                                let album = NSEntityDescription.insertNewObjectForEntityForName("Album", inManagedObjectContext: managedContext) as! Album
                                album.name = albumName
                                album.id = library?.next_album_id
                                library?.next_album_id = Int(library!.next_album_id!) + 1
                                album.is_network = true
                                addedAlbums[albumName] = album
                                return album
                            } else {
                                return albumCheck!
                            }
                        }
                    }()
                    newTrack.album = album
                    newTrackView.album_order = track["album_order"] as? Int
                case "date_added":
                    newTrack.date_added = dateFormatter.dateFromString(track["date_added"] as! String)
                    newTrackView.date_added_order = track["date_added_order"] as? Int
                case "date_modified":
                    newTrack.date_modified = dateFormatter.dateFromString(track["date_modified"] as! String)
                case "date_released":
                    newTrack.album?.release_date = dateFormatter.dateFromString(track["date_released"] as! String)
                    newTrackView.release_date_order = track["release_date_order"] as? Int
                case "comments":
                    newTrack.comments = track["comments"] as? String
                case "composer":
                    let composerName = track["composer"] as! String
                    let composer: Composer = {
                        if addedComposers[composerName] != nil {
                            return addedComposers[composerName] as! Composer
                        } else {
                            let composerCheck = checkIfComposerExists(composerName)
                            if composerCheck == nil {
                                let composer = NSEntityDescription.insertNewObjectForEntityForName("Composer", inManagedObjectContext: managedContext) as! Composer
                                composer.name = composerName
                                composer.id = library?.next_composer_id
                                library?.next_composer_id = Int(library!.next_composer_id!) + 1
                                composer.is_network = true
                                addedComposers[composerName] = composer
                                return composer
                            } else {
                                return composerCheck!
                            }
                        }
                    }()
                    newTrack.composer = composer
                case "disc_number":
                    newTrack.disc_number = track["disc_number"] as? Int
                case "equalizer_preset":
                    newTrack.equalizer_preset = track["equalizer_preset"] as? String
                case "genre":
                    let genreName = track["genre"] as! String
                    let genre: Genre = {
                        if addedComposers[genreName] != nil {
                            return addedGenres[genreName] as! Genre
                        } else {
                            let genreCheck = checkIfGenreExists(genreName)
                            if genreCheck == nil {
                                let genre = NSEntityDescription.insertNewObjectForEntityForName("Genre", inManagedObjectContext: managedContext) as! Genre
                                genre.name = genreName
                                genre.id = library?.next_genre_id
                                library?.next_genre_id = Int(library!.next_genre_id!) + 1
                                genre.is_network = true
                                addedGenres[genreName] = genre
                                return genre
                            } else {
                                return genreCheck!
                            }
                        }
                    }()
                    newTrack.genre = genre
                    newTrackView.genre_order = track["genre_order"] as? Int
                case "file_kind":
                    newTrack.file_kind = track["file_kind"] as? String
                    newTrackView.kind_order = track["kind_order"] as? Int
                case "date_last_played":
                    newTrack.date_last_played = dateFormatter.dateFromString(track["date_last_played"] as! String)
                case "date_last_skipped":
                    newTrack.date_last_skipped = dateFormatter.dateFromString(track["date_last_skipped"] as! String)
                case "movement_name":
                    newTrack.movement_name = track["movement_name"] as? String
                case "movement_number":
                    newTrack.movement_number = track["movement_number"] as? Int
                case "play_count":
                    newTrack.play_count = track["play_count"] as? Int
                case "rating":
                    newTrack.rating = track["rating"] as? Int
                case "bit_rate":
                    newTrack.bit_rate = track["bit_rate"] as? Int
                case "sample_rate":
                    newTrack.sample_rate = track["sample_rate"] as? Int
                case "size":
                    newTrack.size = track["size"] as? Int
                case "skip_count":
                    newTrack.skip_count = track["skip_count"] as? Int
                case "sort_album":
                    newTrack.sort_album = track["sort_album"] as? String
                case "sort_album_artist":
                    newTrack.sort_album_artist = track["sort_album_artist"] as? String
                    newTrackView.album_artist_order = track["album_artist_order"] as? Int
                case "sort_artist":
                    newTrack.sort_artist = track["sort_artist"] as? String
                case "sort_composer":
                    newTrack.sort_composer = track["sort_composer"] as? String
                case "sort_name":
                    newTrack.sort_name = track["sort_name"] as? String
                case "track_num":
                    newTrack.track_num = track["track_num"] as? Int
                case "location":
                    newTrack.location = track["location"] as? String
                case "album_artist":
                    let artistName = track["album_artist"] as! String
                    let artist: Artist = {
                        if addedArtists[artistName] != nil {
                            return addedArtists[artistName] as! Artist
                        } else {
                            let artistCheck = checkIfArtistExists(artistName)
                            if artistCheck == nil {
                                let artist = NSEntityDescription.insertNewObjectForEntityForName("Artist", inManagedObjectContext: managedContext) as! Artist
                                artist.name = artistName
                                artist.is_network = true
                                addedArtists[artistName] = artist
                                return artist
                            } else {
                                return artistCheck!
                            }
                        }
                    }()
                    newTrack.album?.album_artist = artist
                default:
                    break
                }
            }
            addedTrackViews.append(newTrackView)
        }
        let track_id_list = addedTrackViews.map({return Int($0.track!.id!)})
        item.playlist?.track_id_list = track_id_list
    }
}
