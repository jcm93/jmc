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


func createTableViewCopy(table: TableViewYouCanPressSpacebarOn) -> TableViewYouCanPressSpacebarOn {
    let currentRect = table.visibleRect
    let container = NSScrollView(frame: currentRect)
    let newTableView = TableViewYouCanPressSpacebarOn(frame: currentRect)
    let newArrayController = NSArrayController()
    newArrayController.managedObjectContext = managedContext
    newArrayController.entityName = "Track"
    newArrayController.automaticallyPreparesContent = true
    for column in table.tableColumns {
        let newTableColumn = NSTableColumn(identifier: column.identifier)
        newTableColumn.title = column.title
        newTableView.addTableColumn(column)
    }
    return newTableView
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

func editArtist(tracks: [Track]?, artistName: String) {
    print(artistName)
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    let artistCheck: Artist? = {
        let fetch_req = NSFetchRequest(entityName: "Artist")
        let predicate = NSPredicate(format: "name == %@", artistName)
        fetch_req.predicate = predicate
        do {
            let results = try managedContext.executeFetchRequest(fetch_req) as! [Artist]
            if (results.count > 0) {
                return results[0]
            } else {
                return nil
            }
            
        } catch {
            print("error: \(error)")
            return nil
        }
    }()
    if artistCheck != nil {
        for track in tracks! {
            track.artist = artistCheck!
            let artistName = artistCheck!.name!
            var sortArtistName: String
            if artistCheck!.name!.hasPrefix("The ") || artistCheck!.name!.hasPrefix("the ") {
                let range = artistName.startIndex...artistName.startIndex.advancedBy(3)
                sortArtistName = artistName
                sortArtistName.removeRange(range)
            }
            else {
                sortArtistName = artistName
            }
            track.sort_artist = sortArtistName
        }
    } else {
        let new_artist = NSEntityDescription.insertNewObjectForEntityForName("Artist", inManagedObjectContext: managedContext) as! Artist
        new_artist.name = artistName
        var sortArtistName: String
        if artistName.hasPrefix("The ") || artistName.hasPrefix("the ") {
            let range = artistName.startIndex...artistName.startIndex.advancedBy(3)
            sortArtistName = artistName
            sortArtistName.removeRange(range)
            print(sortArtistName)
        }
        else {
            sortArtistName = artistName
        }
        for track in tracks! {
            track.artist = new_artist
            track.sort_artist = sortArtistName
        }
    }
}

func editAlbum(tracks: [Track]?, albumName: String) {
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    print(albumName)
    var album: Album?
    let albumCheck: Album? = {
        let fetch_req = NSFetchRequest(entityName: "Album")
        let predicate = NSPredicate(format: "name == %@", albumName)
        fetch_req.predicate = predicate
        do {
            let results = try managedContext.executeFetchRequest(fetch_req) as! [Album]
            if (results.count > 0) {
                return results[0]
            } else {
                return nil
            }
            
        } catch {
            print("error: \(error)")
            return nil
        }
    }()
    if albumCheck != nil {
        album = albumCheck!
        for track in tracks! {
            print("old album name: \(track.sort_album)")
            track.album = albumCheck!
            let albumName = albumCheck!.name!
            var sortAlbumName: String
            if albumCheck!.name!.hasPrefix("The ") || albumCheck!.name!.hasPrefix("the ") {
                let range = albumName.startIndex...albumName.startIndex.advancedBy(3)
                sortAlbumName = albumName
                sortAlbumName.removeRange(range)
            }
            else {
                sortAlbumName = albumName
            }
            track.sort_album = sortAlbumName
            print("new album name: \(track.sort_album)")
        }
    } else {
        let new_album = NSEntityDescription.insertNewObjectForEntityForName("Album", inManagedObjectContext: managedContext) as! Album
        new_album.name = albumName
        var sort_album_name: String
        if albumName.hasPrefix("The ") || albumName.hasPrefix("the ") {
            let range = albumName.startIndex...albumName.startIndex.advancedBy(3)
            sort_album_name = albumName
            sort_album_name.removeRange(range)
            print(sort_album_name)
        }
        else {
            sort_album_name = albumName
        }
        for track in tracks! {
            print("old album name: \(track.sort_album)")
            track.album = new_album
            track.sort_album = sort_album_name
            print("new album name: \(track.sort_album)")
        }
        album = new_album
    }
    let artists = tracks!.map( {return $0.artist!} )
    let unique_artists = Array(Set(artists))
    for artist in unique_artists {
        artist.addAlbumsObject(album!)
    }
}

func isGreaterArtist(a: Track, b: Track) -> Bool? {
    if a.artist == nil {
        return false
    }
    if b.artist == nil {
        return true
    }
    let artistComp = a.sort_artist!.localizedStandardCompare(b.sort_artist!)
    switch artistComp {
    case .OrderedSame:
        return isGreaterAlbum(a, b: b)
    case .OrderedAscending:
        return false
    case .OrderedDescending:
        return true
    }
}

func isGreaterAlbum(a: Track, b: Track) -> Bool? {
    if a.album == nil {
        return false
    }
    if b.album == nil {
        return true
    }
    let albumComp = a.sort_album!.localizedStandardCompare(b.sort_album!)
    switch albumComp {
    case .OrderedSame:
        return isGreaterTrackNum(a, b: b)
    case .OrderedAscending:
        return false
    case .OrderedDescending:
        return true
    }
}

func isGreaterTrackNum(a: Track, b: Track) -> Bool? {
    if a.track_num == nil {
        return false
    }
    if b.track_num == nil {
        return true
    }
    let trackNumComp = a.track_num!.compare(b.track_num!)
    switch trackNumComp {
    case .OrderedSame:
        return isGreaterName(a, b: b)
    case .OrderedAscending:
        return false
    case .OrderedDescending:
        return true
    }

}

func isGreaterName(a: Track, b: Track) -> Bool? {
    if a.name == nil {
        return false
    }
    if b.name == nil {
        return true
    }
    let nameComp = a.name!.localizedStandardCompare(b.name!)
    print(b.name!)
    switch nameComp {
    case .OrderedAscending:
        return false
    case .OrderedDescending:
        return true
    case .OrderedSame:
        return nil
    }
}

func isGreaterDateAdded(a: Track, b: Track) -> Bool? {
    if a.date_added == nil {
        return false
    }
    if b.date_added == nil {
        return true
    }
    let dateComp = a.date_added!.compare(b.date_added!)
    switch dateComp {
    case .OrderedAscending:
        return false
    case .OrderedDescending:
        return true
    case .OrderedSame:
        return isGreaterArtist(a, b: b)
    }
}

func isGreaterTime(a: Track, b: Track) -> Bool? {
    if a.time == nil {
        return false
    }
    if b.time == nil {
        return true
    }
    let timeComp = a.time!.compare(b.time!)
    switch timeComp {
    case .OrderedAscending:
        return false
    case .OrderedDescending:
        return true
    case .OrderedSame:
        return isGreaterName(a, b: b)
    }
}

func insert(tracks: NSOrderedSet, track: Track, isGreater: (a: Track, b: Track) -> Bool?) -> Int {
    var high: Int = tracks.count - 1
    var low: Int = 0
    var index: Int
    while (low <= high) {
        index = (low + high) / 2
        let result = isGreater(a: track, b: tracks[index] as! Track)
        if result == true {
            low = index + 1
        }
        else if result == false {
            high = index - 1
        }
        else {
            return index
        }
    }
    return low
}


func reorderForTracks(tracks: [Track], cachedOrder: CachedOrder) {
    print("reordering for tracks for cached order \(cachedOrder.order!)")
    var comparator: ((a: Track, b: Track) -> Bool?)?
    switch cachedOrder.order! {
    case "Artist":
        comparator = isGreaterArtist
    case "Album":
        comparator = isGreaterAlbum
    case "Date Added":
        comparator = isGreaterDateAdded
    case "Name":
        comparator = isGreaterName
    case "Time":
        comparator = isGreaterTime
    default:
        comparator = isGreaterArtist
    }
    let fuckYou = cachedOrder.tracks!.mutableCopy() as! NSMutableOrderedSet
    for track in tracks {
        fuckYou.removeObject(track)
    }
    for track in tracks {
        let index = insert(fuckYou, track: track, isGreater: comparator!)
        fuckYou.insertObject(track, atIndex: index)
    }
    cachedOrder.tracks = fuckYou.copy() as? NSOrderedSet
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






