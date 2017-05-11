//
//  Artist+CoreDataProperties.swift
//  jmc
//
//  Created by John Moody on 5/11/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


extension Artist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Artist> {
        return NSFetchRequest<Artist>(entityName: "Artist")
    }

    @NSManaged public var id: NSNumber?
    @NSManaged public var is_network: NSNumber?
    @NSManaged public var name: String?
    @NSManaged public var albums: NSSet?
    @NSManaged public var composers: NSSet?
    @NSManaged public var properties: Property?
    @NSManaged public var tracks: NSSet?

}

// MARK: Generated accessors for albums
extension Artist {

    @objc(addAlbumsObject:)
    @NSManaged public func addToAlbums(_ value: Album)

    @objc(removeAlbumsObject:)
    @NSManaged public func removeFromAlbums(_ value: Album)

    @objc(addAlbums:)
    @NSManaged public func addToAlbums(_ values: NSSet)

    @objc(removeAlbums:)
    @NSManaged public func removeFromAlbums(_ values: NSSet)

}

// MARK: Generated accessors for composers
extension Artist {

    @objc(addComposersObject:)
    @NSManaged public func addToComposers(_ value: Composer)

    @objc(removeComposersObject:)
    @NSManaged public func removeFromComposers(_ value: Composer)

    @objc(addComposers:)
    @NSManaged public func addToComposers(_ values: NSSet)

    @objc(removeComposers:)
    @NSManaged public func removeFromComposers(_ values: NSSet)

}

// MARK: Generated accessors for tracks
extension Artist {

    @objc(addTracksObject:)
    @NSManaged public func addToTracks(_ value: Track)

    @objc(removeTracksObject:)
    @NSManaged public func removeFromTracks(_ value: Track)

    @objc(addTracks:)
    @NSManaged public func addToTracks(_ values: NSSet)

    @objc(removeTracks:)
    @NSManaged public func removeFromTracks(_ values: NSSet)

}
