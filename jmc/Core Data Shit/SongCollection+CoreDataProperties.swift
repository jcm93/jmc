//
//  SongCollection+CoreDataProperties.swift
//  jmc
//
//  Created by John Moody on 5/31/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


extension SongCollection {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SongCollection> {
        return NSFetchRequest<SongCollection>(entityName: "SongCollection")
    }

    @NSManaged public var id: NSNumber?
    @NSManaged public var is_network: NSNumber?
    @NSManaged public var is_smart: NSNumber?
    @NSManaged public var name: String?
    @NSManaged public var if_master_library: Library?
    @NSManaged public var if_master_list_item: SourceListItem?
    @NSManaged public var list_item: SourceListItem?
    @NSManaged public var smart_criteria: SmartCriteria?
    @NSManaged public var tracks: NSOrderedSet?

}

// MARK: Generated accessors for tracks
extension SongCollection {

    @objc(insertObject:inTracksAtIndex:)
    @NSManaged public func insertIntoTracks(_ value: TrackView, at idx: Int)

    @objc(removeObjectFromTracksAtIndex:)
    @NSManaged public func removeFromTracks(at idx: Int)

    @objc(insertTracks:atIndexes:)
    @NSManaged public func insertIntoTracks(_ values: [TrackView], at indexes: NSIndexSet)

    @objc(removeTracksAtIndexes:)
    @NSManaged public func removeFromTracks(at indexes: NSIndexSet)

    @objc(replaceObjectInTracksAtIndex:withObject:)
    @NSManaged public func replaceTracks(at idx: Int, with value: TrackView)

    @objc(replaceTracksAtIndexes:withTracks:)
    @NSManaged public func replaceTracks(at indexes: NSIndexSet, with values: [TrackView])

    @objc(addTracksObject:)
    @NSManaged public func addToTracks(_ value: TrackView)

    @objc(removeTracksObject:)
    @NSManaged public func removeFromTracks(_ value: TrackView)

    @objc(addTracks:)
    func addToTracks(_ values: [Any]) {
        let currentTracks = self.tracks?.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
        currentTracks.addObjects(from: values)
    }

    @objc(removeTracks:)
    @NSManaged public func removeFromTracks(_ values: NSOrderedSet)

}
