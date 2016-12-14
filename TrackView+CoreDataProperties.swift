//
//  TrackView+CoreDataProperties.swift
//  minimalTunes
//
//  Created by John Moody on 11/25/16.
//  Copyright © 2016 John Moody. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension TrackView {

    @NSManaged var album_artist_order: NSNumber?
    @NSManaged var album_artist_descending_order: NSNumber?
    @NSManaged var album_order: NSNumber?
    @NSManaged var album_descending_order: NSNumber?
    @NSManaged var artist_order: NSNumber?
    @NSManaged var artist_descending_order: NSNumber?
    @NSManaged var date_added_order: NSNumber?
    @NSManaged var genre_order: NSNumber?
    @NSManaged var is_network: NSNumber?
    @NSManaged var kind_order: NSNumber?
    @NSManaged var name_order: NSNumber?
    @NSManaged var release_date_order: NSNumber?
    @NSManaged var filtered_orders: NSSet?
    @NSManaged var orders: NSSet?
    @NSManaged var other_sort_orders: NSSet?
    @NSManaged var track: Track?
    @NSManaged var playlists: NSSet?
    
}