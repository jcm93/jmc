//
//  NetworkTrack+CoreDataProperties.swift
//  
//
//  Created by John Moody on 10/3/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension NetworkTrack {

    @NSManaged var name: String?
    @NSManaged var album_name: String?
    @NSManaged var artist_name: String?
    @NSManaged var id: NSNumber?
    @NSManaged var time: NSNumber?
    @NSManaged var playlist: NSSet?

}
