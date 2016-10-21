//
//  NewCachedOrder+CoreDataProperties.swift
//  
//
//  Created by John Moody on 10/20/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension NewCachedOrder {

    @NSManaged var order: String?
    @NSManaged var tracks: NSObject?

}
