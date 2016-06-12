//
//  SongCollectionView+CoreDataProperties.swift
//  minimalTunes
//
//  Created by John Moody on 6/8/16.
//  Copyright © 2016 John Moody. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension SongCollectionView {
    
    @NSManaged var title: String?
    @NSManaged var sort_descriptors: NSObject?
    @NSManaged var top_row: NSNumber?
    @NSManaged var selected_rows: NSObject?
    @NSManaged var fetch_predicate: NSObject?
    @NSManaged var filter_predicate: NSObject?
}
