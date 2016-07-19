//
//  Album+CoreDataProperties.swift
//  minimalTunes
//
//  Created by John Moody on 7/14/16.
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
    @NSManaged var release_date: NSDate?
    @NSManaged var album_artist: Artist?
    @NSManaged var art: AlbumArtworkCollection?
    @NSManaged var properties: Property?
    @NSManaged var tracks: NSSet?

}
