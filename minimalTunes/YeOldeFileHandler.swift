//
//  YeOldeFileHandler.swift
//  minimalTunes
//
//  Created by John Moody on 6/29/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
import AVFoundation


func md5(string string: String) -> String {
    var digest = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
    if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
        CC_MD5(data.bytes, CC_LONG(data.length), &digest)
    }
    
    var digestHex = ""
    for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
        digestHex += String(format: "%02x", digest[index])
    }
    
    return digestHex
}

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

class YeOldeFileHandler: NSObject {
    
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
    
    /*func getTrackFromFile(url: NSURL) -> [String] {
        var mediaObject = AVAsset(URL: url)
        let meta = mediaObject.metadata
        var result = [String]()
        for key in meta {
            if key.extraAttributes != nil {
                for dict in key.extraAttributes! {
                    result.append(dict.0)
                }
            }
        }
        return result
    }*/
    
    func transformFormatToString(type: AudioFormatID) -> String {
        print(type)
        switch type {
        case kAudioFormatAC3:
            return "AC-3 codec audio file"
        case kAudioFormatAMR:
            return "AMR narrow band audio file"
        case kAudioFormatMPEG4AAC_ELD:
            return "MPEG-4 AAC Enhanced Low Delay audio file"
        case kAudioFormatALaw:
            return "aLaw 2:1 audio file"
        case kAudioFormatiLBC:
            return "iLBC audio file"
        case kAudioFormatULaw:
            return "uLaw 2:1 audio file"
        case kAudioFormatMACE3:
            return "MACE 3:1 audio file"
        case kAudioFormatMACE6:
            return "MACE 6:1 audio file"
        case kAudioFormatAudible:
            return "Audible, Inc. audio file"
        case kAudioFormatQDesign:
            return "QDesign music audio file"
        case kAudioFormat60958AC3:
            return "IEC 60958-compliant AC-3 audio file"
        case kAudioFormatMPEG4AAC:
            return "MPEG-4 AAC audio file"
        case kAudioFormatQDesign2:
            return "QDesign2 music audio file"
        case kAudioFormatQUALCOMM:
            return "QUALCOMM PureVoice audio file"
        case kAudioFormatAppleIMA4:
            return "IMA 4:1 ADPCM audio file"
        case kAudioFormatLinearPCM:
            return "Linear PCM audio file"
        case kAudioFormatMPEG4CELP:
            return "MPEG-4 CELP audio file"
        case kAudioFormatMPEG4HVXC:
            return "MPEG-4 HVXC audio file"
        case kAudioFormatMIDIStream:
            return "MIDI stream audio file"
        case kAudioFormatMPEGLayer1:
            return "MPEG-1/2 Layer 1 audio file"
        case kAudioFormatMPEGLayer2:
            return "MPEG-1/2 Layer 2 audio file"
        case kAudioFormatMPEGLayer3:
            return "MPEG-1/2 Layer 3 audio file"
        case kAudioFormatDVIIntelIMA:
            return "DIV Intel IMA audio file"
        case kAudioFormatMPEG4AAC_HE:
            return "MPEG-4 High Efficiency AAC audio file"
        case kAudioFormatMPEG4AAC_LD:
            return "MPEG-4 Low Delay AAC audio file"
        case kAudioFormatMPEG4TwinVQ:
            return "MPEG-4 TwinVQ audio file"
        case kAudioFormatMicrosoftGSM:
            return "Microsoft GSM 6.10 audio file"
        case kAudioFormatAppleLossless:
            return "Apple Lossless audio file"
        case kAudioFormatMPEG4AAC_HE_V2:
            return "MPEG-4 High Efficiency AAC v2.0 audio file"
        case kAudioFormatMPEG4AAC_ELD_SBR:
            return "MPEG-4 AAC Enhanced Low Delay with SBR audio file"
        case kAudioFormatMPEG4AAC_Spatial:
            return "Spatial MPEG-4 AAC audio file"
        default:
            return "Unknown Audio Format"
        }
    }
    
