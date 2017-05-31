//
//  Track+CoreDataClass.swift
//  jmc
//
//  Created by John Moody on 5/31/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


public class Track: NSManagedObject {
    
    // Insert code here to add functionality to your managed object subclass
    
    func dictRepresentation(_ fields: [String]) -> NSDictionary {
        let dict = NSMutableDictionary()
        let dateFormatter = DateFormatter()
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
                    dict["date_added"] = dateFormatter.string(from: self.date_added! as Date)
                    dict["date_added_order"] = self.view?.date_added_order
                }
            case "date_modified":
                if self.date_modified != nil {
                    dict["date_modified"] = dateFormatter.string(from: self.date_modified! as Date)
                }
            case "date_released":
                if self.album?.release_date != nil {
                    dict["date_released"] = dateFormatter.string(from: self.album!.release_date! as Date)
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
                dict["genre"] = self.genre
                dict["genre_order"] = self.view?.genre_order
            case "file_kind":
                dict["file_kind"] = self.file_kind
                dict["kind_order"] = self.view?.kind_order
            case "date_last_played":
                if self.date_last_played != nil {
                    dict["date_last_played"] = dateFormatter.string(from: self.date_last_played! as Date)
                }
            case "date_last_skipped":
                if self.date_last_skipped != nil {
                    dict["date_last_skipped"] = dateFormatter.string(from: self.date_last_skipped! as Date)
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
}
