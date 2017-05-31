//
//  CachedOrder+CoreDataProperties.swift
//  jmc
//
//  Created by John Moody on 5/31/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


extension CachedOrder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedOrder> {
        return NSFetchRequest<CachedOrder>(entityName: "CachedOrder")
    }

    @NSManaged public var is_network: NSNumber?
    @NSManaged public var needs_update: NSNumber?
    @NSManaged public var order: String?
    @NSManaged public var filtered_track_views: NSOrderedSet?
    @NSManaged public var library: Library?
    @NSManaged public var track_views: NSOrderedSet?

}

// MARK: Generated accessors for filtered_track_views
extension CachedOrder {

    @objc(insertObject:inFiltered_track_viewsAtIndex:)
    @NSManaged public func insertIntoFiltered_track_views(_ value: TrackView, at idx: Int)

    @objc(removeObjectFromFiltered_track_viewsAtIndex:)
    @NSManaged public func removeFromFiltered_track_views(at idx: Int)

    @objc(insertFiltered_track_views:atIndexes:)
    @NSManaged public func insertIntoFiltered_track_views(_ values: [TrackView], at indexes: NSIndexSet)

    @objc(removeFiltered_track_viewsAtIndexes:)
    @NSManaged public func removeFromFiltered_track_views(at indexes: NSIndexSet)

    @objc(replaceObjectInFiltered_track_viewsAtIndex:withObject:)
    @NSManaged public func replaceFiltered_track_views(at idx: Int, with value: TrackView)

    @objc(replaceFiltered_track_viewsAtIndexes:withFiltered_track_views:)
    @NSManaged public func replaceFiltered_track_views(at indexes: NSIndexSet, with values: [TrackView])

    @objc(addFiltered_track_viewsObject:)
    @NSManaged public func addToFiltered_track_views(_ value: TrackView)

    @objc(removeFiltered_track_viewsObject:)
    @NSManaged public func removeFromFiltered_track_views(_ value: TrackView)

    @objc(addFiltered_track_views:)
    @NSManaged public func addToFiltered_track_views(_ values: NSOrderedSet)

    @objc(removeFiltered_track_views:)
    @NSManaged public func removeFromFiltered_track_views(_ values: NSOrderedSet)

}

// MARK: Generated accessors for track_views
extension CachedOrder {

    @objc(insertObject:inTrack_viewsAtIndex:)
    @NSManaged public func insertIntoTrack_views(_ value: TrackView, at idx: Int)

    @objc(removeObjectFromTrack_viewsAtIndex:)
    @NSManaged public func removeFromTrack_views(at idx: Int)

    @objc(insertTrack_views:atIndexes:)
    @NSManaged public func insertIntoTrack_views(_ values: [TrackView], at indexes: NSIndexSet)

    @objc(removeTrack_viewsAtIndexes:)
    @NSManaged public func removeFromTrack_views(at indexes: NSIndexSet)

    @objc(replaceObjectInTrack_viewsAtIndex:withObject:)
    @NSManaged public func replaceTrack_views(at idx: Int, with value: TrackView)

    @objc(replaceTrack_viewsAtIndexes:withTrack_views:)
    @NSManaged public func replaceTrack_views(at indexes: NSIndexSet, with values: [TrackView])

    @objc(addTrack_viewsObject:)
    @NSManaged public func addToTrack_views(_ value: TrackView)

    @objc(removeTrack_viewsObject:)
    @NSManaged public func removeFromTrack_views(_ value: TrackView)

    @objc(addTrack_views:)
    @NSManaged public func addToTrack_views(_ values: NSOrderedSet)

    @objc(removeTrack_views:)
    @NSManaged public func removeFromTrack_views(_ values: NSOrderedSet)

}
