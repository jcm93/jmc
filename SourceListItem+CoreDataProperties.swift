//
//  SourceListItem+CoreDataProperties.swift
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

extension SourceListItem {

    @NSManaged var name: String?
    @NSManaged var is_header: NSNumber?
    @NSManaged var sort_order: NSNumber?
    @NSManaged var library: Library?
    @NSManaged var children: NSSet?
    @NSManaged var parent: SourceListItem?
    @NSManaged var playlist: SongCollection?
    @NSManaged var playlist_folder: SongCollectionFolder?
    @NSManaged var network_library: SharedLibrary?
    @NSManaged var master_playlist: SongCollection?

}
