//
//  SourceListItem+CoreDataProperties.swift
//  minimalTunes
//
//  Created by John Moody on 7/14/16.
//  Copyright © 2016 John Moody. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension SourceListItem {

    @NSManaged var is_header: NSNumber?
    @NSManaged var name: String?
    @NSManaged var sort_order: NSNumber?
    @NSManaged var children: NSSet?
    @NSManaged var library: Library?
    @NSManaged var master_playlist: SongCollection?
    @NSManaged var network_library: SharedLibrary?
    @NSManaged var parent: SourceListItem?
    @NSManaged var playlist: SongCollection?
    @NSManaged var playlist_folder: SongCollectionFolder?

}
