//
//  Album+CoreDataProperties.swift
//  jmc
//
//  Created by John Moody on 5/16/17.
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
    @NSManaged public var other_art: NSSet?
    @NSManaged public var primary_art: AlbumArtwork?
    @NSManaged public var properties: Property?
    @NSManaged public var tracks: NSSet?

}

// MARK: Generated accessors for other_art
extension Album {

    @objc(addOther_artObject:)
    @NSManaged public func addToOther_art(_ value: AlbumArtwork)

    @objc(removeOther_artObject:)
    @NSManaged public func removeFromOther_art(_ value: AlbumArtwork)

    @objc(addOther_art:)
    @NSManaged public func addToOther_art(_ values: NSSet)

    @objc(removeOther_art:)
    @NSManaged public func removeFromOther_art(_ values: NSSet)

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
