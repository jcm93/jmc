//
//  PlaylistOrderObject.swift
//  jmc
//
//  Created by John Moody on 3/25/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class PlaylistOrderObject: Equatable, Hashable {
    
    var shuffled_play_order: [Int]?
    var current_play_order: [Int]?
    var sourceListItem: SourceListItem
    var inorderNeedsUpdate: Bool?
    
    init(sli: SourceListItem) {
        self.sourceListItem = sli
    }
    
    var hashValue: Int {
        get {
            return self.sourceListItem.hashValue
        }
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
}

func ==(lpoo: PlaylistOrderObject, rpoo: PlaylistOrderObject) -> Bool {
    return lpoo.sourceListItem == rpoo.sourceListItem
}
