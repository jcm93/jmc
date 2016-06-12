//
//  AlbumArtworkCollection+CoreDataProperties.swift
//  minimalTunes
//
//  Created by John Moody on 6/9/16.
//  Copyright © 2016 John Moody. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension AlbumArtworkCollection {

    @NSManaged var album_name: String?
    @NSManaged var primary_art: NSManagedObject?
    @NSManaged var other_art: NSSet?

}
