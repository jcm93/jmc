//
//  Album+CoreDataProperties.swift
//  jmc
//
//  Created by John Moody on 6/3/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


extension Album {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Album> {
        return NSFetchRequest<Album>(entityName: "Album")
    }

    @NSManaged public var disc_count: NSNumber?
    @NSManaged public var id: NSNumber?
    @NSManaged public var is_compilation: NSNumber?
    @NSManaged public var is_network: NSNumber?
    @NSManaged public var name: String?
    @NSManaged public var release_date: JMDate?
    @NSManaged public var track_count: NSNumber?
    @NSManaged public var album_artist: Artist?
    @NSManaged public var other_art: NSOrderedSet?
    @NSManaged public var primary_art: AlbumArtwork?
    @NSManaged public var tracks: NSSet?
    @NSManaged public var other_files: NSSet?
    @NSManaged public var sort_name: String?

}

// MARK: Generated accessors for other_art
extension Album {

    @objc(insertObject:inOther_artAtIndex:)
    @NSManaged public func insertIntoOther_art(_ value: AlbumArtwork, at idx: Int)

    @objc(removeObjectFromOther_artAtIndex:)
    @NSManaged public func removeFromOther_art(at idx: Int)

    @objc(insertOther_art:atIndexes:)
    @NSManaged public func insertIntoOther_art(_ values: [AlbumArtwork], at indexes: NSIndexSet)

    @objc(removeOther_artAtIndexes:)
    @NSManaged public func removeFromOther_art(at indexes: NSIndexSet)

    @objc(replaceObjectInOther_artAtIndex:withObject:)
    @NSManaged public func replaceOther_art(at idx: Int, with value: AlbumArtwork)

    @objc(replaceOther_artAtIndexes:withOther_art:)
    @NSManaged public func replaceOther_art(at indexes: NSIndexSet, with values: [AlbumArtwork])

    @objc(addOther_artObject:)
    func addToOther_art(_ value: AlbumArtwork) {
        let currentOtherArt = self.other_art?.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
        currentOtherArt.add(value)
        self.other_art = currentOtherArt as NSOrderedSet
    }

    @objc(removeOther_artObject:)
    @NSManaged public func removeFromOther_art(_ value: AlbumArtwork)

    @objc(addOther_art:)
    func addToOther_art(_ values: [Any]) {
        let currentOtherArt = self.other_art?.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
        currentOtherArt.addObjects(from: values)
        self.other_art = currentOtherArt as NSOrderedSet
    }

    @objc(removeOther_art:)
    @NSManaged public func removeFromOther_art(_ values: NSOrderedSet)

}

// MARK: Generated accessors for tracks
extension Album {

    @objc(addTracksObject:)
    @NSManaged public func addToTracks(_ value: Track)

    @objc(removeTracksObject:)
    @NSManaged public func removeFromTracks(_ value: Track)

    @objc(addTracks:)
    @NSManaged public func addToTracks(_ values: NSSet)

    @objc(removeTracks:)
    @NSManaged public func removeFromTracks(_ values: NSSet)

}

// MARK: Generated accessors for other_files
extension Album {

    @objc(addOther_filesObject:)
    func addToOther_files(_ value: AlbumFile) {
        let currentOtherFiles = self.other_files?.mutableCopy() as? NSMutableSet ?? NSMutableSet()
        currentOtherFiles.add(value)
        self.other_files = currentOtherFiles as NSSet
    }

    @objc(removeOther_filesObject:)
    @NSManaged public func removeFromOther_files(_ value: AlbumFile)

    @objc(addOther_files:)
    func addToOther_files(_ values: NSSet) {
        let currentOtherFiles = self.other_files?.mutableCopy() as? NSMutableSet ?? NSMutableSet()
        currentOtherFiles.addObjects(from: values.allObjects)
        self.other_files = currentOtherFiles as NSSet
    }

    @objc(removeOther_files:)
    @NSManaged public func removeFromOther_files(_ values: NSSet)

}
