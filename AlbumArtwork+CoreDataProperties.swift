//
//  AlbumArtwork+CoreDataProperties.swift
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

extension AlbumArtwork {

    @NSManaged var artwork: NSObject?
    @NSManaged var collection_primary: AlbumArtworkCollection?
    @NSManaged var collection_album: AlbumArtworkCollection?

}
