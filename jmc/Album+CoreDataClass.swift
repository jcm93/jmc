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
    func getMiscellaneousFiles() -> [String] {
        var albumFiles = [String?]()
        albumFiles.append(self.primary_art?.artwork_location)
        if let otherArt = self.other_art {
            albumFiles.append(contentsOf: otherArt.map({return ($0 as! AlbumArtwork).artwork_location}))
        }
        if let otherFiles = self.other_files {
            albumFiles.append(contentsOf: otherFiles.map({return ($0 as! AlbumFile).location}))
        }
        return albumFiles.flatMap({return $0})
    }
}
