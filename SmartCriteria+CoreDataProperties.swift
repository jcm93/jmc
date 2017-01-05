//
//  SmartCriteria+CoreDataProperties.swift
//  minimalTunes
//
//  Created by John Moody on 1/4/17.
//  Copyright © 2017 John Moody. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension SmartCriteria {

    @NSManaged var fetch_limit: NSNumber?
    @NSManaged var fetch_limit_type: String?
    @NSManaged var ordering_criterion: String?
    @NSManaged var predicate: NSObject?
    @NSManaged var playlist: SongCollection?

}
