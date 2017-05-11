//
//  Album+CoreDataProperties.swift
//  jmc
//
//  Created by John Moody on 5/11/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


extension Album {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Album> {
        return NSFetchRequest<Album>(entityName: "Album")
    }

    @NSManaged public var disc_count: NSNumber?
    @NSManaged public var id: NSNumber?
    @NSManaged public var is_compilation: NSNumber?
    @NSManaged public var is_network: NSNumber?
    @NSManaged public var name: String?
    @NSManaged public var release_date: NSDate?
    @NSManaged public var track_count: NSNumber?
    @NSManaged public var album_artist: Artist?
    @NSManaged public var other_art: AlbumArtworkCollection?
    @NSManaged public var primary_art: AlbumArtwork?
    @NSManaged public var properties: Property?
    @NSManaged public var tracks: NSSet?

}

// MARK: Generated accessors for tracks
extension Album {

    @objc(addTracksObject:)
    @NSManaged public func addToTracks(_ value: Track)

    @objc(removeTracksObject:)
    @NSManaged public func removeFromTracks(_ value: Track)

    @objc(addTracks:)
    @NSManaged public func addToTracks(_ values: NSSet)

    @objc(removeTracks:)
    @NSManaged public func removeFromTracks(_ values: NSSet)

}
