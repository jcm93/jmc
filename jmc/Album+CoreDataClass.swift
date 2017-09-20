//
//  Album+CoreDataClass.swift
//  jmc
//
//  Created by John Moody on 6/3/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


public class Album: NSManagedObject {
    func getMiscellaneousFiles() -> [NSObject] {
        var albumFiles = [NSObject]()
        albumFiles.append(self.primary_art!)
        if let otherArt = self.other_art?.array {
            albumFiles.append(contentsOf: otherArt as! [NSObject])
        }
        if let otherFiles = self.other_files?.allObjects {
            albumFiles.append(contentsOf: otherFiles as! [NSObject])
        }
        return albumFiles.flatMap({return $0})
    }
}
