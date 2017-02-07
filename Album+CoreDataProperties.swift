//
//  Album+CoreDataProperties.swift
//  minimalTunes
//
//  Created by John Moody on 10/26/16.
//  Copyright © 2016 John Moody. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Album {

    @NSManaged var id: NSNumber?
    @NSManaged var name: String?
    @NSManaged var release_date: Date?
    @NSManaged var is_compilation: NSNumber?
    @NSManaged var track_count: NSNumber?
    @NSManaged var disc_count: NSNumber?
    @NSManaged var is_network: NSNumber?
    @NSManaged var album_artist: Artist?
    @NSManaged var other_art: AlbumArtworkCollection?
    @NSManaged var primary_art: AlbumArtwork?
    @NSManaged var properties: Property?
    @NSManaged var tracks: NSSet?

}
