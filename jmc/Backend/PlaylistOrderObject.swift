//
//  PlaylistOrderObject.swift
//  jmc
//
//  Created by John Moody on 3/25/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

public class PlaylistOrderObject: NSObject, NSCoding {
    
    var shuffled_play_order: [Int]?
    var current_play_order: [Int]?
    var sourceListItem: SourceListItem
    var inorderNeedsUpdate: Bool?
    
    init(sli: SourceListItem) {
        self.sourceListItem = sli
    }
    
    func libraryStatusNeedsUpdate() {
        let viewController = self.sourceListItem.tableViewController
        let volumes = Set((viewController?.trackViewArrayController.arrangedObjects as! [TrackView]).flatMap({return $0.track!.volume}))
        var count = 0
        var missingVolumes = [Volume]()
        for volume in volumes {
            if !volumeIsAvailable(volume: volume) {
                count += 1
                missingVolumes.append(volume)
            }
        }
        for volume in missingVolumes {
            let IDs = Set((volume.tracks as! Set<Track>).map({return Int($0.id!)}))
            self.current_play_order = self.current_play_order!.filter({return !IDs.contains($0)})
        }
        if count > 0 {
            DispatchQueue.main.async {
                viewController?.mainWindowController?.sourceListViewController?.reloadData()
            }
        }
    }
    
    public func encode(with aCoder: NSCoder) {
        if let shuffled_play_order = self.shuffled_play_order {
            aCoder.encode(shuffled_play_order, forKey: "shuffled_play_order")
        }
        if let current_play_order = self.current_play_order {
            aCoder.encode(current_play_order, forKey: "current_play_order")
        }
        if let inorderNeedsUpdate = self.inorderNeedsUpdate {
            aCoder.encode(inorderNeedsUpdate, forKey: "inorderNeedsUpdate")
        }
        aCoder.encode(self.sourceListItem.objectID.uriRepresentation(), forKey: "sourceListItem")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        if let spo = aDecoder.decodeObject(forKey: "shuffled_play_order") as? [Int] {
            self.shuffled_play_order = spo
        }
        if let cpo = aDecoder.decodeObject(forKey: "current_play_order") as? [Int] {
            self.current_play_order = cpo
        }
        if let inu = aDecoder.decodeObject(forKey: "inorderNeedsUpdate") as? Bool {
            self.inorderNeedsUpdate = inu
        }
        if let sourceListURI = aDecoder.decodeObject(forKey: "sourceListItem") as? URL {
            if let managedObjectID = privateQueueParentContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: sourceListURI) {
                if let sli = privateQueueParentContext.object(with: managedObjectID) as? SourceListItem {
                    self.sourceListItem = sli
                    return
                }
            }
        }
        return nil
    }
}