    func getArtworkFromFile(filename: String) -> NSData? {
        print("checking for art in file")
        let url = NSURL(string: filename)
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
    
    func getTrackFromFile(filename: String) -> Track? {
        var hasArt = false
        let track = NSEntityDescription.insertNewObjectForEntityForName("Track", inManagedObjectContext: managedContext) as! Track
        let url = NSURL(string: filename)
        let actualFilename = url?.lastPathComponent
        var fileAttributes: [String : AnyObject]?
        do {
            fileAttributes = try fileManager.attributesOfItemAtPath(NSURL(string: filename)!.path!)
        } catch {
            print("file read error: \(error)")
        }
        var mediaObject: AVAsset?
        mediaObject = AVAsset(URL: url!)
        var thing: Int = 0
        var art: NSData?
        let desc = CMAudioFormatDescriptionGetFormatList(mediaObject?.tracks[0].formatDescriptions[0] as! CMAudioFormatDescription, &thing)
        track.sample_rate = desc.memory.mASBD.mSampleRate
        track.date_added = NSDate()
        track.date_modified = NSDate()
        track.file_kind = transformFormatToString(desc.memory.mASBD.mFormatID)
        track.id = NSUserDefaults.standardUserDefaults().integerForKey("currentID")
        track.status = 1
        track.time = CMTimeGetSeconds((mediaObject?.duration)!) * 1000
        track.size = fileAttributes!["NSFileSize"] as? NSNumber
        let commonMeta = mediaObject?.commonMetadata
        for key in commonMeta! {
            var placeholderNewAlbum: Album?
            switch key.commonKey! {
                case "title":
                    track.name = key.value as? String
                case "type":
                    let genreCheck = instanceCheck("Genre", name: key.value as! String) as? Genre
                    if genreCheck != nil {
                        track.genre = genreCheck
                    }
                    else {
                        let newGenre = NSEntityDescription.insertNewObjectForEntityForName("Genre", inManagedObjectContext: managedContext) as! Genre
                        newGenre.name = key.value as? String
                        track.genre = newGenre
                    }
                case "albumName":
                    let albumCheck = instanceCheck("Album", name: key.value as! String) as? Album
                    if albumCheck != nil {
                        track.album = albumCheck
                    }
                    else {
                        let newAlbum = NSEntityDescription.insertNewObjectForEntityForName("Album", inManagedObjectContext: managedContext) as! Album
                        newAlbum.name = key.value as? String
                        track.album = newAlbum
                        placeholderNewAlbum = newAlbum
                    }
                case "artist":
                    let artistCheck = instanceCheck("Artist", name: key.value as! String) as? Artist
                    if artistCheck != nil {
                        track.artist = artistCheck
                    }
                    else {
                        let newArtist = NSEntityDescription.insertNewObjectForEntityForName("Artist", inManagedObjectContext: managedContext) as! Artist
                        newArtist.name = key.value as? String
                        track.artist = newArtist
                    }
                case "creator":
                    let composerCheck = instanceCheck("Composer", name: key.value as! String) as? Composer
                    if composerCheck != nil {
                        track.composer = composerCheck
                    }
                    else {
                        let newComposer = NSEntityDescription.insertNewObjectForEntityForName("Composer", inManagedObjectContext: managedContext) as! Composer
                        newComposer.name = key.value as? String
                        track.composer = newComposer
                    }
                case "artwork":
                    hasArt = true
                    print("has artwork")
                    art = key.value as! NSData
                case "creationDate":
                    print("date:")
                    print(key.value)
                case "description":
                    track.comments = key.value as? String
                
            default: break
                
                
            }
        }
        let metadata = mediaObject?.metadata
        for key in metadata! {
            if (key.key?.description == "TRCK") {
                track.track_num = Int((key.value?.description)!)
            }
        }
        var albumDirectoryURL: NSURL?
        var fileURL: NSURL?
        let orgType = NSUserDefaults.standardUserDefaults().objectForKey(DEFAULTS_LIBRARY_ORGANIZATION_TYPE_STRING)! as! Int
        if orgType == NO_ORGANIZATION_TYPE {
            track.location = url!.absoluteString
        } else {
            let libraryPathURL = NSURL(string: NSUserDefaults.standardUserDefaults().objectForKey(DEFAULTS_LIBRARY_PATH_STRING) as! String)!
            let albumArtist = track.album?.album_artist?.name != nil ? track.album!.album_artist!.name! : track.artist?.name != nil ? track.artist!.name! : UNKNOWN_ARTIST_STRING
            let album = track.album?.name != nil ? track.album!.name! : UNKNOWN_ALBUM_STRING
            albumDirectoryURL = libraryPathURL.URLByAppendingPathComponent(albumArtist).URLByAppendingPathComponent(album)
            do {
                try fileManager.createDirectoryAtURL(albumDirectoryURL!, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("error creating album directory: \(error)")
            }
            if orgType == MOVE_ORGANIZATION_TYPE {
                do {
                    fileURL = albumDirectoryURL?.URLByAppendingPathComponent(actualFilename!)
                    try fileManager.moveItemAtURL(url!, toURL: fileURL!)
                } catch {
                    print("error moving item to album directory: \(error)")
                }
                track.location = fileURL!.absoluteString
            } else if orgType == COPY_ORGANIZATION_TYPE {
                do {
                    fileURL = albumDirectoryURL?.URLByAppendingPathComponent(actualFilename!)
                    try fileManager.copyItemAtURL(url!, toURL: fileURL!)
                } catch {
                    print("error copying item to album directory: \(error)")
                }
                track.location = fileURL!.absoluteString
            }
        }

        if hasArt == true {
            addPrimaryArtForTrack(track, art: art!, albumDirectoryURL: albumDirectoryURL!)
        }
        
        for order in cachedOrders! {
            reorderForTracks([track], cachedOrder: order)
        }
        return track
    }
}
