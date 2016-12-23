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

enum TrackAddToDatabaseError: ErrorType {
    case couldNotUpdateFileSystem
    case couldntEVenOpenTheFile
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
    
    func addTracksFromURLStrings(urlStrings: [String]) throws -> TrackAddToDatabaseError {
        let addedArtists: NSMutableDictionary, addedAlbums: NSMutableDictionary, addedComposers: NSMutableDictionary, addedGenres: NSMutableDictionary = NSMutableDictionary()
        var tracks = [Track]()
        for urlString in urlStrings {
            var hasArt = false
            let track = NSEntityDescription.insertNewObjectForEntityForName("Track", inManagedObjectContext: managedContext) as! Track
            tracks.append(track)
            guard let url = NSURL(string: urlString) else {return .couldntEVenOpenTheFile}
            guard let mediaFileObject = getMDItemFromURL(url) else {return .couldntEVenOpenTheFile}
            var art: NSData?
            track.sample_rate = MDItemCopyAttribute(mediaFileObject, "kMDItemAudioSampleRate" as CFString) as? Int
            track.date_added = NSDate()
            track.date_modified = MDItemCopyAttribute(mediaFileObject, "kMDItemContentModificationDate") as? NSDate
            track.file_kind = MDItemCopyAttribute(mediaFileObject, "kMDItemKind") as? String
            track.bit_rate = MDItemCopyAttribute(mediaFileObject, "kMDItemAudioBitRate") as? Int
            track.id = library?.next_track_id
            library?.next_track_id = Int(library!.next_track_id!) + 1
            track.status = 1
            track.time = (MDItemCopyAttribute(mediaFileObject, "kMDItemDurationSeconds") as! Int) * 1000
            track.size = MDItemCopyAttribute(mediaFileObject, "kMDItemFSSize") as! Int
            track.name = MDItemCopyAttribute(mediaFileObject, "kMDItemTitle") as? String
            track.track_num = MDItemCopyAttribute(mediaFileObject, "kMDItemAudioTrackNumber") as? Int
            if let genreCheck = MDItemCopyAttribute(mediaFileObject, "kMDItemMusicalGenre") as? String {
                if let alreadyAddedGenre = addedGenres[genreCheck] as? Genre {
                    track.genre = alreadyAddedGenre
                } else {
                    let newGenre = NSEntityDescription.insertNewObjectForEntityForName("Genre", inManagedObjectContext: managedContext) as! Genre
                    newGenre.name = genreCheck
                    track.genre = newGenre
                    addedGenres[genreCheck] = newGenre
                }
            }
            if let albumCheck = MDItemCopyAttribute(mediaFileObject, "kMDItemAlbum") as? String {
                if let alreadyAddedAlbum = addedAlbums[albumCheck] as? Album {
                    track.album = alreadyAddedAlbum
                } else {
                    let newAlbum = NSEntityDescription.insertNewObjectForEntityForName("Album", inManagedObjectContext: managedContext) as! Album
                    newAlbum.name = albumCheck
                    track.album = newAlbum
                    addedAlbums[albumCheck] = newAlbum
                }
            }
            if let artistCheck = MDItemCopyAttribute(mediaFileObject, "kMDItemAuthors") as? [String] {
                let mainArtistCheck = artistCheck[0]
                if let alreadyAddedArtist = addedArtists[mainArtistCheck] as? Artist {
                    track.artist = alreadyAddedArtist
                } else {
                    let newArtist = NSEntityDescription.insertNewObjectForEntityForName("Artist", inManagedObjectContext: managedContext) as! Artist
                    newArtist.name = mainArtistCheck
                    track.artist = newArtist
                    addedArtists[mainArtistCheck] = newArtist
                }
            }
            if let composerCheck = MDItemCopyAttribute(mediaFileObject, "kMDItemComposer") as? String {
                if let alreadyAddedComposer = addedArtists[composerCheck] as? Composer {
                    track.composer = alreadyAddedComposer
                } else {
                    let newComposer = NSEntityDescription.insertNewObjectForEntityForName("Composer", inManagedObjectContext: managedContext) as! Composer
                    newComposer.name = composerCheck
                    track.composer = newComposer
                    addedComposers[composerCheck] = newComposer
                }
            }
            //add sort values
            addSortValues(track)
            var otherMetadataForAlbumArt = AVAsset(URL: url).commonMetadata
            otherMetadataForAlbumArt = otherMetadataForAlbumArt.filter({return $0.commonKey == "artwork"})
            if otherMetadataForAlbumArt.count > 0 {
                art = otherMetadataForAlbumArt[0].value as? NSData
                if art != nil {
                    hasArt = true
                }
            }
            if let moveFileForTrackResult = moveFileToAppropriateLocationForTrack(track, currentURL: url) {
                if hasArt == true {
                    addPrimaryArtForTrack(track, art: art!, trackURL: moveFileForTrackResult)
                }
            } else {
                return .couldNotUpdateFileSystem
            }
        }
        for order in cachedOrders! {
            reorderForTracks(tracks, cachedOrder: order)
        }
    }
    
    func moveFileToAppropriateLocationForTrack(track: Track, currentURL: NSURL) -> NSURL? {
        let fileName = {() -> String in
            switch NSUserDefaults.standardUserDefaults().boolForKey(DEFAULTS_RENAMES_FILES_STRING) {
            case true:
                return self.formFilenameForTrack(track)
            default:
                return currentURL.lastPathComponent!
            }
        }()
        var albumDirectoryURL: NSURL?
        var fileURL: NSURL?
        let orgType = NSUserDefaults.standardUserDefaults().objectForKey(DEFAULTS_LIBRARY_ORGANIZATION_TYPE_STRING)! as! Int
        if orgType == NO_ORGANIZATION_TYPE {
            track.location = currentURL.absoluteString
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
    }
    
    func formFilenameForTrack(track: Track) -> String {
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
        var filenameString = "\(trackNumberStringRepresentation) \(trackNameString).\(trackExtension)"
        if filenameString == " " {
            filenameString = NO_FILENAME_STRING
        }
    }
    
    func createFileForNetworkTrack(track: Track, data: NSData, trackMetadata: NSDictionary) -> Bool {
        
    }
}
