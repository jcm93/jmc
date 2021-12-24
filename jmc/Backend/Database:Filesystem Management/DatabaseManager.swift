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
        return (NSApplication.shared.delegate
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
    var currentTrack: Track?
    var consolidationShouldStop: Bool = false
    
    func getArtworkFromFile(_ urlString: String) -> Data? {
        print("checking for art in file")
        let url = URL(string: urlString)
        let mediaObject = AVAsset(url: url!)
        var art: Data?
        let commonMeta = mediaObject.commonMetadata
        for metadataItem in commonMeta {
            if metadataItem.commonKey?.rawValue == "artwork" {
                print("found art in file")
                art = metadataItem.value as? Data
            }
        }
        return art
    }
    
    func tryFindPrimaryArtForTrack(_ track: Track, callback: ((Track, Bool) -> Void)?, background: Bool) { //does not handle errors good
        //we know primary_art is nil
        //may be called form background thread
        let track = resolve(track, inBackground: background) as! Track
        self.currentTrack = track
        let validImages = searchAlbumDirectoryForArt(track)
        if validImages.count > 0 {
            managedContext.perform {
                let track = managedContext.object(with: track.objectID) as! Track
                var results = [AlbumArtwork]()
                for image in validImages {
                    if let result = self.addArtForTrack(track, from: image, managedContext: managedContext, organizes: true) {
                        results.append(result)
                    }
                }
                if results.count > 0 {
                    callback?(track, true)
                } else {
                    callback?(track, false)
                }
            }
        } else {
            if let art = getArtworkFromFile(track.location!) {
                managedContext.perform {
                    let track = managedContext.object(with: track.objectID) as! Track
                    if self.addArtForTrack(track, fromData: art, managedContext: managedContext) == true {
                        callback?(track, true)
                    } else {
                        callback?(track, false)
                    }
                }
            } else {
                callback?(track, false)
            }
        }
    }
    
    func artFoundCallback(for track: Track) {
        guard self.currentTrack == track else { return }
    }
    
    func searchAlbumDirectoryForArt(_ track: Track) -> [URL] { //handles errors ok
        guard let location = track.location, let locationURL = URL(string: location) else { return [URL]() }
        let albumDirectoryURL = locationURL.deletingLastPathComponent()
        do {
            let albumDirectoryContents = try fileManager.contentsOfDirectory(at: albumDirectoryURL, includingPropertiesForKeys: [.typeIdentifierKey], options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            let validImages = albumDirectoryContents.filter({url in
                if let typeIdentifier = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
                    if UTTypeConformsTo(typeIdentifier as CFString, kUTTypeImage) || UTTypeConformsTo(typeIdentifier as CFString, kUTTypePDF) {
                        return NSImage(byReferencing: url).isValid
                    } else {
                        return false
                    }
                } else {
                    return false
                }
            })
            return validImages
        } catch {
            print("error looking in album directory for art: \(error)")
            return [URL]()
        }
    }
    
    @objc func undoOperationThatMovedFiles(for tracks: [Track]) {//handles errors
        print("undoing a move operation")
        var errors = [Error]()
        for track in tracks {
            if let currentFileLocation = self.undoFileLocations[track]?.removeLast() {
                do {
                    try fileManager.moveItem(at: URL(string: currentFileLocation)!, to: URL(string: track.location!)!)
                } catch {
                    print("error undoing move \(error)")
                    errors.append(error)
                    track.location = currentFileLocation
                }
            } else {
                //todo figure out how to initialize non-NSError, inform delegate
                //let error = NSError(domain: <#T##String#>, code: <#T##Int#>, userInfo: <#T##[String : Any]?#>)
                //errors.append(error)
                //
            }
        }
        informAppDelegateOfErrors(errors: errors)
    }
    
    func addMiscellaneousFile(forTrack track: Track, from url: URL, managedContext: NSManagedObjectContext, organizes: Bool) -> AlbumFile? {
        //returns true if file was successfully added
        guard let album = track.album else { return nil }
        guard let uti = getUTIFrom(url: url) else { return nil }
        guard UTTypeConformsTo(uti as CFString, kUTTypeText) else { return nil }
        let fileObject = NSEntityDescription.insertNewObject(forEntityName: "AlbumFile", into: managedContext) as! AlbumFile
        fileObject.album = album
        fileObject.location = url.absoluteString
        if UTTypeConformsTo(uti as CFString, CUE_SHEET_UTI_STRING as CFString) {
            fileObject.file_description = "Cue Sheet"
        } else if UTTypeConformsTo(uti as CFString, kUTTypeLog) {
            fileObject.file_description = "Log File"
        } else {
            fileObject.file_description = "Other File"
        }
        if organizes {
            let filename = url.lastPathComponent
            moveAlbumFileToAppropriateDirectory(albumFile: fileObject, filename: filename)
        }
        return fileObject
    }
    
    func moveAlbumFileToAppropriateDirectory(albumFile: AlbumFile, filename: String) { //does not handle errors
        let destination = getAlbumDirectory(for: albumFile.album!).appendingPathComponent(filename)
        do {
            let oldLocation = URL(string: albumFile.location!)!
            if globalRootLibrary?.organization_type == NSNumber(value: 1) {
                try fileManager.moveItem(at: oldLocation, to: destination)
            } else if globalRootLibrary?.organization_type == NSNumber(value: 2) {
                try fileManager.copyItem(at: oldLocation, to: destination)
            }
            albumFile.location = destination.absoluteString
        } catch {
            print(error)
        }
    }
    
    func moveAlbumFileToAppropriateDirectory(albumArt: AlbumArtwork, filename: String) { //does not handle errors
        let destination = getAlbumDirectory(for: albumArt.album ?? albumArt.album_multiple!).appendingPathComponent(filename)
        do {
            let oldLocation = URL(string: albumArt.location!)!
            try fileManager.copyItem(at: oldLocation, to: destination)
            albumArt.location = destination.absoluteString
        } catch {
            print(error)
        }
    }
    
    func addArtForTrack(_ track: Track, from url: URL, managedContext: NSManagedObjectContext, organizes: Bool) -> AlbumArtwork? {
        //returns true if art was successfully added, so a receiver can display the image, if needed
        guard let album = track.album else { return nil }
        let image = NSImage(byReferencing: url)
        guard image.isValid else { return nil }
        if track.album?.primary_art?.location != nil {
            let currentPrimaryArtURL = URL(string: track.album!.primary_art!.location!)
            guard url != currentPrimaryArtURL else { return nil }
        }
        if track.album?.other_art != nil && track.album!.other_art!.count > 0 {
            let currentArtURLs = track.album!.other_art!.map({return URL(string: ($0 as! AlbumArtwork).location!)!})
            guard !currentArtURLs.contains(url) else { return nil }
        }
        let filename = url.lastPathComponent
        var newArt: AlbumArtwork
        if track.album?.primary_art == nil {
            let newPrimaryArt = NSEntityDescription.insertNewObject(forEntityName: "AlbumArtwork", into: managedContext) as! AlbumArtwork
            newArt = newPrimaryArt
            newPrimaryArt.album = album
            newPrimaryArt.location = url.absoluteString
            newPrimaryArt.id = globalRootLibrary?.next_album_artwork_id
            globalRootLibrary?.next_album_artwork_id = globalRootLibrary!.next_album_artwork_id!.intValue + 1 as NSNumber?
        } else {
            let newOtherArt = NSEntityDescription.insertNewObject(forEntityName: "AlbumArtwork", into: managedContext) as! AlbumArtwork
            newArt = newOtherArt
            newOtherArt.album_multiple = album
            newOtherArt.location = url.absoluteString
            newOtherArt.id = globalRootLibrary?.next_album_artwork_id
            globalRootLibrary?.next_album_artwork_id = globalRootLibrary!.next_album_artwork_id!.intValue + 1 as NSNumber?
        }
        if organizes {
            moveAlbumFileToAppropriateDirectory(albumArt: newArt, filename: filename)
        }
        return newArt
    }
    
    func addArtForTrack(_ track: Track, fromData data: Data, managedContext: NSManagedObjectContext) -> Bool { //does not handle errors good
        //returns true if art was successfully added, so a receiver can display the image, if needed
        guard let album = track.album else { return false }
        guard let globalRootLibrary = track.library else {
            print("ruh roh")
            return false
        }
        let hashString = createMD5HashOf(data: data)
        if let existingPrimaryArt = track.album?.primary_art {
            var existingHash = ""
            if existingPrimaryArt.image_hash != nil {
                existingHash = existingPrimaryArt.image_hash!
            } else {
                do {
                    let url = URL(string: existingPrimaryArt.location!)!
                    let data = try Data(contentsOf: url, options: [])
                    let hash = createMD5HashOf(data: data)
                    existingPrimaryArt.image_hash = hash
                    existingHash = hash
                } catch {
                    print(error)
                }
            }
            guard existingHash != hashString else { return false }
        }
        if let existingOtherArtSet = track.album?.other_art, existingOtherArtSet.count > 0 {
            for setObject in existingOtherArtSet {
                let existingOtherArt = setObject as! AlbumArtwork
                var existingHash = ""
                if existingOtherArt.image_hash != nil {
                    existingHash = existingOtherArt.image_hash!
                } else {
                    do {
                        let url = URL(string: existingOtherArt.location!)!
                        let data = try Data(contentsOf: url, options: [])
                        let hash = createMD5HashOf(data: data)
                        existingOtherArt.image_hash = hash
                        existingHash = hash
                    } catch {
                        print(error)
                        //image from other art cannot be opened. what do?
                        continue
                    }
                }
                guard existingHash != hashString else { return false }
            }
        }
        //no matches from current art set
        //make sure it's a real image
        guard let fileExtension = getFileType(image: data) else { return false }
        let albumDirectory = getAlbumDirectory(for: album)
        let artworkURL = getArtworkFilenameForDirectory(url: albumDirectory, ext: fileExtension)
        do {
            try data.write(to: artworkURL)
        } catch {
            return false
        }
        if track.album?.primary_art == nil {
            let newPrimaryArt = NSEntityDescription.insertNewObject(forEntityName: "AlbumArtwork", into: managedContext) as! AlbumArtwork
            newPrimaryArt.album = album
            newPrimaryArt.location = artworkURL.absoluteString
            newPrimaryArt.id = globalRootLibrary.next_album_artwork_id
            globalRootLibrary.next_album_artwork_id = globalRootLibrary.next_album_artwork_id!.intValue + 1 as NSNumber?
            return true
        } else {
            let newOtherArt = NSEntityDescription.insertNewObject(forEntityName: "AlbumArtwork", into: managedContext) as! AlbumArtwork
            newOtherArt.album_multiple = album
            newOtherArt.location = artworkURL.absoluteString
            newOtherArt.id = globalRootLibrary.next_album_artwork_id
            globalRootLibrary.next_album_artwork_id = globalRootLibrary.next_album_artwork_id!.intValue + 1 as NSNumber?
            return true
        }
    }
    
    func getArtworkFilenameForDirectory(url: URL, ext: String) -> URL {
        /*
        let currentDirectoryContents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        let currentDirectoryImages = currentDirectoryContents.filter({(url: URL) -> Bool in
            do {
                let key: Set = [URLResourceKey.typeIdentifierKey]
                let values = try url.resourceValues(forKeys: key)
                return UTTypeConformsTo(values.typeIdentifier! as CFString, kUTTypeImage)
            } catch {
                return false
            }
        })
        let currentDirectoryImageFilenames = currentDirectoryImages.map({return $0.lastPathComponent}).filter({return $0.hasPrefix("cover")})
        //this is all totally unecessary
        */
        //just brute force search
        var index: Int = 0
        var potentialArtworkPath = url.appendingPathComponent("cover\(index != 0 ? String(index) : "").\(ext)")
        while fileManager.fileExists(atPath: potentialArtworkPath.path) {
            index += 1
            potentialArtworkPath = url.appendingPathComponent("cover\(index != 0 ? String(index) : "").\(ext)")
        }
        return potentialArtworkPath
    }
    
    func appendDuplicateTo(url: URL, dupe: Int) -> URL {
        let pathExtension = url.pathExtension
        var lastComponent = url.deletingPathExtension().lastPathComponent
        lastComponent.append(" \(dupe)")
        var newURL = url.deletingLastPathComponent().appendingPathComponent(lastComponent).appendingPathExtension(pathExtension)
        return newURL
    }
    
    //OK -- discrete
    func moveFileAfterEdit(_ track: Track, copies: Bool) -> Bool { //does not handle errors good
        print("moving file after edit")
        print("current track location: \(track.location)")
        guard track.library?.organization_type != NSNumber(integerLiteral: 0) else { return true }
        guard let currentLocation = URL(string: track.location!) else { print("current location doesn't exist."); return false }
        guard let newLocation = track.determineLocation() else { return false }
        let directoryURL = newLocation.deletingLastPathComponent()
        //check if directories already exist
        if currentLocation.path.lowercased() != newLocation.path.lowercased() {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                var dupe = 1
                var newLocationWithDupe = newLocation
                while (fileManager.fileExists(atPath: newLocationWithDupe.path)) {
                    newLocationWithDupe = appendDuplicateTo(url: newLocation, dupe: dupe)
                    dupe += 1
                }
                if !copies {
                    try fileManager.moveItem(at: currentLocation, to: newLocationWithDupe)
                } else {
                    try fileManager.copyItem(at: currentLocation, to: newLocationWithDupe)
                }
                track.location = newLocationWithDupe.absoluteString
            } catch {
                print("error moving file: \(error)")
                return false
            }
        } else {
            checkCasesForMove(withOldURL: currentLocation, newURL: newLocation)
        }
        trimDirectoryFollowingMoveOperation(track: track, oldLocation: currentLocation)
        print("moved \(currentLocation) to \(track.location!)")
        if self.undoFileLocations[track] == nil {
            self.undoFileLocations[track] = [String]()
        }
        self.undoFileLocations[track]!.append(track.location!)
        return true
    }
    
    func checkCasesForMove(withOldURL oldURL: URL, newURL: URL) { //does not handle errors good
        //oldURL.path.lowercased() == newURL.path.lowercased()
        guard oldURL.path.lowercased() == newURL.path.lowercased() else { return }
        let newPathComponents = newURL.pathComponents
        
        var oldComponentsTraversedSoFar = [String]()
        var newComponentsTraversedSoFar = [String]()
        for (index, pathComponent) in oldURL.pathComponents.enumerated() {
            if pathComponent != newPathComponents[index] {
                let urlA = URL(fileURLWithPath: "/" + (oldComponentsTraversedSoFar + [pathComponent]).joined(separator: "/"))
                let urlB = URL(fileURLWithPath: "/" + (newComponentsTraversedSoFar + [newPathComponents[index]]).joined(separator: "/"))
                do {
                    try fileManager.moveItem(at: urlA, to: urlB)
                } catch {
                    NSLog("error renaming directories for case mismatch: \(error)")
                }
            }
            newComponentsTraversedSoFar.append(newPathComponents[index])
            oldComponentsTraversedSoFar.append(pathComponent)
        }
    }
    
    func getAlbumDirectory(for album: Album) -> URL {
        let currentTrackLocations = album.tracks?.compactMap({return ($0 as! Track).location})
        let currentTrackDirectories = currentTrackLocations?.compactMap({return URL(string: $0)?.deletingLastPathComponent()}) ?? [URL]()
        let directoriesSet = Set(currentTrackDirectories)
        if directoriesSet.count == 1 {
            return directoriesSet.first!
        } else {
            return createNonTemplateDirectoryFor(album: album, dry: true)!
        }
    }
    
    func trimDirectoryFollowingMoveOperation(track: Track, oldLocation: URL) { //does not handle errors good
        let oldDirectory = oldLocation.deletingLastPathComponent()
        let currentTrackLocations = track.album?.tracks?.compactMap({return ($0 as! Track).location})
        let currentTrackDirectories = currentTrackLocations?.compactMap({return URL(string: $0)?.deletingLastPathComponent()}) ?? [URL]()
        let directoriesSet = Set(currentTrackDirectories)
        guard directoriesSet.contains(oldDirectory) == false else { return }
        //no files left in old directory
        guard let albumFiles = track.album?.getMiscellaneousFiles() else { return }
        if directoriesSet.count == 1 {
            let currentAlbumDirectory = directoriesSet.first!
            for albumFile in albumFiles {
                do {
                    let fileURL = URL(string: albumFile.value(forKey: "location") as! String)!
                    let fileName = fileURL.lastPathComponent
                    try fileManager.moveItem(at: fileURL, to: currentAlbumDirectory.appendingPathComponent(fileName))
                } catch {
                    print(error)
                }
            }
        } else {
            //construct directory for album files since album is spread across disparate locations
            guard let albumDirectory = createNonTemplateDirectoryFor(album: track.album, dry: false) else { return }
            for albumFile in albumFiles {
                do {
                    let fileURL = URL(string: albumFile.value(forKey: "location") as! String)!
                    let fileName = fileURL.lastPathComponent
                    try fileManager.moveItem(at: fileURL, to: albumDirectory.appendingPathComponent(fileName))
                } catch {
                    print(error)
                }
            }
        }
        do {
            let oldContents = try fileManager.contentsOfDirectory(at: oldDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            if oldContents.count < 1 {
                try fileManager.removeItem(at: oldDirectory)
            }
        } catch {
            print(error)
        }
        
    }
    
    func getMDItemFromURL(_ url: URL) -> MDItem? {
        let item = MDItemCreateWithURL(kCFAllocatorDefault, url as CFURL?)
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
    
    func getNonAudioFiles(inDirectory directory: URL) -> [(URL, CFString)]? {
        var currentDirectoryAddableFiles = [(URL, CFString)]()
        if let enumerator = fileManager.enumerator(atPath: directory.path) {
            for fileObject in enumerator {
                guard let file = fileObject as? URL else { continue }
                if let uti = (try? file.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier as CFString? {
                    if UTTypeConformsTo(uti, kUTTypeImage) || UTTypeConformsTo(uti, kUTTypePDF) || UTTypeConformsTo(uti, kUTTypeLog) || UTTypeConformsTo(uti, kUTTypeText) || file.pathExtension.lowercased() == "cue" {
                        currentDirectoryAddableFiles.append((file, uti))
                    }
                }
            }
        }
        return currentDirectoryAddableFiles
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
    
    func consolidateLibrary(withLocations newLocationDictionary: [NSObject : URL], context: NSManagedObjectContext, visualUpdateHandler: ProgressBarController?, moves: Bool) {
        //assume called on not-main queue
        var index = 0
        let count = newLocationDictionary.count
        DispatchQueue.main.async {
            visualUpdateHandler?.prepareForNewTask(actionName: "Consolidating", thingName: "tracks", thingCount: count)
        }
        for (object, newURL) in newLocationDictionary {
            guard self.consolidationShouldStop != true else { break }
            defer {
                index += 1
                DispatchQueue.main.async {
                    visualUpdateHandler?.increment(thingsDone: index)
                }
            }
            let object = object as! NSManagedObject
            let subContextObject = context.object(with: object.objectID)
            guard let oldURL = {() -> URL? in
                switch subContextObject {
                case let subContextObject as Track:
                    return URL(string: subContextObject.location ?? "")
                case let subContextObject as AlbumFile:
                    return URL(string: subContextObject.location ?? "")
                case let subContextObject as AlbumArtwork:
                    return URL(string: subContextObject.location ?? "")
                default:
                    return nil
                }
            }() else { continue }
            do {
                try fileManager.createDirectory(at: newURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
            do {
                switch moves {
                case true:
                    try fileManager.moveItem(at: oldURL, to: newURL)
                case false:
                    try fileManager.copyItem(at: oldURL, to: newURL)
                }
            } catch {
                print(error)
                //append error
                continue
            }
            switch subContextObject {
            case let subContextObject as Track:
                subContextObject.location = newURL.absoluteString
            case let subContextObject as AlbumFile:
                subContextObject.location = newURL.absoluteString
            case let subContextObject as AlbumArtwork:
                subContextObject.location = newURL.absoluteString
            default:
                break
            }
            do {
                try context.save()
                DispatchQueue.main.async {
                    do {
                        try managedContext.save()
                    } catch {
                        self.consolidationShouldStop = true
                    }
                }
            } catch {
                self.consolidationShouldStop = true
                continue
            }
        }
        if self.consolidationShouldStop == true {
            print("failure")
        } else {
            print("success")
        }
        DispatchQueue.main.async {
            visualUpdateHandler?.finish()
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
        metadataDictionary[kDateModifiedKey] = MDItemCopyAttribute(mediaFileObject, "kMDItemContentModificationDate" as CFString?) as? Date
        metadataDictionary[kFileKindKey]     = MDItemCopyAttribute(mediaFileObject, "kMDItemKind" as CFString?) as? String
        guard let size                       = MDItemCopyAttribute(mediaFileObject, "kMDItemFSSize" as CFString?) as? Int else {
                print(MDItemCopyAttribute(mediaFileObject, "kMDItemFSSize" as CFString?))
                print("doingluskhrejwk")
                return nil
        }
        metadataDictionary[kSizeKey]         = size as NSNumber?
        
        if url.pathExtension.lowercased() == "flac" {
            
            guard let flacReader = FlacDecoder(file: url, audioModule: nil) else { return nil }
            flacReader.initForMetadata()
            guard flacReader.sampleRate != nil && flacReader.bitsPerSample != nil && flacReader.channels != nil else { return nil }
            metadataDictionary[kSampleRateKey]  = flacReader.sampleRate
            let duration_seconds                = Double(flacReader.totalFrames) / Double(flacReader.sampleRate!)
            let bitRate                         = ((Double(metadataDictionary[kSizeKey] as! Int) * 8) / 1000) / duration_seconds
            metadataDictionary[kBitRateKey]     = bitRate
            metadataDictionary[kTimeKey]        = duration_seconds * 1000
            
            //format-sensitive metadata
            for item in flacReader.metadataDictionary {
                switch item.key.lowercased() {
                case "artist":
                    metadataDictionary[kArtistKey]          = item.value
                case "album":
                    metadataDictionary[kAlbumKey]           = item.value
                case "composer":
                    metadataDictionary[kComposerKey]        = item.value
                case "date":
                    metadataDictionary[kReleaseDateKey]     = item.value
                case "description":
                    metadataDictionary[kCommentsKey]        = item.value
                case "genre":
                    metadataDictionary[kGenreKey]           = item.value
                case "release date":
                    metadataDictionary[kReleaseDateKey]     = item.value
                case "title":
                    metadataDictionary[kNameKey]            = item.value
                case "tracknumber":
                    metadataDictionary[kTrackNumKey]        = item.value
                case "compilation":
                    metadataDictionary[kIsCompilationKey]   = item.value
                case "comment":
                    metadataDictionary[kCommentsKey]        = item.value
                case "totaltracks":
                    metadataDictionary[kTotalTracksKey]     = item.value
                case "discnumber":
                    metadataDictionary[kDiscNumberKey]      = item.value
                case "albumartist":
                    metadataDictionary[kAlbumArtistKey]     = item.value
                default: break
                }
            }
        } else {
            
            //this method for getting metadata appears to not work on macOS 12.0
            /*
            let sampleRate = MDItemCopyAttribute(mediaFileObject, "kMDItemAudioSampleRate" as CFString) as? Int as NSNumber?
            let bitRate = MDItemCopyAttribute(mediaFileObject, "kMDItemAudioBitRate" as CFString?) as! Double // / 1000
            let duration = MDItemCopyAttribute(mediaFileObject, "kMDItemDurationSeconds" as CFString?) as! Double // * 1000
            metadataDictionary[kSampleRateKey]  = sampleRate
            metadataDictionary[kBitRateKey]     = bitRate / 1000
            metadataDictionary[kTimeKey]        = duration * 1000
            metadataDictionary[kTrackNumKey]    = (MDItemCopyAttribute(mediaFileObject, "kMDItemAudioTrackNumber" as CFString?) as? Int).map({ return String($0) })
            metadataDictionary[kGenreKey]       = MDItemCopyAttribute(mediaFileObject, "kMDItemMusicalGenre" as CFString?) as? String
            metadataDictionary[kNameKey]        = MDItemCopyAttribute(mediaFileObject, "kMDItemTitle" as CFString?) as? String
            metadataDictionary[kAlbumKey]       = MDItemCopyAttribute(mediaFileObject, "kMDItemAlbum" as CFString?) as? String
            metadataDictionary[kArtistKey]      = (MDItemCopyAttribute(mediaFileObject, "kMDItemAuthors" as CFString?) as? [String])?[0]
            metadataDictionary[kComposerKey]    = MDItemCopyAttribute(mediaFileObject, "kMDItemComposer" as CFString?) as? String
             */
            //let's replace it with AVAsset which seems to work on 10.10+
            let asset = AVAsset(url: url)
            let assetMetadata = asset.metadata
            let assetAudioTrack = asset.tracks.first!
            let assetFormatInformation = assetAudioTrack.formatDescriptions[0] as! CMAudioFormatDescription
            let assetStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(assetFormatInformation)!.pointee
            
            metadataDictionary[kSampleRateKey] = Int(assetStreamBasicDescription.mSampleRate) as NSNumber?
            metadataDictionary[kBitRateKey] = Double(assetAudioTrack.estimatedDataRate / 1000.0)
            metadataDictionary[kTimeKey] = asset.duration.seconds
            for metadataItem in assetMetadata {
                if let commonKey = metadataItem.commonKey {
                    switch commonKey {
                    case .commonKeyArtist:
                        metadataDictionary[kArtistKey] = metadataItem.stringValue
                    case .commonKeyTitle:
                        metadataDictionary[kNameKey] = metadataItem.stringValue
                    case .commonKeyAlbumName:
                        metadataDictionary[kAlbumKey] = metadataItem.stringValue
                    case .commonKeyType:
                        //this is genre in a lot of files?
                        metadataDictionary[kGenreKey] = metadataItem.stringValue
                    default:
                        break
                    }
                } else {
                    if let metadataKey = metadataItem.key as? String {
                        if metadataKey == "TRCK" || metadataKey == "TPOS" {
                            metadataDictionary[kTrackNumKey] = metadataItem.stringValue
                        }
                    }
                }
            }
        }
        
        //other stuff?
        return metadataDictionary
    }
    
    func addTracksFromURLs(_ mediaURLs: [URL], to library: Library, context: NSManagedObjectContext, visualUpdateHandler: ProgressBarController?, callback: (() -> Void)?) -> [FileAddToDatabaseError] { //does not handle errors good
        let subContextLibrary = context.object(with: library.objectID)
        let globalRootLibrary = subContextLibrary as? Library
        var errors = [FileAddToDatabaseError]()
        var addedArtists = [String : Artist]()
        var addedAlbums = [Artist : [String : Album]]()
        var addedComposers = [String : Composer]()
        var addedVolumes = [URL : Volume]()
        var scannedDirectories = Set<URL>()
        var tracks = [Track]()
        var addedAlbumFiles = [AnyObject]()
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
            var addedAlbum: String?
            var addedComposer: Composer?
            var addedAlbumArtist: Artist?
            
            //create track and track view objects
            let track = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context) as! Track
            let trackView = NSEntityDescription.insertNewObject(forEntityName: "TrackView", into: context) as! TrackView
            trackView.track = track
            track.location = url.absoluteString
            track.date_added = Date() as NSDate
            track.id = globalRootLibrary?.next_track_id
            globalRootLibrary?.next_track_id = Int(globalRootLibrary!.next_track_id!) + 1 as NSNumber
            track.status = 0
            let volumeURL = getVolumeOfURL(url: url)
            if let existingVolume = addedVolumes[volumeURL]  {
                track.volume = existingVolume
            } else if let existingVolume = checkIfVolumeExists(withURL: volumeURL, subcontext: context) {
                track.volume = context.object(with: existingVolume.objectID) as! Volume
            } else {
                let newVolume = NSEntityDescription.insertNewObject(forEntityName: "Volume", into: context) as! Volume
                newVolume.location = volumeURL.absoluteString
                newVolume.name = (try? volumeURL.resourceValues(forKeys: [.volumeNameKey]))?.volumeName
                track.volume = newVolume
                let newSourceListItemForVolume = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: context) as! SourceListItem
                newSourceListItemForVolume.volume = newVolume
                newSourceListItemForVolume.name = newVolume.name
                let globalRootLibrarySourceListItem = getGlobalRootLibrarySourceListItem(context: context)
                (context.object(with: globalRootLibrarySourceListItem!.objectID) as! SourceListItem).addToChildren(newSourceListItemForVolume)
                addedVolumes[volumeURL] = newVolume
            }
            
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
            track.track_num     = (fileMetadataDictionary[kTrackNumKey] as? String).flatMap({return $0}).flatMap({return Int.init($0)}) as NSNumber?
            track.genre         = fileMetadataDictionary[kGenreKey] as? String
            if let name         = fileMetadataDictionary[kNameKey] as? String {
                track.name = name
            } else {
                track.name = url.deletingPathExtension().lastPathComponent
            }
            
            //populate artist, album, composer
            let artistCheck = fileMetadataDictionary[kArtistKey] as? String ?? ""
            if let alreadyAddedArtist = addedArtists[artistCheck] {
                track.artist = alreadyAddedArtist
            } else if let alreadyAddedArtist = checkIfArtistExists(artistCheck, subcontext: context) {
                track.artist = context.object(with: alreadyAddedArtist.objectID) as! Artist
            } else {
                let newArtist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: context) as! Artist
                newArtist.name = artistCheck
                newArtist.id = globalRootLibrary?.next_artist_id
                globalRootLibrary?.next_artist_id = Int(globalRootLibrary!.next_artist_id!) + 1 as NSNumber
                track.artist = newArtist
                addedArtists[artistCheck] = newArtist
                addedArtist = newArtist
            }
            let albumCheck = fileMetadataDictionary[kAlbumKey] as? String ?? ""
            if let alreadyAddedAlbum = addedAlbums[track.artist!]?[albumCheck] {
                track.album = alreadyAddedAlbum
            } else if let alreadyAddedAlbum = checkIfAlbumExists(withName: albumCheck, withArtist: track.artist!, subcontext: context) {
                track.album = context.object(with: alreadyAddedAlbum.objectID) as! Album
            } else {
                let newAlbum = NSEntityDescription.insertNewObject(forEntityName: "Album", into: context) as! Album
                newAlbum.name = albumCheck
                newAlbum.id = globalRootLibrary?.next_album_id
                addedAlbum = albumCheck
                if addedAlbums[track.artist!] == nil {
                    addedAlbums[track.artist!] = [String : Album]()
                }
                addedAlbums[track.artist!]![albumCheck] = newAlbum
                newAlbum.album_artist = track.artist!
                globalRootLibrary?.next_album_id = Int(globalRootLibrary!.next_album_id!) + 1 as NSNumber
                track.album = newAlbum
            }
            if let releaseDateString = fileMetadataDictionary[kReleaseDateKey] as? String {
                if let year = Int(releaseDateString) {
                    let date = JMDate(year: year)
                    track.album?.release_date = date
                }
            }
            if let composerCheck = fileMetadataDictionary[kComposerKey] as? String {
                if let alreadyAddedComposer = addedComposers[composerCheck] {
                    track.composer = alreadyAddedComposer
                } else if let alreadyAddedComposer = checkIfComposerExists(composerCheck, subcontext: context) {
                    track.composer = context.object(with: alreadyAddedComposer.objectID) as! Composer
                }  else {
                    let newComposer = NSEntityDescription.insertNewObject(forEntityName: "Composer", into: context) as! Composer
                    newComposer.name = composerCheck
                    newComposer.id = globalRootLibrary?.next_composer_id
                    globalRootLibrary?.next_composer_id = Int(globalRootLibrary!.next_composer_id!) + 1 as NSNumber
                    track.composer = newComposer
                    addedComposers[composerCheck] = newComposer
                    addedComposer = newComposer
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
                    otherMetadataForAlbumArt = otherMetadataForAlbumArt.filter({return $0.commonKey?.rawValue == "artwork"})
                    if otherMetadataForAlbumArt.count > 0 {
                        art = otherMetadataForAlbumArt[0].value as? Data
                        if art != nil {
                            hasArt = true
                        }
                    }
                }
            }
            
            //move file to the appropriate location, if we're organizing
            var result = true
            switch globalRootLibrary!.organization_type! {
            case NSNumber(integerLiteral: 1):
                result = moveFileAfterEdit(track, copies: false)
            case NSNumber(integerLiteral: 2):
                result = moveFileAfterEdit(track, copies: true)
            default: result = true
            }
            if hasArt {
                addArtForTrack(track, fromData: art!, managedContext: context)
            }
            if result == false {
                print("error moving")
                errors.append(FileAddToDatabaseError(url: url.absoluteString, error: "Couldn't move/copy file to album directory"))
                if addedAlbum != nil {
                    context.delete(track.album!)
                }
                context.delete(track)
                context.delete(trackView)
                if addedArtist != nil {
                    context.delete(addedArtist!)
                }
                if addedComposer != nil {
                    context.delete(addedComposer!)
                }
            } else {
                tracks.append(track)
            }
            index += 1
            let directoryURL = url.deletingLastPathComponent()
            if !scannedDirectories.contains(directoryURL) {
                //scan directory for art, logs, cues
                if let addableFiles = getNonAudioFiles(inDirectory: directoryURL) {
                    for file in addableFiles {
                        if UTTypeConformsTo(file.1 as CFString, kUTTypeImage) || UTTypeConformsTo(file.1 as CFString, kUTTypePDF) {
                            if let art = addArtForTrack(track, from: file.0, managedContext: context, organizes: false) {
                                addedAlbumFiles.append(art)
                            }
                        } else {
                            if let otherFile = addMiscellaneousFile(forTrack: track, from: file.0, managedContext: context, organizes: false) {
                                addedAlbumFiles.append(otherFile)
                            }
                        }
                    }
                }
                scannedDirectories.insert(directoryURL)
                
            }
            DispatchQueue.main.async {
                visualUpdateHandler?.increment(thingsDone: index)
            }
        }
        index = 0
        DispatchQueue.main.async {
            visualUpdateHandler?.prepareForNewTask(actionName: "Moving", thingName: "album files", thingCount: addedAlbumFiles.count)
        }
        if globalRootLibrary?.organization_type != NSNumber(integerLiteral: 0) {
            for item in addedAlbumFiles {
                if let albumFile = item as? AlbumFile {
                    let filename = URL(string: albumFile.location!)!.lastPathComponent
                    moveAlbumFileToAppropriateDirectory(albumFile: albumFile, filename: filename)
                } else if let art = item as? AlbumArtwork {
                    let filename = URL(string: art.location!)!.lastPathComponent
                    moveAlbumFileToAppropriateDirectory(albumArt: art, filename: filename)
                }
                DispatchQueue.main.async {
                    visualUpdateHandler?.increment(thingsDone: index)
                }
                index += 1
            }
        }
        
        
        DispatchQueue.main.async {
            visualUpdateHandler?.makeIndeterminate(actionName: "Repopulating sort cache...")
        }
        let cachedOrders = getCachedOrders(for: context)
        for order in cachedOrders! {
            reorderForTracks(tracks, cachedOrder: order.value, subContext: context)
        }
        DispatchQueue.main.async {
            visualUpdateHandler?.makeIndeterminate(actionName: "Committing changes...")
        }
        do {
            try context.save()
        } catch {
            print(error)
        }
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
        managedContext.undoManager?.registerUndo(withTarget: self, selector: #selector(undoOperationThatMovedFiles), object: tracks)
        editName(tracks, name: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order, subContext: nil)
        }
        for track in tracks {
            moveFileAfterEdit(track, copies: false)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Name")
    }
    
    func artistEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        managedContext.undoManager?.registerUndo(withTarget: self, selector: #selector(undoOperationThatMovedFiles), object: tracks)
        editArtist(tracks, artistName: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order, subContext: nil)
        }
        for track in tracks {
            moveFileAfterEdit(track, copies: false)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Artist")
    }
    
    func albumArtistEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        managedContext.undoManager?.registerUndo(withTarget: self, selector: #selector(undoOperationThatMovedFiles), object: tracks)
        editAlbumArtist(tracks, albumArtistName: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order, subContext: nil)
        }
        for track in tracks {
            moveFileAfterEdit(track, copies: false)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Album Artist")
    }
    
    func albumEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.registerUndo(withTarget: self, selector: #selector(undoOperationThatMovedFiles), object: tracks)
        managedContext.undoManager?.beginUndoGrouping()
        editAlbum(tracks, albumName: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order, subContext: nil)
        }
        for track in tracks {
            moveFileAfterEdit(track, copies: false)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Album")
    }
    
    func trackNumEdited(tracks: [Track], value: Int) {
        managedContext.undoManager?.beginUndoGrouping()
        managedContext.undoManager?.registerUndo(withTarget: self, selector: #selector(undoOperationThatMovedFiles), object: tracks)
        editTrackNum(tracks, num: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order, subContext: nil)
        }
        for track in tracks {
            moveFileAfterEdit(track, copies: false)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Track Number")
    }
    
    func trackNumOfEdited(tracks: [Track], value: Int) {
        managedContext.undoManager?.beginUndoGrouping()
        editTrackNumOf(tracks, num: value)
        for track in tracks {
            moveFileAfterEdit(track, copies: false)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Total Tracks")
    }
    
    func discNumEdited(tracks: [Track], value: Int) {
        managedContext.undoManager?.beginUndoGrouping()
        managedContext.undoManager?.registerUndo(withTarget: self, selector: #selector(undoOperationThatMovedFiles), object: tracks)
        editDiscNum(tracks, num: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order, subContext: nil)
        }
        for track in tracks {
            moveFileAfterEdit(track, copies: false)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Disc Number")
    }
    
    func totalDiscsEdited(tracks: [Track], value: Int) {
        managedContext.undoManager?.beginUndoGrouping()
        editDiscNumOf(tracks, num: value)
        for track in tracks {
            moveFileAfterEdit(track, copies: false)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Total Discs")
    }
    
    func composerEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        editComposer(tracks, composerName: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order, subContext: nil)
        }
        for track in tracks {
            moveFileAfterEdit(track, copies: false)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Composer")
    }
    
    func genreEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        editGenre(tracks, genre: value)
        for track in tracks {
            moveFileAfterEdit(track, copies: false)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Genre")
    }
    
    func compilationChanged(tracks: [Track], value: Bool) {
        managedContext.undoManager?.beginUndoGrouping()
        managedContext.undoManager?.registerUndo(withTarget: self, selector: #selector(undoOperationThatMovedFiles), object: tracks)
        editIsComp(tracks, isComp: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order, subContext: nil)
        }
        for track in tracks {
            moveFileAfterEdit(track, copies: false)
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
        for track in tracks {
            moveFileAfterEdit(track, copies: false)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Movement Name")
    }
    
    func movementNumEdited(tracks: [Track], value: Int) {
        //needs work
        managedContext.undoManager?.beginUndoGrouping()
        editMovementNum(tracks, num: value)
        for track in tracks {
            moveFileAfterEdit(track, copies: false)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Movement Number")
    }
    
    func sortAlbumEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        editSortAlbum(tracks, sortAlbum: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order, subContext: nil)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Sort Album")
    }
    
    func sortAlbumArtistEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        editSortAlbumArtist(tracks, sortAlbumArtist: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order, subContext: nil)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Sort Album Artist")
    }
    
    func sortArtistEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        editSortArtist(tracks, sortArtist: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order, subContext: nil)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Sort Artist")
    }
    
    func sortComposerEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        editSortComposer(tracks, sortComposer: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order, subContext: nil)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Sort Composer")
    }
    
    func sortNameEdited(tracks: [Track], value: String) {
        managedContext.undoManager?.beginUndoGrouping()
        editSortName(tracks, sortName: value)
        for order in cachedOrders!.values {
            reorderForTracks(tracks, cachedOrder: order, subContext: nil)
        }
        managedContext.undoManager?.endUndoGrouping()
        managedContext.undoManager?.setActionName("Edit Sort Name")
    }
    
    func releaseDateEdited(tracks: [Track], value: JMDate) {
        withUndoBlock(name: "Edit Release Date") {
            editReleaseDate(tracks, date: value)
            for order in cachedOrders!.values {
                reorderForTracks(tracks, cachedOrder: order, subContext: nil)
            }
            for track in tracks {
                moveFileAfterEdit(track, copies: false)
            }
        }
    }
    
    
    
    func batchMoveTracks(tracks: [Track], visualUpdateHandler: ProgressBarController?) {
        let subContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        subContext.parent = managedContext
        let subContextTracks = tracks.map({return subContext.object(with: $0.objectID) as! Track})
        DispatchQueue.global(qos: .default).async {
            var index = 0
            for track in subContextTracks {
                self.moveFileAfterEdit(track, copies: false)
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
    
    
    //MARK: network stuff (needs rewrite-ish)
    
    func moveFileForNetworkTrackToAppropriateLocationWithData(_ track: Track, data: Data) -> Bool {
        guard let location = track.determineLocation() else { print("could not determine location"); return false }
        let containingDirectoryURL = location.deletingLastPathComponent()
        do {
            try fileManager.createDirectory(at: containingDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("error creating album directory: \(error)")
            return false
        }
        do {
            try data.write(to: location, options: NSData.WritingOptions.atomic)
            track.location = location.absoluteString
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
                    let albumCheck = checkIfAlbumExists(withName: albumName, withArtist: track.artist!)
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
                newTrack.album?.release_date?.date = dateFormatter.date(from: trackMetadata["date_released"] as! String) as! NSDate
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
                reorderForTracks([newTrack], cachedOrder: order.value, subContext: nil)
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
    
    func verifyTrackLocations(visualUpdateHandler: LocationVerifierSheetController?, library: Library, context: NSManagedObjectContext) -> [Track]? {
        let request = NSFetchRequest<Track>(entityName: "Track")
        let predicate = library != globalRootLibrary ? NSPredicate(format: "(is_network == false or is_network == nil) and library == %@", library) : NSPredicate(format: "is_network == false or is_network == nil")
        let fileManager = FileManager.default
        request.predicate = predicate
        do {
            let tracks = try context.fetch(request)
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
            }
            if visualUpdateHandler != nil {
                DispatchQueue.main.async {
                    visualUpdateHandler!.completionHandler()
                }
            }
            return missingTracks
        } catch {
            if visualUpdateHandler != nil {
                DispatchQueue.main.async {
                    visualUpdateHandler!.completionHandler()
                }
            }
            print(error)
        }
        if visualUpdateHandler != nil {
            DispatchQueue.main.async {
                visualUpdateHandler!.completionHandler()
            }
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
            locations = Set(tracks.compactMap({return $0.location?.lowercased()}))
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
        let libraryURL = library.getCentralMediaFolder()!
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
        let libraryPathURL = globalRootLibrary!.getCentralMediaFolder()!
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
                            let albumCheck = checkIfAlbumExists(withName: albumName, withArtist: newTrack.artist!)
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
                    newTrack.album?.release_date?.date = dateFormatter.date(from: track["date_released"] as! String) as! NSDate
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
    }
}
