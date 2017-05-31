//
//  SourceListItem+CoreDataClass.swift
//  jmc
//
//  Created by John Moody on 5/31/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData

public class SourceListItem: NSManagedObject {
    
    // Insert code here to add functionality to your managed object subclass
    
    func dictRepresentation() -> NSMutableDictionary {
        let dict = NSMutableDictionary()
        dict["is_header"] = self.is_header
        dict["name"] = self.name
        dict["sort_order"] = self.sort_order
        dict["id"] = self.playlist?.id
        return dict
    }
    
    var playOrderObject: PlaylistOrderObject?
    var tableViewController: LibraryTableViewController?
}
