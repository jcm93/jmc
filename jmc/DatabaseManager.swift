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

func instanceCheck(_ entity: String, name: String) -> NSManagedObject? {
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.shared().delegate
            as? AppDelegate)?.managedObjectContext }()!
    let fetch_req = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
    let predicate = NSPredicate(format: "name == %@", name)
    fetch_req.predicate = predicate
    var results: [NSManagedObject]?
    do {
        results = try managedContext.fetch(fetch_req) as! [NSManagedObject]
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

func getArt(_ name: String) -> AlbumArtworkCollection? {
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.shared().delegate
            as? AppDelegate)?.managedObjectContext }()!
    let fetch_req = NSFetchRequest<NSFetchRequestResult>(entityName: "AlbumArtworkCollection")
    let predicate = NSPredicate(format: "album.name == %@", name)
    fetch_req.predicate = predicate
    var results: [AlbumArtworkCollection]
    do {
        results = try managedContext.fetch(fetch_req) as! [AlbumArtworkCollection]
        return results[0]
    } catch {
        print("err: \(error)")
        return nil
    }
}

class FileAddToDatabaseError: NSObject {
    var urlString: String
    var error: String
    init(url: String, error: String) {
        self.urlString = url
        self.error = error
    }
}

class DatabaseManager: NSObject {
    
    var organizesMedia: Bool = true
    let fileManager = FileManager.default
    var undoFileLocations = [Track : [String]]()
    
    func getArtworkFromFile(_ urlString: String) -> Data? {
        print("checking for art in file")
        let url = URL(string: urlString)
        let mediaObject = AVAsset(url: url!)
        var art: Data?
        let commonMeta = mediaObject.commonMetadata
        for metadataItem in commonMeta {
            if metadataItem.commonKey == "artwork" {
                print("found art in file")
                art = metadataItem.value as? Data
            }
        }
        if art != nil {
            return art
        }
        else {
            return nil
        }
    }
    
    func searchAlbumDirectoryForArt(_ track: Track) -> URL? {
        let locationURL = URL(string: track.location!)
        let albumDirectoryURL = locationURL!.deletingLastPathComponent()
        do {
            let albumDirectoryContents = try fileManager.contentsOfDirectory(at: albumDirectoryURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            let potentialImages = albumDirectoryContents.filter({VALID_ARTWORK_TYPE_EXTENSIONS.contains($0.pathExtension.lowercased())})
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
    
    func undoOperationThatMovedFiles(for tracks: [Track]) {
        print("undoing a move operation")
        for track in tracks {
            let currentFileLocation = self.undoFileLocations[track]!.removeLast()
            do {
                try fileManager.moveItem(at: URL(string: currentFileLocation)!, to: URL(string: track.location!)!)
            } catch {
                print("error undoing move \(error)")
            }
        }
    }
    
    func addPrimaryArtForTrack(_ track: Track, art: Data, managedContext: NSManagedObjectContext) -> Track? {
        print("adding new primary album art")
        let artHash = art.hashValue
        if let currentPrimaryHash = track.album?.primary_art?.image_hash {
            if Int(currentPrimaryHash) == artHash {
                print("artwork collision")
                return nil
            }
        }
        guard let artImage = CGImageSourceCreateWithData(art as CFData, nil) else {return nil}
        guard let artUTI = CGImageSourceGetType(artImage) else {return nil}
        guard let artExtension = getImageExtension(artUTI) else {return nil}
        let newArtwork = NSEntityDescription.insertNewObject(forEntityName: "AlbumArtwork", into: managedContext) as! AlbumArtwork
        newArtwork.image_hash = artHash as NSNumber?
        if track.album?.primary_art != nil {
            let contains: Bool = {
                if track.album?.primary_art?.image_hash == (artHash as NSNumber) {
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
                        if (album as! AlbumArtwork).image_hash == (artHash as NSNumber) {
                            return true
                        }
                    }
                    return false
                }()
                guard contains != true else {return track}
                track.album!.other_art!.addArtObject(track.album!.primary_art!)
            }
            else if track.album!.other_art == nil {
                let newArtworkCollection = NSEntityDescription.insertNewObject(forEntityName: "AlbumArtworkCollection", into: managedContext) as! AlbumArtworkCollection
                newArtworkCollection.album = track.album!
                newArtworkCollection.addArtObject(track.album!.primary_art!)
            }
        }
        let artURL = NSURL(string: track.location!)?.deletingLastPathComponent?.appendingPathComponent("\(artHash)").appendingPathExtension(artExtension)
        newArtwork.artwork_location = artURL!.absoluteString
        track.album?.primary_art = newArtwork
        do {
            try art.write(to: artURL!, options: NSData.WritingOptions.atomic)
        } catch {
            print("error writing file: \(error)")
        }
        return track
    }
    
    //OK -- discrete
    func moveFileAfterEdit(_ track: Track) {
        print("moving file after edit")
        print("current track location: \(track.location)")
        let organizationType = track.library?.organization_type as! Int
        guard organizationType != NO_ORGANIZATION_TYPE else {managedContext.processPendingChanges(); managedContext.undoManager?.enableUndoRegistration(); return}
        let artistFolderName = track.album?.album_artist?.name != nil ? track.album!.album_artist!.name! : track.artist?.name != nil ? track.artist!.name! : UNKNOWN_ARTIST_STRING
        let albumFolderName = track.album?.name != nil ? track.album!.name! : UNKNOWN_ALBUM_STRING
        let trackName = validateStringForFilename(formFilenameForTrack(track, url: nil))
        let currentLocationURL = URL(string: track.location!)
        let oldAlbumDirectoryURL = currentLocationURL?.deletingLastPathComponent()
        let newArtistDirectoryURL = ((currentLocationURL as NSURL?)?.deletingLastPathComponent as NSURL?)?.deletingLastPathComponent?.deletingLastPathComponent().appendingPathComponent(artistFolderName)
        let newAlbumDirectoryURL = newArtistDirectoryURL?.appendingPathComponent(albumFolderName)
        let newLocationURL = ((currentLocationURL as NSURL?)?.deletingLastPathComponent as NSURL?)?.deletingLastPathComponent?.deletingLastPathComponent().appendingPathComponent(artistFolderName).appendingPathComponent(albumFolderName).appendingPathComponent(trackName)
        //check if directories already exist
        do {
            try fileManager.createDirectory(at: newAlbumDirectoryURL!, withIntermediateDirectories: true, attributes: nil)
            try fileManager.moveItem(at: currentLocationURL!, to: newLocationURL!)
            track.location = newLocationURL?.absoluteString
        } catch {
            print("error moving file: \(error)")
        }
        do {
            let currentAlbumDirectoryContents = try fileManager.contentsOfDirectory(at: oldAlbumDirectoryURL!, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            if currentAlbumDirectoryContents.count == 1 {
                let lastFileURL = currentAlbumDirectoryContents[0]
                let ext = lastFileURL.pathExtension.lowercased()
                if VALID_ARTWORK_TYPE_EXTENSIONS.contains(ext) {
                    let fileName = lastFileURL.lastPathComponent
                    try fileManager.moveItem(at: lastFileURL, to: (newLocationURL?.deletingLastPathComponent().appendingPathComponent(fileName))!)
                }
            }
        } catch {
            print("error checking directory: \(error)")
        }
        print("moved \(currentLocationURL) to \(track.location!)")
        if self.undoFileLocations[track] == nil {
            self.undoFileLocations[track] = [String]()
        }
        self.undoFileLocations[track]!.append(track.location!)
    }
    
    func getMDItemFromURL(_ url: URL) -> MDItem? {
        let item = MDItemCreateWithURL(kCFAllocatorDefault, url as CFURL!)
        return item
    }
    
    func addSortValues(_ track: Track) {
        track.sort_name = getSortName(track.name)
        track.sort_artist = getSortName(track.artist?.name)
        track.sort_album = getSortName(track.album?.name)
        track.sort_album_artist = getSortName(track.album?.album_artist?.name)
        track.sort_composer = getSortName(track.composer?.name)
    }
    
    func handleDirectoryEnumerationError(_ url: URL, error: Error) -> Bool {
        print("directory enumeration error: \(error)")
        print("this is bad! returning true anyway")
        return true
    }
    
    func getMediaURLsInDirectoryURLs(_ urls: [URL]) -> ([URL],[FileAddToDatabaseError]) {
        var mediaURLs = [URL]()
        var errors = [FileAddToDatabaseError]()
        for url in urls {
            var isDirectory = ObjCBool(true)
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles, errorHandler: self.handleDirectoryEnumerationError)
                    for fileURLElement in enumerator! {
                        let fileURL = fileURLElement as! URL
                        if fileURL.pathExtension != "" && VALID_FILE_TYPES.contains(fileURL.pathExtension.lowercased()) {
                            mediaURLs.append(fileURL)
                        } else {
                            let error = FileAddToDatabaseError(url: fileURL.absoluteString, error: "invalid file type")
                            errors.append(error)
                        }
                    }
                } else {
                    if url.pathExtension != "" && VALID_FILE_TYPES.contains(url.pathExtension.lowercased()) {
                        mediaURLs.append(url)
                    }
                }
            }
        }
        return (mediaURLs, errors)
    }
    
