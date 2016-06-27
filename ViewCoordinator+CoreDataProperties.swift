//
//  ViewCoordinator+CoreDataProperties.swift
//  minimalTunes
//
//  Created by John Moody on 6/22/16.
//  Copyright © 2016 John Moody. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ViewCoordinator {

    @NSManaged var fetch_predicate: NSObject?
    @NSManaged var filter_predicate: NSObject?
    @NSManaged var scroll_location: NSNumber?
    @NSManaged var search_bar_content: String?
    @NSManaged var selected_rows: NSObject?
    @NSManaged var sort_descriptors: NSObject?
    @NSManaged var source_list_item_name: String?

}
