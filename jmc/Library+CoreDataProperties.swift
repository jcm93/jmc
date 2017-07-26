//
//  Library+CoreDataProperties.swift
//  jmc
//
//  Created by John Moody on 7/26/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


extension Library {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Library> {
        return NSFetchRequest<Library>(entityName: "Library")
    }

    @NSManaged public var finds_artwork: NSNumber?
    @NSManaged public var is_active: NSNumber?
    @NSManaged public var is_available: NSNumber?
    @NSManaged public var is_network: NSNumber?
    @NSManaged public var keeps_track_of_files: NSNumber?
    @NSManaged public var last_fs_event: NSNumber?
    @NSManaged public var monitors_directories_for_new: NSNumber?
    @NSManaged public var name: String?
    @NSManaged public var next_album_artwork_collection_id: NSNumber?
    @NSManaged public var next_album_artwork_id: NSNumber?
    @NSManaged public var next_album_id: NSNumber?
    @NSManaged public var next_artist_id: NSNumber?
    @NSManaged public var next_composer_id: NSNumber?
    @NSManaged public var next_genre_id: NSNumber?
    @NSManaged public var next_playlist_id: NSNumber?
    @NSManaged public var next_track_id: NSNumber?
    @NSManaged public var organization_type: NSNumber?
    @NSManaged public var peer: NSObject?
    @NSManaged public var renames_files: NSNumber?
    @NSManaged public var uuid: String?
    @NSManaged public var watch_dirs: NSObject?
    @NSManaged public var last_fm_session_key: String?
    @NSManaged public var last_fm_username: String?
    @NSManaged public var cached_orders: NSSet?
    @NSManaged public var children: NSSet?
    @NSManaged public var local_items: NSOrderedSet?
    @NSManaged public var master_playlist: NSSet?
    @NSManaged public var organization_template: OrganizationTemplateBundle?
    @NSManaged public var parent: Library?
    @NSManaged public var tracks: NSSet?
    @NSManaged public var volumes: NSSet?

}

// MARK: Generated accessors for cached_orders
extension Library {

    @objc(addCached_ordersObject:)
    @NSManaged public func addToCached_orders(_ value: CachedOrder)

    @objc(removeCached_ordersObject:)
    @NSManaged public func removeFromCached_orders(_ value: CachedOrder)

    @objc(addCached_orders:)
    @NSManaged public func addToCached_orders(_ values: NSSet)

    @objc(removeCached_orders:)
    @NSManaged public func removeFromCached_orders(_ values: NSSet)

}

// MARK: Generated accessors for children
extension Library {

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: Library)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: Library)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSSet)

}

// MARK: Generated accessors for local_items
extension Library {

    @objc(insertObject:inLocal_itemsAtIndex:)
    @NSManaged public func insertIntoLocal_items(_ value: SourceListItem, at idx: Int)

    @objc(removeObjectFromLocal_itemsAtIndex:)
    @NSManaged public func removeFromLocal_items(at idx: Int)

    @objc(insertLocal_items:atIndexes:)
    @NSManaged public func insertIntoLocal_items(_ values: [SourceListItem], at indexes: NSIndexSet)

    @objc(removeLocal_itemsAtIndexes:)
    @NSManaged public func removeFromLocal_items(at indexes: NSIndexSet)

    @objc(replaceObjectInLocal_itemsAtIndex:withObject:)
    @NSManaged public func replaceLocal_items(at idx: Int, with value: SourceListItem)

    @objc(replaceLocal_itemsAtIndexes:withLocal_items:)
    @NSManaged public func replaceLocal_items(at indexes: NSIndexSet, with values: [SourceListItem])

    @objc(addLocal_itemsObject:)
    @NSManaged public func addToLocal_items(_ value: SourceListItem)

    @objc(removeLocal_itemsObject:)
    @NSManaged public func removeFromLocal_items(_ value: SourceListItem)

    @objc(addLocal_items:)
    @NSManaged public func addToLocal_items(_ values: NSOrderedSet)

    @objc(removeLocal_items:)
    @NSManaged public func removeFromLocal_items(_ values: NSOrderedSet)

}

// MARK: Generated accessors for master_playlist
extension Library {

    @objc(addMaster_playlistObject:)
    @NSManaged public func addToMaster_playlist(_ value: SongCollection)

    @objc(removeMaster_playlistObject:)
    @NSManaged public func removeFromMaster_playlist(_ value: SongCollection)

    @objc(addMaster_playlist:)
    @NSManaged public func addToMaster_playlist(_ values: NSSet)

    @objc(removeMaster_playlist:)
    @NSManaged public func removeFromMaster_playlist(_ values: NSSet)

}

// MARK: Generated accessors for tracks
extension Library {

    @objc(addTracksObject:)
    @NSManaged public func addToTracks(_ value: Track)

    @objc(removeTracksObject:)
    @NSManaged public func removeFromTracks(_ value: Track)

    @objc(addTracks:)
    @NSManaged public func addToTracks(_ values: NSSet)

    @objc(removeTracks:)
    @NSManaged public func removeFromTracks(_ values: NSSet)

}

// MARK: Generated accessors for volumes
extension Library {

    @objc(addVolumesObject:)
    @NSManaged public func addToVolumes(_ value: Volume)

    @objc(removeVolumesObject:)
    @NSManaged public func removeFromVolumes(_ value: Volume)

    @objc(addVolumes:)
    @NSManaged public func addToVolumes(_ values: NSSet)

    @objc(removeVolumes:)
    @NSManaged public func removeFromVolumes(_ values: NSSet)

}
