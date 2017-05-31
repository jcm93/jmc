//
//  SourceListItem+CoreDataProperties.swift
//  jmc
//
//  Created by John Moody on 5/31/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


extension SourceListItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SourceListItem> {
        return NSFetchRequest<SourceListItem>(entityName: "SourceListItem")
    }

    @NSManaged public var is_folder: NSNumber?
    @NSManaged public var is_header: NSNumber?
    @NSManaged public var is_network: NSNumber?
    @NSManaged public var is_root: NSNumber?
    @NSManaged public var name: String?
    @NSManaged public var sort_order: NSNumber?
    @NSManaged public var children: NSOrderedSet?
    @NSManaged public var library: Library?
    @NSManaged public var master_playlist: SongCollection?
    @NSManaged public var parent: SourceListItem?
    @NSManaged public var playlist: SongCollection?

}

// MARK: Generated accessors for children
extension SourceListItem {

    @objc(insertObject:inChildrenAtIndex:)
    @NSManaged public func insertIntoChildren(_ value: SourceListItem, at idx: Int)

    @objc(removeObjectFromChildrenAtIndex:)
    @NSManaged public func removeFromChildren(at idx: Int)

    @objc(insertChildren:atIndexes:)
    @NSManaged public func insertIntoChildren(_ values: [SourceListItem], at indexes: NSIndexSet)

    @objc(removeChildrenAtIndexes:)
    @NSManaged public func removeFromChildren(at indexes: NSIndexSet)

    @objc(replaceObjectInChildrenAtIndex:withObject:)
    @NSManaged public func replaceChildren(at idx: Int, with value: SourceListItem)

    @objc(replaceChildrenAtIndexes:withChildren:)
    @NSManaged public func replaceChildren(at indexes: NSIndexSet, with values: [SourceListItem])

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: SourceListItem)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: SourceListItem)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSOrderedSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSOrderedSet)

}
