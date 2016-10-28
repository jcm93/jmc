//
//  Library+CoreDataProperties.swift
//  minimalTunes
//
//  Created by John Moody on 10/27/16.
//  Copyright © 2016 John Moody. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Library {

    @NSManaged var is_network: NSNumber?
    @NSManaged var name: String?
    @NSManaged var local_items: NSSet?
    @NSManaged var master_playlist: NSSet?
    @NSManaged var cached_orders: NSSet?

}
