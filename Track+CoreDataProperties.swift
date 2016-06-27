//
//  Track+CoreDataProperties.swift
//  minimalTunes
//
//  Created by John Moody on 6/22/16.
//  Copyright © 2016 John Moody. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Track {

    @NSManaged var album_sort_order: NSNumber?
    @NSManaged var artist_sort_order: NSNumber?
    @NSManaged var bit_rate: NSNumber?
    @NSManaged var comments: String?
    @NSManaged var date_added: NSDate?
    @NSManaged var date_added_sort_order: NSNumber?
    @NSManaged var date_last_played: NSDate?
    @NSManaged var date_last_skipped: NSDate?
    @NSManaged var date_modified: NSDate?
    @NSManaged var file_kind: String?
    @NSManaged var id: NSNumber?
    @NSManaged var location: String?
    @NSManaged var misc_search_field: String?
    @NSManaged var name: String?
    @NSManaged var play_count: NSNumber?
    @NSManaged var rating: NSNumber?
    @NSManaged var sample_rate: NSNumber?
    @NSManaged var size: NSNumber?
    @NSManaged var skip_count: NSNumber?
    @NSManaged var sort_album: String?
    @NSManaged var sort_artist: String?
    @NSManaged var sort_name: String?
    @NSManaged var status: NSNumber?
    @NSManaged var time: NSNumber?
    @NSManaged var track_num: NSNumber?
    @NSManaged var album: Album?
    @NSManaged var artist: Artist?
    @NSManaged var composer: Composer?
    @NSManaged var genre: Genre?
    @NSManaged var playlists: NSSet?
    @NSManaged var user_defined_properties: NSSet?

}
