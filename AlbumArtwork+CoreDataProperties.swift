//
//  AlbumArtwork+CoreDataProperties.swift
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

extension AlbumArtwork {

    @NSManaged var artwork_location: String?
    @NSManaged var image_hash: NSNumber?
    @NSManaged var id: NSNumber?
    @NSManaged var is_network: NSNumber?
    @NSManaged var collection: AlbumArtworkCollection?
    @NSManaged var primary_album: Album?

}
