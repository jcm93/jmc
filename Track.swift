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
    
    func dictRepresentation(fields: [String]) -> NSDictionary {
        let dict = NSMutableDictionary()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        self.view?.album_artist_order
        dict["id"] = self.id
        dict["location"] = self.location
        for field in fields {
            switch field {
            case "is_enabled":
                dict["is_enabled"] = self.status
            case "name":
                dict["name"] = self.name
                dict["name_order"] = self.view?.name_order
            case "time":
                dict["time"] = self.time
            case "artist":
                dict["artist"] = self.artist?.name
                dict["artist_order"] = self.view?.artist_order
            case "album":
                dict["album"] = self.album?.name
                dict["album_order"] = self.view?.album_order
            case "date_added":
                if self.date_added != nil {
                    dict["date_added"] = dateFormatter.stringFromDate(self.date_added!)
                    dict["date_added_order"] = self.view?.date_added_order
                }
            case "date_modified":
                if self.date_modified != nil {
                    dict["date_modified"] = dateFormatter.stringFromDate(self.date_modified!)
                }
            case "date_released":
                if self.album?.release_date != nil {
                    dict["date_released"] = dateFormatter.stringFromDate(self.album!.release_date!)
                    dict["release_date_order"] = self.view?.release_date_order
                }
            case "comments":
                dict["comments"] = self.comments
            case "composer":
                dict["composer"] = self.composer?.name
            case "disc_number":
                dict["disc_number"] = self.disc_number
            case "equalizer_preset":
                dict["equalizer_preset"] = self.equalizer_preset
            case "genre":
                dict["genre"] = self.genre?.name
                dict["genre_order"] = self.view?.genre_order
            case "file_kind":
                dict["file_kind"] = self.file_kind
                dict["kind_order"] = self.view?.kind_order
            case "date_last_played":
                if self.date_last_played != nil {
                    dict["date_last_played"] = dateFormatter.stringFromDate(self.date_last_played!)
                }
            case "date_last_skipped":
                if self.date_last_skipped != nil {
                    dict["date_last_skipped"] = dateFormatter.stringFromDate(self.date_last_skipped!)
                }
            case "movement_name":
                dict["movement_name"] = self.movement_name
            case "movement_number":
                dict["movement_number"] = self.movement_number
            case "play_count":
                dict["play_count"] = self.play_count
            case "rating":
                dict["rating"] = self.rating
            case "bit_rate":
                dict["bit_rate"] = self.bit_rate
            case "sample_rate":
                dict["sample_rate"] = self.sample_rate
            case "size":
                dict["size"] = self.size
            case "skip_count":
                dict["skip_count"] = self.skip_count
            case "sort_album":
                dict["sort_album"] = self.sort_album
            case "sort_album_artist":
                dict["sort_album_artist"] = self.sort_album_artist
                dict["album_artist_order"] = self.view?.album_artist_order
            case "sort_artist":
                dict["sort_artist"] = self.sort_artist
            case "sort_composer":
                dict["sort_composer"] = self.sort_composer
            case "sort_name":
                dict["sort_name"] = self.sort_name
            case "track_num":
                dict["track_num"] = self.track_num
            default:
                break
            }
        }
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
