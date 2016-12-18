//
//  Library+CoreDataProperties.swift
//  minimalTunes
//
//  Created by John Moody on 12/16/16.
//  Copyright © 2016 John Moody. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Library {

    @NSManaged var is_network: NSNumber?
    @NSManaged var library_location: String?
    @NSManaged var name: String?
    @NSManaged var uuid: String?
    @NSManaged var peer: NSObject?
    @NSManaged var cached_orders: NSSet?
    @NSManaged var local_items: NSOrderedSet?
    @NSManaged var master_playlist: NSSet?

}
