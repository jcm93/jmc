//
//  SongCollection.swift
//  
//
//  Created by John Moody on 10/3/16.
//
//

import Foundation
import CoreData


class SongCollection: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    @NSManaged func addTracksObject(track: Track)
    @NSManaged func addNetworkTracksObject(track: NetworkTrack)
}
