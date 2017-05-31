//
//  AlbumArtwork+CoreDataProperties.swift
//  jmc
//
//  Created by John Moody on 5/31/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


extension AlbumArtwork {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AlbumArtwork> {
        return NSFetchRequest<AlbumArtwork>(entityName: "AlbumArtwork")
    }

    @NSManaged public var art_name: String?
    @NSManaged public var artwork_location: String?
    @NSManaged public var id: NSNumber?
    @NSManaged public var image_hash: String?
    @NSManaged public var is_network: NSNumber?
    @NSManaged public var album: Album?
    @NSManaged public var album_multiple: Album?

}
