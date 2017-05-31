//
//  Composer+CoreDataProperties.swift
//  jmc
//
//  Created by John Moody on 5/31/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


extension Composer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Composer> {
        return NSFetchRequest<Composer>(entityName: "Composer")
    }

    @NSManaged public var id: NSNumber?
    @NSManaged public var is_network: NSNumber?
    @NSManaged public var name: String?
    @NSManaged public var artists: NSSet?
    @NSManaged public var tracks: NSSet?

}

// MARK: Generated accessors for artists
extension Composer {

    @objc(addArtistsObject:)
    @NSManaged public func addToArtists(_ value: Artist)

    @objc(removeArtistsObject:)
    @NSManaged public func removeFromArtists(_ value: Artist)

    @objc(addArtists:)
    @NSManaged public func addToArtists(_ values: NSSet)

    @objc(removeArtists:)
    @NSManaged public func removeFromArtists(_ values: NSSet)

}

// MARK: Generated accessors for tracks
extension Composer {

    @objc(addTracksObject:)
    @NSManaged public func addToTracks(_ value: Track)

    @objc(removeTracksObject:)
    @NSManaged public func removeFromTracks(_ value: Track)

    @objc(addTracks:)
    @NSManaged public func addToTracks(_ values: NSSet)

    @objc(removeTracks:)
    @NSManaged public func removeFromTracks(_ values: NSSet)

}
