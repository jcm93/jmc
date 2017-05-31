//
//  TrackView+CoreDataProperties.swift
//  jmc
//
//  Created by John Moody on 5/31/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


extension TrackView {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrackView> {
        return NSFetchRequest<TrackView>(entityName: "TrackView")
    }

    @NSManaged public var album_artist_order: NSNumber?
    @NSManaged public var album_order: NSNumber?
    @NSManaged public var artist_order: NSNumber?
    @NSManaged public var composer_order: NSNumber?
    @NSManaged public var date_added_order: NSNumber?
    @NSManaged public var genre_order: NSNumber?
    @NSManaged public var is_network: NSNumber?
    @NSManaged public var kind_order: NSNumber?
    @NSManaged public var name_order: NSNumber?
    @NSManaged public var playlist_order: NSNumber?
    @NSManaged public var release_date_order: NSNumber?
    @NSManaged public var filtered_orders: NSSet?
    @NSManaged public var orders: NSSet?
    @NSManaged public var other_sort_orders: NSSet?
    @NSManaged public var playlists: NSSet?
    @NSManaged public var track: Track?

}

// MARK: Generated accessors for filtered_orders
extension TrackView {

    @objc(addFiltered_ordersObject:)
    @NSManaged public func addToFiltered_orders(_ value: CachedOrder)

    @objc(removeFiltered_ordersObject:)
    @NSManaged public func removeFromFiltered_orders(_ value: CachedOrder)

    @objc(addFiltered_orders:)
    @NSManaged public func addToFiltered_orders(_ values: NSSet)

    @objc(removeFiltered_orders:)
    @NSManaged public func removeFromFiltered_orders(_ values: NSSet)

}

// MARK: Generated accessors for orders
extension TrackView {

    @objc(addOrdersObject:)
    @NSManaged public func addToOrders(_ value: CachedOrder)

    @objc(removeOrdersObject:)
    @NSManaged public func removeFromOrders(_ value: CachedOrder)

    @objc(addOrders:)
    @NSManaged public func addToOrders(_ values: NSSet)

    @objc(removeOrders:)
    @NSManaged public func removeFromOrders(_ values: NSSet)

}

// MARK: Generated accessors for other_sort_orders
extension TrackView {

    @objc(addOther_sort_ordersObject:)
    @NSManaged public func addToOther_sort_orders(_ value: SortOrder)

    @objc(removeOther_sort_ordersObject:)
    @NSManaged public func removeFromOther_sort_orders(_ value: SortOrder)

    @objc(addOther_sort_orders:)
    @NSManaged public func addToOther_sort_orders(_ values: NSSet)

    @objc(removeOther_sort_orders:)
    @NSManaged public func removeFromOther_sort_orders(_ values: NSSet)

}

// MARK: Generated accessors for playlists
extension TrackView {

    @objc(addPlaylistsObject:)
    @NSManaged public func addToPlaylists(_ value: SongCollection)

    @objc(removePlaylistsObject:)
    @NSManaged public func removeFromPlaylists(_ value: SongCollection)

    @objc(addPlaylists:)
    @NSManaged public func addToPlaylists(_ values: NSSet)

    @objc(removePlaylists:)
    @NSManaged public func removeFromPlaylists(_ values: NSSet)

}
