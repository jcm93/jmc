//
//  SourceListItem+CoreDataProperties.swift
//  minimalTunes
//
//  Created by John Moody on 1/5/17.
//  Copyright © 2017 John Moody. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension SourceListItem {

    @NSManaged var is_header: NSNumber?
    @NSManaged var is_network: NSNumber?
    @NSManaged var is_root: NSNumber?
    @NSManaged var name: String?
    @NSManaged var sort_order: NSNumber?
    @NSManaged var is_folder: NSNumber?
    @NSManaged var children: NSOrderedSet?
    @NSManaged var library: Library?
    @NSManaged var master_playlist: SongCollection?
    @NSManaged var parent: SourceListItem?
    @NSManaged var playlist: SongCollection?

}
