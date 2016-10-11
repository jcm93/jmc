//
//  Track.swift
//  minimalTunes
//
//  Created by John Moody on 7/14/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Foundation
import CoreData


class Track: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    @NSManaged func addOrdersObject(order: CachedOrder)
    
    func dictRepresentation() -> NSMutableDictionary {
        let dict = NSMutableDictionary()
        dict["id"] = self.id
        dict["name"] = self.name
        dict["artist_name"] = self.artist?.name
        dict["album_name"] = self.album?.name
        dict["time"] = self.time
        return dict
    }
    /*
 @NSManaged var bit_rate: NSNumber?
 @NSManaged var comments: String?
 @NSManaged var date_added: NSDate?
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
 @NSManaged var orders: NSSet?*/
}
