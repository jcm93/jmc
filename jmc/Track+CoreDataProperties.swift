//
//  Track+CoreDataProperties.swift
//  jmc
//
//  Created by John Moody on 6/8/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


extension Track {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Track> {
        return NSFetchRequest<Track>(entityName: "Track")
    }

    @NSManaged public var bit_rate: NSNumber?
    @NSManaged public var bpm: NSNumber?
    @NSManaged public var comments: String?
    @NSManaged public var date_added: NSDate?
    @NSManaged public var date_last_played: NSDate?
    @NSManaged public var date_last_skipped: NSDate?
    @NSManaged public var date_modified: NSDate?
    @NSManaged public var disc_number: NSNumber?
    @NSManaged public var equalizer_preset: String?
    @NSManaged public var file_kind: String?
    @NSManaged public var genre: String?
    @NSManaged public var id: NSNumber?
    @NSManaged public var is_network: NSNumber?
    @NSManaged public var is_playing: NSNumber?
    @NSManaged public var location: String?
    @NSManaged public var misc_search_field: String?
    @NSManaged public var movement_name: String?
    @NSManaged public var movement_number: NSNumber?
    @NSManaged public var name: String?
    @NSManaged public var play_count: NSNumber?
    @NSManaged public var rating: NSNumber?
    @NSManaged public var sample_rate: NSNumber?
    @NSManaged public var size: NSNumber?
    @NSManaged public var skip_count: NSNumber?
    @NSManaged public var sort_album: String?
    @NSManaged public var sort_album_artist: String?
    @NSManaged public var sort_artist: String?
    @NSManaged public var sort_composer: String?
    @NSManaged public var sort_name: String?
    @NSManaged public var status: NSNumber?
    @NSManaged public var time: NSNumber?
    @NSManaged public var track_num: NSNumber?
    @NSManaged public var album: Album?
    @NSManaged public var artist: Artist?
    @NSManaged public var composer: Composer?
    @NSManaged public var library: Library?
    @NSManaged public var view: TrackView?
    @NSManaged public var volume: Volume?

}
