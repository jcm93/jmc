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
    
    lazy var managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    
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
        if type == 778924083 {
            return "MPEG Audio File"
        }
        return ""
    }
    
    func getTrackFromFile(filename: String) -> Track? {
        var hasArt = false
        let fileManager = NSFileManager.defaultManager()
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
                    track.album?.album_artist = track.artist
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
                    art = key.value as! NSData
                    let artImage = NSImage(data: art!)
                
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
        var albumDirectoryPath: String?
        var filePath: String?
        switch NSUserDefaults.standardUserDefaults().objectForKey("organizationType")! as! Int {
        case 0:
            track.location = url!.absoluteString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet())
        case 2:
            let libraryPathString = NSUserDefaults.standardUserDefaults().objectForKey("libraryPath") as! String
            let albumArtist = track.album?.album_artist!.name
            let album = track.album!.name
            albumDirectoryPath = libraryPathString + "/\(albumArtist!)/\(album!)"
            do {
                var stupidTrue = ObjCBool(true)
                if (fileManager.fileExistsAtPath(albumDirectoryPath!, isDirectory: &stupidTrue) == false) {
                    print("file exists at path is false")
                    try fileManager.createDirectoryAtPath(albumDirectoryPath!, withIntermediateDirectories: true, attributes: nil)
                }
            } catch {
                print("error: \(error)")
            }
            do {
                filePath = albumDirectoryPath! + "/\(actualFilename!)"
                try fileManager.copyItemAtPath(url!.path!, toPath: filePath!)
            } catch {
                print("err: \(error)")
            }
            track.location = "File://" + filePath!.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet())!
        case 1:
            let libraryPathString = NSUserDefaults.standardUserDefaults().objectForKey("libraryPath") as! String
            let albumArtist = track.album?.album_artist!.name
            let album = track.album!.name
            albumDirectoryPath = libraryPathString + "/\(albumArtist!)/\(album!)"
            do {
                var stupidTrue = ObjCBool(true)
                if (fileManager.fileExistsAtPath(albumDirectoryPath!, isDirectory: &stupidTrue) == false) {
                    print("file exists at path is false")
                    try fileManager.createDirectoryAtPath(albumDirectoryPath!, withIntermediateDirectories: true, attributes: nil)
                }
            } catch {
                print("error: \(error)")
            }
            do {
                filePath = albumDirectoryPath! + "/\(actualFilename!)"
                try fileManager.moveItemAtPath(url!.path!, toPath: filePath!)
            } catch {
                print("err: \(error)")
            }
            track.location = "File://" + filePath!.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet())!
        default: break
        }
        

        if hasArt == true {
            let artHash = art!.hashValue
            let currentAlbumArt: AlbumArtworkCollection
            if track.album!.art == nil {
                let newArtworkCollection = NSEntityDescription.insertNewObjectForEntityForName("AlbumArtworkCollection", inManagedObjectContext: managedContext) as! AlbumArtworkCollection
                newArtworkCollection.album = track.album
                currentAlbumArt = newArtworkCollection
            }
            else {
                currentAlbumArt = track.album!.art!
            }
            var contains = false
            for artwork in (currentAlbumArt.art)! {
                if (artwork as! AlbumArtwork).image_hash == artHash {
                    contains = true
                }
            }
            if contains == false {
                let newArtwork = NSEntityDescription.insertNewObjectForEntityForName("AlbumArtwork", inManagedObjectContext: managedContext) as! AlbumArtwork
                newArtwork.collection_album = currentAlbumArt
                let artCount = currentAlbumArt.art?.count
                newArtwork.image_hash = artHash
                let artFilename = albumDirectoryPath! + "/Embedded Artwork - \(artCount).png"
                newArtwork.artwork_location = artFilename
                let artImage = NSImage(data: art!)
                let artTIFF = artImage?.TIFFRepresentation
                let artRep = NSBitmapImageRep(data: artTIFF!)
                let artPNG = artRep?.representationUsingType(.NSPNGFileType, properties: [:])
                do {try artPNG?.writeToFile(artFilename, options: NSDataWritingOptions.AtomicWrite)
                }catch {
                    print("error writing file: \(error)")
                }
            }
        }
        
        return track
    }
}