    func createNewSource(url: URL) {
        let library = NSEntityDescription.insertNewObject(forEntityName: "Library", into: managedContext) as! Library
        library.volume_url_string = url.absoluteString
        library.name = url.lastPathComponent
        library.parent = globalRootLibrary
        library.is_active = true
        let librarySourceListItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        librarySourceListItem.library = library
        librarySourceListItem.name = library.name
        globalRootLibrarySourceListItem!.addToChildren(librarySourceListItem)
    }
    
    func addNewSource(url: URL, organize: Bool, visualUpdateHandler: ProgressBarController?) {
        let library = NSEntityDescription.insertNewObject(forEntityName: "Library", into: managedContext) as! Library
        library.volume_url_string = url.absoluteString
        library.name = url.lastPathComponent
        library.parent = globalRootLibrary
        library.is_active = true
        library.renames_files = organize as NSNumber
        library.organization_type = organize == true ? 2 as NSNumber : 0 as NSNumber
        library.keeps_track_of_files = true
        var urlArray = library.watch_dirs as? [URL] ?? [URL]()
        urlArray.append(url)
        library.watch_dirs = urlArray as NSArray
        library.monitors_directories_for_new = true
        let librarySourceListItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        librarySourceListItem.library = library
        librarySourceListItem.name = library.name
        globalRootLibrarySourceListItem!.addToChildren(librarySourceListItem)
        visualUpdateHandler?.makeIndeterminate(actionName: "Getting all media in directory")
        let mediaURLs = getMediaURLsInDirectoryURLs([url]).0
        DispatchQueue.global(qos: .default).async {
            self.addTracksFromURLs(mediaURLs, to: library, visualUpdateHandler: visualUpdateHandler, callback: nil)
        }
    }
    
    func removeNetworkedLibrary(_ library: Library) {
        removeSource(library: library)
    }
    
    func removeSource(library: Library) {
        guard library != globalRootLibrary else {return}
        for track in (library.tracks! as! Set<Track>) {
            managedContext.delete(track.view!)
            if track.artist?.tracks?.count != nil && track.artist!.tracks!.count <= 1 {
                managedContext.delete(track.artist!)
            }
            if track.album?.tracks?.count != nil && track.album!.tracks!.count <= 1 {
                managedContext.delete(track.album!)
            }
            managedContext.delete(track)
        }
        if library.local_items != nil {
            for item in library.local_items! {
                managedContext.delete(item as! NSManagedObject)
            }
        }
        managedContext.delete(library)
        do {
            try managedContext.save()
        } catch {
            print(error)
        }
    }
    
    func getAudioMetadata(url: URL) -> [String : Any]? {
        //get the bit rate, sample rate, duration, important id3/vorbis metadata
        var metadataDictionary = [String : Any]()
        guard let mediaFileObject = getMDItemFromURL(url) else {return nil}
        
        //format-agnostic metadata
        metadataDictionary[kDateModifiedKey] = MDItemCopyAttribute(mediaFileObject, "kMDItemContentModificationDate" as CFString!) as? Date
        metadataDictionary[kFileKindKey]     = MDItemCopyAttribute(mediaFileObject, "kMDItemKind" as CFString!) as? String
        guard let size                       = MDItemCopyAttribute(mediaFileObject, "kMDItemFSSize" as CFString!) as? Int else {
                print(MDItemCopyAttribute(mediaFileObject, "kMDItemFSSize" as CFString!))
                print("doingluskhrejwk")
                return nil
        }
        metadataDictionary[kSizeKey]         = size as NSNumber?
        
        if url.pathExtension.lowercased() == "flac" {
            
            let flacReader = FlacDecoder(file: url, audioModule: nil)
            flacReader!.initForMetadata()
            
            metadataDictionary[kSampleRateKey]  = flacReader?.metadataDictionary[kSampleRateKey]
            let duration_seconds                = Double(flacReader!.totalFrames) / Double(flacReader!.sampleRate!)
            let bitRate                         = ((Double(metadataDictionary[kSizeKey] as! Int) * 8) / 1000) / duration_seconds
            metadataDictionary[kBitRateKey]     = bitRate
            metadataDictionary[kTimeKey]        = duration_seconds * 1000
            
            //format-sensitive metadata
            for item in flacReader!.metadataDictionary {
                switch item.key {
                case "ARTIST":
                    metadataDictionary[kArtistKey]          = item.value
                case "ALBUM":
                    metadataDictionary[kAlbumKey]           = item.value
                case "COMPOSER":
                    metadataDictionary[kComposerKey]        = item.value
                case "DATE":
                    metadataDictionary[kReleaseDateKey]     = item.value
                case "DESCRIPTION":
                    metadataDictionary[kCommentsKey]        = item.value
                case "GENRE":
                    metadataDictionary[kGenreKey]           = item.value
                case "RELEASE DATE":
                    metadataDictionary[kReleaseDateKey]     = item.value
                case "TITLE":
                    metadataDictionary[kNameKey]            = item.value
                case "TRACKNUMBER":
                    metadataDictionary[kTrackNumKey]        = item.value
                case "COMPILATION":
                    metadataDictionary[kIsCompilationKey]   = item.value
                case "COMMENT":
                    metadataDictionary[kCommentsKey]        = item.value
                case "TOTALTRACKS":
                    metadataDictionary[kTotalTracksKey]     = item.value
                case "DISCNUMBER":
                    metadataDictionary[kDiscNumberKey]      = item.value
                case "ALBUMARTIST":
                    metadataDictionary[kAlbumArtistKey]     = item.value
                default: break
                }
            }
        } else {
            metadataDictionary[kSampleRateKey]  = MDItemCopyAttribute(mediaFileObject, "kMDItemAudioSampleRate" as CFString) as? Int as NSNumber?
            metadataDictionary[kBitRateKey]     = (MDItemCopyAttribute(mediaFileObject, "kMDItemAudioBitRate" as CFString!) as! Double) / 1000
            metadataDictionary[kTimeKey]        = (MDItemCopyAttribute(mediaFileObject, "kMDItemDurationSeconds" as CFString!) as! Double) * 1000
            metadataDictionary[kTrackNumKey]    = MDItemCopyAttribute(mediaFileObject, "kMDItemAudioTrackNumber" as CFString!) as? Int as NSNumber?
            metadataDictionary[kGenreKey]       = MDItemCopyAttribute(mediaFileObject, "kMDItemMusicalGenre" as CFString!) as? String
            metadataDictionary[kNameKey]        = MDItemCopyAttribute(mediaFileObject, "kMDItemTitle" as CFString!) as? String
            metadataDictionary[kAlbumKey]       = MDItemCopyAttribute(mediaFileObject, "kMDItemAlbum" as CFString!) as? String
            metadataDictionary[kArtistKey]      = (MDItemCopyAttribute(mediaFileObject, "kMDItemAuthors" as CFString!) as? [String])?[0]
            metadataDictionary[kComposerKey]    = MDItemCopyAttribute(mediaFileObject, "kMDItemComposer" as CFString!) as? String
        }
        
        //other stuff?
        return metadataDictionary
    }
    
    func addTracksFromURLs(_ mediaURLs: [URL], to library: Library, visualUpdateHandler: ProgressBarController?, callback: (() -> Void)?) -> [FileAddToDatabaseError] {
        let subContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        subContext.parent = managedContext
        let subContextLibrary = subContext.object(with: library.objectID)
        var errors = [FileAddToDatabaseError]()
        var addedArtists = [String: Artist]()
        var addedAlbums = [String: Album]()
        var addedComposers = [String: Composer]()
        var tracks = [Track]()
        var index = 0
        DispatchQueue.main.async {
            visualUpdateHandler?.prepareForNewTask(actionName: "Importing", thingName: "tracks", thingCount: mediaURLs.count)
        }
        for url in mediaURLs {
            guard let fileMetadataDictionary = getAudioMetadata(url: url) else {
                print("failure getting audio metadata, error")
                errors.append(FileAddToDatabaseError(url: url.absoluteString, error: kFileAddErrorMetadataNotYetPopulated)); continue
            }
            var addedArtist: Artist?
            var addedAlbum: Album?
            var addedComposer: Composer?
            var addedAlbumArtist: Artist?
            
            //create track and track view objects
            let track = NSEntityDescription.insertNewObject(forEntityName: "Track", into: subContext) as! Track
            let trackView = NSEntityDescription.insertNewObject(forEntityName: "TrackView", into: subContext) as! TrackView
            trackView.track = track
            track.location = url.absoluteString
            track.date_added = Date() as NSDate
            track.id = globalRootLibrary?.next_track_id
            globalRootLibrary?.next_track_id = Int(globalRootLibrary!.next_track_id!) + 1 as NSNumber
            track.status = 0
            
            //associate track with library
            track.library = subContextLibrary as! Library
            
            //populate metadata from getAudioMetadata
            track.bit_rate      = fileMetadataDictionary[kBitRateKey] as? NSNumber
            track.disc_number   = fileMetadataDictionary[kDiscNumberKey] as? NSNumber
            track.sample_rate   = fileMetadataDictionary[kSampleRateKey] as? NSNumber
            track.date_modified = fileMetadataDictionary[kDateModifiedKey] as? NSDate
            track.file_kind     = fileMetadataDictionary[kFileKindKey] as? String
            track.time          = fileMetadataDictionary[kTimeKey] as! Double as NSNumber
            track.size          = fileMetadataDictionary[kSizeKey] as! Int as NSNumber
            track.track_num     = fileMetadataDictionary[kTrackNumKey] as? NSNumber
            track.genre         = fileMetadataDictionary[kGenreKey] as? String
            if let name         = fileMetadataDictionary[kNameKey] as? String {
                track.name = name
            } else {
                track.name = url.deletingPathExtension().lastPathComponent
            }
            
            //populate artist, album, composer
            if let albumCheck = fileMetadataDictionary[kAlbumKey] as? String {
                if let alreadyAddedAlbum = addedAlbums[albumCheck] {
                    track.album = alreadyAddedAlbum
                } else if let alreadyAddedAlbum = checkIfAlbumExists(albumCheck) {
                    track.album = subContext.object(with: alreadyAddedAlbum.objectID) as! Album
                } else {
                    let newAlbum = NSEntityDescription.insertNewObject(forEntityName: "Album", into: subContext) as! Album
                    newAlbum.name = albumCheck
                    newAlbum.id = globalRootLibrary?.next_album_id
                    globalRootLibrary?.next_album_id = Int(globalRootLibrary!.next_album_id!) + 1 as NSNumber
                    track.album = newAlbum
                    addedAlbums[albumCheck] = newAlbum
                    addedAlbum = newAlbum
                }
            }
            if let artistCheck = fileMetadataDictionary[kArtistKey] as? String {
                if let alreadyAddedArtist = addedArtists[artistCheck] {
                    track.artist = alreadyAddedArtist
                } else if let alreadyAddedArtist = checkIfArtistExists(artistCheck) {
                    track.artist = subContext.object(with: alreadyAddedArtist.objectID) as! Artist
                } else {
                    let newArtist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: subContext) as! Artist
                    newArtist.name = artistCheck
                    newArtist.id = globalRootLibrary?.next_artist_id
                    globalRootLibrary?.next_artist_id = Int(globalRootLibrary!.next_artist_id!) + 1 as NSNumber
                    track.artist = newArtist
                    addedArtists[artistCheck] = newArtist
                    addedArtist = newArtist
                }
            }
            if let composerCheck = fileMetadataDictionary[kComposerKey] as? String {
                if let alreadyAddedComposer = addedComposers[composerCheck] {
                    track.composer = alreadyAddedComposer
                } else if let alreadyAddedComposer = checkIfComposerExists(composerCheck) {
                    track.composer = subContext.object(with: alreadyAddedComposer.objectID) as! Composer
                }  else {
                    let newComposer = NSEntityDescription.insertNewObject(forEntityName: "Composer", into: subContext) as! Composer
                    newComposer.name = composerCheck
                    newComposer.id = globalRootLibrary?.next_composer_id
                    globalRootLibrary?.next_composer_id = Int(globalRootLibrary!.next_composer_id!) + 1 as NSNumber
                    track.composer = newComposer
                    addedComposers[composerCheck] = newComposer
                    addedComposer = newComposer
                }
            }
            //handle album artist
            if let albumArtistName = fileMetadataDictionary[kAlbumArtistKey] as? String {
                if let alreadyAddedArtist = addedArtists[albumArtistName] {
                    track.album?.album_artist = alreadyAddedArtist
                } else if let alreadyAddedArtist = checkIfArtistExists(albumArtistName) {
                    track.album?.album_artist = subContext.object(with: alreadyAddedArtist.objectID) as! Artist
                } else {
                    let newArtist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: subContext) as! Artist
                    newArtist.name = albumArtistName
                    newArtist.id = globalRootLibrary?.next_artist_id
                    globalRootLibrary?.next_artist_id = Int(globalRootLibrary!.next_artist_id!) + 1 as NSNumber
                    track.album?.album_artist = newArtist
                    addedArtists[albumArtistName] = newArtist
                    addedAlbumArtist = newArtist
                }
            }
            
            if fileMetadataDictionary[kIsCompilationKey] as? Int == 1 {
                track.album?.is_compilation = true as NSNumber
            }
            
            //add sort values
            addSortValues(track)
            
            //deal with artwork
            var art: Data?
            var hasArt = false
            autoreleasepool {
                if UserDefaults.standard.bool(forKey: DEFAULTS_CHECK_EMBEDDED_ARTWORK_STRING) {
                    var otherMetadataForAlbumArt = AVAsset(url: url).commonMetadata
                    otherMetadataForAlbumArt = otherMetadataForAlbumArt.filter({return $0.commonKey == "artwork"})
                    if otherMetadataForAlbumArt.count > 0 {
                        art = otherMetadataForAlbumArt[0].value as? Data
                        if art != nil {
                            hasArt = true
                        }
                    }
                }
            }
            
            //move file to the appropriate location, if we're organizing
            if moveFileToAppropriateLocationForTrack(track, currentURL: url) != nil {
                if hasArt == true {
                    addPrimaryArtForTrack(track, art: art!, managedContext: subContext)
                }
                tracks.append(track)
            } else {
                print("error moving")
                errors.append(FileAddToDatabaseError(url: url.absoluteString, error: "Couldn't move/copy file to album directory"))
                subContext.delete(track)
                subContext.delete(trackView)
                if addedArtist != nil {
                    subContext.delete(addedArtist!)
                }
                if addedComposer != nil {
                    subContext.delete(addedComposer!)
                }
                if addedAlbum != nil {
                    subContext.delete(addedAlbum!)
                }
            }
            index += 1
            DispatchQueue.main.async {
                visualUpdateHandler?.increment(thingsDone: index)
            }
        }
        
        do {
            try subContext.save()
        } catch {
            print(error)
        }
        
        //insert new tracks to necessary sort caches, on the main queue
        DispatchQueue.main.async {
            //nesting async statements seems only reliable way to make progress bars actually update
            visualUpdateHandler?.makeIndeterminate(actionName: "Repopulating sort cache...")
            DispatchQueue.main.async {
                for order in cachedOrders! {
                    reorderForTracks(tracks, cachedOrder: order.value)
                }
                visualUpdateHandler?.makeIndeterminate(actionName: "Committing changes...")
                DispatchQueue.main.async {
                    do {
                        try managedContext.save()
                    } catch {
                        print(error)
                    }
                    visualUpdateHandler?.finish()
                    if callback != nil {
                        callback!()
                    }
                }
            }
        }
        
        return errors
    }
    
    func removeTracks(_ tracks: [Track]) {
        print("removing tracks")
        for track in tracks {
            print("removing track \(track.name)")
            managedContext.delete(track)
            managedContext.delete(track.view!)
            if track.artist != nil && track.artist!.tracks!.count <= 1 {
                managedContext.delete(track.artist!)
            }
            if track.album != nil && track.album!.tracks!.count <= 1 {
                managedContext.delete(track.album!)
            }
            if track.composer != nil && track.composer!.tracks!.count <= 1 {
                managedContext.delete(track.composer!)
            }
        }
        do {
            try managedContext.save()
        } catch {
            print(error)
        }
    }
    
    func nameEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        managedContext.undoManager!.registerUndo(withTarget: self, selector: #selector(undoOperationThatMovedFiles), object: tracks)
        editName(tracks, name: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order)
        }
        for track in tracks {
            moveFileAfterEdit(track)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Name")
    }
    
    func artistEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        managedContext.undoManager!.registerUndo(withTarget: self, selector: #selector(undoOperationThatMovedFiles), object: tracks)
        editArtist(tracks, artistName: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order)
        }
        for track in tracks {
            moveFileAfterEdit(track)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Artist")
    }
    
    func albumArtistEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        managedContext.undoManager!.registerUndo(withTarget: self, selector: #selector(undoOperationThatMovedFiles), object: tracks)
        editAlbumArtist(tracks, albumArtistName: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order)
        }
        for track in tracks {
            moveFileAfterEdit(track)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Album Artist")
    }
    
    func albumEdited(tracks: [Track], value: String) {
        managedContext.undoManager!.registerUndo(withTarget: self, selector: #selector(undoOperationThatMovedFiles), object: tracks)
        managedContext.undoManager?.beginUndoGrouping()
        editAlbum(tracks, albumName: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order)
        }
        for track in tracks {
            moveFileAfterEdit(track)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Album")
    }
    
    func trackNumEdited(tracks: [Track], value: Int) {
        managedContext.undoManager?.beginUndoGrouping()
        managedContext.undoManager!.registerUndo(withTarget: self, selector: #selector(undoOperationThatMovedFiles), object: tracks)
        editTrackNum(tracks, num: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order)
        }
        for track in tracks {
            moveFileAfterEdit(track)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Track Number")
    }
    
    func trackNumOfEdited(tracks: [Track], value: Int) {
        managedContext.undoManager?.beginUndoGrouping()
        editTrackNumOf(tracks, num: value)
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Total Tracks")
    }
    
    func discNumEdited(tracks: [Track], value: Int) {
        managedContext.undoManager?.beginUndoGrouping()
        managedContext.undoManager!.registerUndo(withTarget: self, selector: #selector(undoOperationThatMovedFiles), object: tracks)
        editDiscNum(tracks, num: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order)
        }
        for track in tracks {
            moveFileAfterEdit(track)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Disc Number")
    }
    
    func totalDiscsEdited(tracks: [Track], value: Int) {
        managedContext.undoManager?.beginUndoGrouping()
        editDiscNumOf(tracks, num: value)
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Total Discs")
    }
    
    func composerEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        editComposer(tracks, composerName: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Composer")
    }
    
    func genreEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        editGenre(tracks, genre: value)
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Genre")
    }
    
    func compilationChanged(tracks: [Track], value: Bool) {
        managedContext.undoManager?.beginUndoGrouping()
        managedContext.undoManager!.registerUndo(withTarget: self, selector: #selector(undoOperationThatMovedFiles), object: tracks)
        editIsComp(tracks, isComp: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order)
        }
        for track in tracks {
            moveFileAfterEdit(track)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Compilation")
    }
    
    func commentsEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        editComments(tracks, comments: value)
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Comments")
    }
    
    func movementNameEdited(tracks: [Track], value: String) {
        //needs work
        managedContext.undoManager?.beginUndoGrouping()
        editMovementName(tracks, name: value)
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Movement Name")
    }
    
    func movementNumEdited(tracks: [Track], value: Int) {
        //needs work
        managedContext.undoManager?.beginUndoGrouping()
        editMovementNum(tracks, num: value)
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Movement Number")
    }
    
    func sortAlbumEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        editSortAlbum(tracks, sortAlbum: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Sort Album")
    }
    
    func sortAlbumArtistEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        editSortAlbumArtist(tracks, sortAlbumArtist: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Sort Album Artist")
    }
    
    func sortArtistEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        editSortArtist(tracks, sortArtist: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Sort Artist")
    }
    
    func sortComposerEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        editSortComposer(tracks, sortComposer: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Sort Composer")
    }
    
    func sortNameEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        editSortName(tracks, sortName: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Sort Name")
    }
    
    
    
    func batchMoveTracks(tracks: [Track], visualUpdateHandler: ProgressBarController?) {
        let subContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        subContext.parent = managedContext
        let subContextTracks = tracks.map({return subContext.object(with: $0.objectID) as! Track})
        DispatchQueue.global(qos: .default).async {
            var index = 0
            for track in subContextTracks {
                self.moveFileToAppropriateLocationForTrack(track, currentURL: URL(string: track.location!)!)
                index += 1
                DispatchQueue.main.async {
                    visualUpdateHandler?.increment(thingsDone: index)
                }
            }
            DispatchQueue.main.async {
                visualUpdateHandler?.makeIndeterminate(actionName: "")
            }
            do {
                try subContext.save()
            } catch {
                print("error saving subcontext")
            }
            DispatchQueue.main.async {
                do {
                    try managedContext.save()
                } catch {
                    print("error saving subcontext")
                }
                visualUpdateHandler?.finish()
            }
        }
    }
    
    func moveFileToAppropriateLocationForTrack(_ track: Track, currentURL: URL) -> URL? {
        let fileName = {() -> String in
            switch track.library?.renames_files as! Bool {
            case true:
                return validateStringForFilename(self.formFilenameForTrack(track, url: currentURL))
            default:
                return currentURL.lastPathComponent
            }
        }()
        var albumDirectoryURL: URL?
        var fileURL: URL?
        let orgType = track.library?.organization_type! as! Int
        if orgType == NO_ORGANIZATION_TYPE {
            track.location = currentURL.deletingLastPathComponent().appendingPathComponent(fileName).absoluteString
            fileURL = currentURL
        } else {
            let libraryPathURL = URL(string: track.library!.central_media_folder_url_string!)
            var album, albumArtist: String
            if track.album?.is_compilation != true {
                albumArtist = validateStringForFilename(track.album?.album_artist?.name != nil ? track.album!.album_artist!.name! : track.artist?.name != nil ? track.artist!.name! : UNKNOWN_ARTIST_STRING)
                album = validateStringForFilename(track.album?.name != nil ? track.album!.name! : UNKNOWN_ALBUM_STRING)
                albumDirectoryURL = libraryPathURL?.appendingPathComponent(albumArtist).appendingPathComponent(album)
            } else {
                album = validateStringForFilename(track.album?.name != nil ? track.album!.name! : UNKNOWN_ALBUM_STRING)
                albumDirectoryURL = libraryPathURL?.appendingPathComponent("Compilations").appendingPathComponent(album)
            }
            do {
                try fileManager.createDirectory(at: albumDirectoryURL!, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("error creating album directory: \(error)")
            }
            do {
                fileURL = albumDirectoryURL?.appendingPathComponent(fileName)
                if currentURL != fileURL {
                    if orgType == MOVE_ORGANIZATION_TYPE {
                        try fileManager.moveItem(at: currentURL, to: fileURL!)
                    } else {
                        try fileManager.copyItem(at: currentURL, to: fileURL!)
                    }
                }
                track.location = fileURL?.absoluteString
            } catch {
                print("error while moving/copying files: \(error)")
                return nil
            }
        }
        return fileURL
    }
    
    func moveFileForNetworkTrackToAppropriateLocationWithData(_ track: Track, data: Data) -> Bool {
        let fileName = {() -> String in
            switch track.library?.renames_files as! Bool {
            case true:
                return self.formFilenameForTrack(track, url: nil)
            default:
                return URL(string: track.location!)!.lastPathComponent
            }
        }()
        var albumDirectoryURL: URL?
        var fileURL: URL?
        let libraryPathURL = URL(fileURLWithPath: track.library!.central_media_folder_url_string!)
        var album, albumArtist: String
        if track.album?.is_compilation != true {
            albumArtist = validateStringForFilename(track.album?.album_artist?.name != nil ? track.album!.album_artist!.name! : track.artist?.name != nil ? track.artist!.name! : UNKNOWN_ARTIST_STRING)
            album = validateStringForFilename(track.album?.name != nil ? track.album!.name! : UNKNOWN_ALBUM_STRING)
            albumDirectoryURL = libraryPathURL.appendingPathComponent(albumArtist).appendingPathComponent(album)
        } else {
            album = validateStringForFilename(track.album?.name != nil ? track.album!.name! : UNKNOWN_ALBUM_STRING)
            albumDirectoryURL = libraryPathURL.appendingPathComponent("Compilations").appendingPathComponent(album)
        }
        do {
            try fileManager.createDirectory(at: albumDirectoryURL!, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("error creating album directory: \(error)")
            return false
        }
        do {
            fileURL = albumDirectoryURL!.appendingPathComponent(fileName)
            try data.write(to: fileURL!, options: NSData.WritingOptions.atomic)
            track.location = fileURL!.absoluteString
        } catch {
            print("error while moving/copying files: \(error)")
            return false
        }
        return true
    }
    
    func formFilenameForTrack(_ track: Track, url: URL?) -> String {
        var discNumberStringRepresentation: String
        if track.disc_number != nil {
            discNumberStringRepresentation = "\(String(describing: track.disc_number!))-"
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
            discNumberStringRepresentation = ""
        }
        let trackNameString = track.name != nil ? track.name! : ""
        let trackExtension = url?.pathExtension ?? URL(string: track.location!)!.pathExtension
        var filenameString = "\(discNumberStringRepresentation)\(trackNumberStringRepresentation) \(trackNameString).\(trackExtension)"
        if filenameString == " " {
            filenameString = NO_FILENAME_STRING
        }
        return filenameString
    }
    
    func createFileForNetworkTrack(_ track: Track, data: Data, trackMetadata: NSDictionary) -> Bool {
        let newTrack = NSEntityDescription.insertNewObject(forEntityName: "Track", into: managedContext) as! Track
        let newTrackView = NSEntityDescription.insertNewObject(forEntityName: "TrackView", into: managedContext) as! TrackView
        newTrackView.track = newTrack
        newTrack.id = globalRootLibrary?.next_track_id
        newTrack.status = nil
        globalRootLibrary?.next_track_id = Int(globalRootLibrary!.next_track_id!) + 1 as NSNumber
        newTrack.status = 1
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        var addedArtist: Artist?
        var addedAlbum: Album?
        var addedComposer: Composer?
        var addedAlbumArtist: Artist?
        for field in trackMetadata.allKeys as! [String] {
            switch field {
            case "name":
                newTrack.name = trackMetadata["name"] as? String
                newTrackView.name_order = trackMetadata["name_order"] as? Int as NSNumber?
            case "time":
                newTrack.time = trackMetadata["time"] as? NSNumber
            case "artist":
                let artistName = trackMetadata["artist"] as! String
                let artist: Artist = {() -> Artist in
                    let artistCheck = checkIfArtistExists(artistName)
                    if artistCheck == nil {
                        let artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: managedContext) as! Artist
                        addedArtist = artist
                        artist.name = artistName
                        artist.id = globalRootLibrary?.next_artist_id
                        globalRootLibrary?.next_artist_id = Int(globalRootLibrary!.next_artist_id!) + 1 as NSNumber
                        return artist
                    } else {
                        artistCheck?.is_network = nil
                        return artistCheck!
                    }
                }()
                newTrack.artist = artist
                newTrackView.artist_order = trackMetadata["artist_order"] as? Int as NSNumber?
            case "album":
                let albumName = trackMetadata["album"] as! String
                let album: Album = {
                    let albumCheck = checkIfAlbumExists(albumName)
                    if albumCheck == nil {
                        let album = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
                        addedAlbum = album
                        album.name = albumName
                        album.id = globalRootLibrary?.next_album_id
                        globalRootLibrary?.next_album_id = Int(globalRootLibrary!.next_album_id!) + 1 as NSNumber
                        return album
                    } else {
                        albumCheck?.is_network = nil
                        return albumCheck!
                    }
                }()
                newTrack.album = album
                newTrackView.album_order = trackMetadata["album_order"] as? Int as NSNumber?
            case "date_added":
                newTrack.date_added = Date() as NSDate
            case "date_modified":
                newTrack.date_modified = dateFormatter.date(from: trackMetadata["date_modified"] as! String) as! NSDate
            case "date_released":
                newTrack.album?.release_date = dateFormatter.date(from: trackMetadata["date_released"] as! String)
                newTrackView.release_date_order = trackMetadata["release_date_order"] as? Int as NSNumber?
            case "comments":
                newTrack.comments = trackMetadata["comments"] as? String
            case "composer":
                let composerName = trackMetadata["composer"] as! String
                let composer: Composer = {
                    let composerCheck = checkIfComposerExists(composerName)
                    if composerCheck == nil {
                        let composer = NSEntityDescription.insertNewObject(forEntityName: "Composer", into: managedContext) as! Composer
                        addedComposer = composer
                        composer.name = composerName
                        composer.id = globalRootLibrary?.next_composer_id
                        globalRootLibrary?.next_composer_id = Int(globalRootLibrary!.next_composer_id!) + 1 as NSNumber
                        return composer
                    } else {
                        composerCheck?.is_network = nil
                        return composerCheck!
                    }
                }()
                newTrack.composer = composer
            case "disc_number":
                newTrack.disc_number = trackMetadata["disc_number"] as? Int as NSNumber?
            case "genre":
                let genreName = trackMetadata["genre"] as? String
                newTrack.genre = genreName
            case "file_kind":
                newTrack.file_kind = trackMetadata["file_kind"] as? String
                newTrackView.kind_order = trackMetadata["kind_order"] as? Int as NSNumber?
            case "date_last_played":
                newTrack.date_last_played = dateFormatter.date(from: trackMetadata["date_last_played"] as! String) as! NSDate
            case "date_last_skipped":
                newTrack.date_last_skipped = dateFormatter.date(from: trackMetadata["date_last_skipped"] as! String) as! NSDate
            case "movement_name":
                newTrack.movement_name = trackMetadata["movement_name"] as? String
            case "movement_number":
                newTrack.movement_number = trackMetadata["movement_number"] as? Int as NSNumber?
            case "play_count":
                newTrack.play_count = trackMetadata["play_count"] as? Int as NSNumber?
            case "rating":
                newTrack.rating = trackMetadata["rating"] as? Int as NSNumber?
            case "bit_rate":
                newTrack.bit_rate = trackMetadata["bit_rate"] as? Int as NSNumber?
            case "sample_rate":
                newTrack.sample_rate = trackMetadata["sample_rate"] as? Int as NSNumber?
            case "size":
                newTrack.size = trackMetadata["size"] as? Int as NSNumber?
            case "skip_count":
                newTrack.skip_count = trackMetadata["skip_count"] as? Int as NSNumber?
            case "sort_album":
                newTrack.sort_album = trackMetadata["sort_album"] as? String
            case "sort_album_artist":
                newTrack.sort_album_artist = trackMetadata["sort_album_artist"] as? String
                newTrackView.album_artist_order = trackMetadata["album_artist_order"] as? Int as NSNumber?
            case "sort_artist":
                newTrack.sort_artist = trackMetadata["sort_artist"] as? String
            case "sort_composer":
                newTrack.sort_composer = trackMetadata["sort_composer"] as? String
            case "sort_name":
                newTrack.sort_name = trackMetadata["sort_name"] as? String
            case "track_num":
                newTrack.track_num = trackMetadata["track_num"] as? Int as NSNumber?
            case "location":
                newTrack.location = trackMetadata["location"] as? String
            case "album_artist":
                let artistName = trackMetadata["album_artist"] as! String
                let artist: Artist = {
                    let artistCheck = checkIfArtistExists(artistName)
                    if artistCheck == nil {
                        let artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: managedContext) as! Artist
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
                reorderForTracks([newTrack], cachedOrder: order.value)
            }
        } else {
            managedContext.delete(newTrack)
            managedContext.delete(newTrackView)
            if addedArtist != nil {
                managedContext.delete(addedArtist!)
            }
            if addedComposer != nil {
                managedContext.delete(addedComposer!)
            }
            if addedAlbum != nil {
                managedContext.delete(addedAlbum!)
            }
            if addedAlbumArtist != nil {
                managedContext.delete(addedAlbumArtist!)
            }
        }
        return true
    }
    
    func trackDoesNotExist(_ track: NSDictionary) -> Bool {
        let trackFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
        let id = track["id"] as! Int
        let trackPredicate = NSPredicate(format: "id == \(id)")
        trackFetch.predicate = trackPredicate
        do {
            let results = try managedContext.fetch(trackFetch) as! [Track]
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
    
    func verifyTrackLocations(visualUpdateHandler: LocationVerifierSheetController?, library: Library) -> [Track]? {
        let request = NSFetchRequest<Track>(entityName: "Track")
        let predicate = library != globalRootLibrary ? NSPredicate(format: "(is_network == false or is_network == nil) and library == %@", library) : NSPredicate(format: "is_network == false or is_network == nil")
        let fileManager = FileManager.default
        request.predicate = predicate
        do {
            let tracks = try managedContext.fetch(request)
            let count = tracks.count
            if visualUpdateHandler != nil {
                DispatchQueue.main.async {
                    visualUpdateHandler!.initialize(count: count)
                }
            }
            var countUpdate = count / 1000
            if countUpdate == 0 {countUpdate = 1}
            var numTracksChecked = 0
            var missingTracks = [Track]()
            for track in tracks {
                numTracksChecked += 1
                if let location = track.location, let url = URL(string: location), fileManager.fileExists(atPath: url.path) {
                    
                } else {
                    missingTracks.append(track)
                }
                if numTracksChecked % countUpdate == 0 {
                    if visualUpdateHandler != nil {
                        DispatchQueue.main.async {
                            visualUpdateHandler!.visualUpdateHandlerCallback(numTracksChecked: numTracksChecked)
                        }
                    }
                }
                if numTracksChecked >= count {
                    if visualUpdateHandler != nil {
                        DispatchQueue.main.async {
                            visualUpdateHandler!.completionHandler()
                        }
                    }
                }
            }
            print(missingTracks.count)
            return missingTracks
        } catch {
            print(error)
        }
        return nil
    }
    
    func scanForNewMedia(visualUpdateHandler: MediaScannerSheet?, library: Library) -> [URL] {
        //create o(1) data structure for current locations
        let request = NSFetchRequest<Track>(entityName: "Track")
        let predicate = library != globalRootLibrary ? NSPredicate(format: "(is_network == false or is_network == nil) and library == %@", library) : NSPredicate(format: "is_network == false or is_network == nil")
        request.predicate = predicate
        var locations: Set<String>
        do {
            let tracks = try managedContext.fetch(request)
            if visualUpdateHandler != nil {
                DispatchQueue.main.async {
                    visualUpdateHandler!.initializeForSetCreation()
                }
            }
            locations = Set(tracks.flatMap({return $0.location?.lowercased()}))
        } catch {
            print(error)
            return [URL]()
        }
        //scan the directory recursively for media
        if visualUpdateHandler != nil {
            DispatchQueue.main.async {
                visualUpdateHandler!.initializeForDirectoryParsing()
            }
        }
        let libraryURL = URL(string: library.central_media_folder_url_string!)!
        let mediaURLs = getMediaURLsInDirectoryURLs([libraryURL]).0
        //diff the sets
        if visualUpdateHandler != nil {
            DispatchQueue.main.async {
                visualUpdateHandler!.initializeForFiltering(count: mediaURLs.count)
            }
        }
        var count = 0
        var updateCount = mediaURLs.count / 1000
        if updateCount == 0 {updateCount = 1}
        let filteredURLs = mediaURLs.filter({(url: URL) -> Bool in
            count += 1
            if count % updateCount == 0 {
                if visualUpdateHandler != nil {
                    DispatchQueue.main.async {
                        visualUpdateHandler!.filteringCallback(numFilesChecked: count)
                    }
                }
            }
            if locations.contains(url.absoluteString.lowercased()) {
                return false
            } else {
                return true
            }
        })
        if visualUpdateHandler != nil {
            DispatchQueue.main.async {
                visualUpdateHandler!.doneFiltering()
            }
        }
        return filteredURLs
    }
    
    func fixInfoForTrack(track: Track) {
        //update file format, metadata for track
    }
    
    func saveStreamingNetworkTrack(_ track: Track, data: Data) {
        let fileName = {() -> String in
            switch globalRootLibrary?.renames_files as! Bool {
            case true:
                return self.formFilenameForTrack(track, url: nil)
            default:
                return URL(string: track.location!)!.lastPathComponent
            }
        }()
        var albumDirectoryURL: URL?
        var fileURL: URL?
        let libraryPathURL = URL(fileURLWithPath: globalRootLibrary!.central_media_folder_url_string!)
        let albumArtist = track.album?.album_artist?.name != nil ? track.album!.album_artist!.name! : track.artist?.name != nil ? track.artist!.name! : UNKNOWN_ARTIST_STRING
        let album = track.album?.name != nil ? track.album!.name! : UNKNOWN_ALBUM_STRING
        albumDirectoryURL = libraryPathURL.appendingPathComponent("tmp").appendingPathComponent(albumArtist).appendingPathComponent(album)
        do {
            try fileManager.createDirectory(at: albumDirectoryURL!, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("error creating album directory: \(error)")
        }
        do {
            fileURL = albumDirectoryURL?.appendingPathComponent(fileName)
            try data.write(to: fileURL!, options: NSData.WritingOptions.atomic)
            track.location = fileURL?.absoluteString
        } catch {
            print("error while moving/copying files: \(error)")
        }
    }

    func addTracksForPlaylistData(_ playlistDictionary: NSDictionary, item: SourceListItem) {
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
        //get tracks
        let tracks = playlistDictionary["playlist"] as! [NSDictionary]
        let addedArtists = NSMutableDictionary()
        let addedAlbums = NSMutableDictionary()
        let addedComposers = NSMutableDictionary()
        let addedTracks = NSMutableDictionary()
        var addedTrackViews = [TrackView]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        for track in tracks {
            guard trackDoesNotExist(track) else {continue}
            let newTrack = NSEntityDescription.insertNewObject(forEntityName: "Track", into: managedContext) as! Track
            let newTrackView = NSEntityDescription.insertNewObject(forEntityName: "TrackView", into: managedContext) as! TrackView
            newTrackView.is_network = true
            newTrackView.track = newTrack
            newTrack.is_network = true
            newTrack.is_playing = false
            for field in track.allKeys as! [String] {
                let trackArtist: Artist
                switch field {
                case "id":
                    let id = track["id"] as! Int
                    newTrack.id = track["id"] as? Int as NSNumber?
                    addedTracks[id] = newTrack
                case "is_enabled":
                    newTrack.status = track["is_enabled"] as? Bool as NSNumber?
                case "name":
                    newTrack.name = track["name"] as? String
                    newTrackView.name_order = track["name_order"] as? Int as NSNumber?
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
                                let artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: managedContext) as! Artist
                                artist.name = artistName
                                artist.id = globalRootLibrary?.next_artist_id
                                globalRootLibrary?.next_artist_id = Int(globalRootLibrary!.next_artist_id!) + 1 as NSNumber
                                artist.is_network = true
                                addedArtists[artistName] = artist
                                return artist
                            } else {
                                return artistCheck!
                            }
                        }
                    }()
                    newTrack.artist = artist
                    newTrackView.artist_order = track["artist_order"] as? Int as NSNumber?
                    trackArtist = artist
                case "album":
                    let albumName = track["album"] as! String
                    let album: Album = {
                        if addedAlbums[albumName] != nil {
                            return addedAlbums[albumName] as! Album
                        } else {
                            let albumCheck = checkIfAlbumExists(albumName)
                            if albumCheck == nil {
                                let album = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
                                album.name = albumName
                                album.id = library?.next_album_id
                                globalRootLibrary?.next_album_id = Int(globalRootLibrary!.next_album_id!) + 1 as NSNumber
                                album.is_network = true
                                addedAlbums[albumName] = album
                                return album
                            } else {
                                return albumCheck!
                            }
                        }
                    }()
                    newTrack.album = album
                    newTrackView.album_order = track["album_order"] as? Int as NSNumber?
                case "date_added":
                    newTrack.date_added = dateFormatter.date(from: track["date_added"] as! String) as! NSDate
                    newTrackView.date_added_order = track["date_added_order"] as? Int as NSNumber?
                case "date_modified":
                    newTrack.date_modified = dateFormatter.date(from: track["date_modified"] as! String) as! NSDate
                case "date_released":
                    newTrack.album?.release_date = dateFormatter.date(from: track["date_released"] as! String)
                    newTrackView.release_date_order = track["release_date_order"] as? Int as NSNumber?
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
                                let composer = NSEntityDescription.insertNewObject(forEntityName: "Composer", into: managedContext) as! Composer
                                composer.name = composerName
                                composer.id = globalRootLibrary?.next_composer_id
                                globalRootLibrary?.next_composer_id = Int(globalRootLibrary!.next_composer_id!) + 1 as NSNumber
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
                    newTrack.disc_number = track["disc_number"] as? Int as NSNumber?
                case "equalizer_preset":
                    newTrack.equalizer_preset = track["equalizer_preset"] as? String
                case "genre":
                    let genreName = track["genre"] as? String
                    newTrack.genre = genreName
                case "file_kind":
                    newTrack.file_kind = track["file_kind"] as? String
                    newTrackView.kind_order = track["kind_order"] as? Int as NSNumber?
                case "date_last_played":
                    newTrack.date_last_played = dateFormatter.date(from: track["date_last_played"] as! String) as! NSDate
                case "date_last_skipped":
                    newTrack.date_last_skipped = dateFormatter.date(from: track["date_last_skipped"] as! String) as! NSDate
                case "movement_name":
                    newTrack.movement_name = track["movement_name"] as? String
                case "movement_number":
                    newTrack.movement_number = track["movement_number"] as? Int as NSNumber?
                case "play_count":
                    newTrack.play_count = track["play_count"] as? Int as NSNumber?
                case "rating":
                    newTrack.rating = track["rating"] as? Int as NSNumber?
                case "bit_rate":
                    newTrack.bit_rate = track["bit_rate"] as? Int as NSNumber?
                case "sample_rate":
                    newTrack.sample_rate = track["sample_rate"] as? Int as NSNumber?
                case "size":
                    newTrack.size = track["size"] as? Int as NSNumber?
                case "skip_count":
                    newTrack.skip_count = track["skip_count"] as? Int as NSNumber?
                case "sort_album":
                    newTrack.sort_album = track["sort_album"] as? String
                case "sort_album_artist":
                    newTrack.sort_album_artist = track["sort_album_artist"] as? String
                    newTrackView.album_artist_order = track["album_artist_order"] as? Int as NSNumber?
                case "sort_artist":
                    newTrack.sort_artist = track["sort_artist"] as? String
                case "sort_composer":
                    newTrack.sort_composer = track["sort_composer"] as? String
                case "sort_name":
                    newTrack.sort_name = track["sort_name"] as? String
                case "track_num":
                    newTrack.track_num = track["track_num"] as? Int as NSNumber?
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
                                let artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: managedContext) as! Artist
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
        item.playlist?.track_id_list = track_id_list as NSObject?
    }
}
