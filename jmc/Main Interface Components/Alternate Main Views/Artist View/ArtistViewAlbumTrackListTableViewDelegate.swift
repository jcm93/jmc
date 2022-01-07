//
//  ArtistViewAlbumTrackListTableViewDelegate.swift
//  jmc
//
//  Created by John Moody on 12/25/21.
//  Copyright © 2021 John Moody. All rights reserved.
//

import Cocoa

class ArtistViewAlbumTrackListTableViewDelegate: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    
    var album: Album
    var tracks: [TrackView]
    var timeFormatter: TimeFormatter!
    @objc dynamic var tracksArrayController: NSArrayController!

    init(album: Album, tracks: [TrackView]) {
        self.album = album
        self.tracks = tracks.sorted(by: {(t1: TrackView, t2: TrackView) -> Bool in
            let firstValue = t1.track!.track_num?.intValue ?? 0
            let secondValue = t2.track!.track_num?.intValue ?? 0
            return firstValue < secondValue
            })
        self.tracksArrayController = NSArrayController(content: tracks)
        print("array controller stuff added")
        self.timeFormatter = TimeFormatter()
        self.tracksArrayController.sortDescriptors = [NSSortDescriptor(key: "track.track_num", ascending: true)]
        self.tracksArrayController.rearrangeObjects()
    }
    
    func selectTrackViews(_ trackViews: [TrackView]) {
        var objects = [TrackView]()
        for trackView in trackViews {
            if self.album == trackView.track!.album {
                objects.append(trackView)
            }
        }
        self.tracksArrayController.setSelectedObjects(objects)
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        switch tableColumn?.identifier.rawValue {
        case "Track":
            return (self.tracksArrayController.arrangedObjects as! [TrackView])[row].track!.track_num
        case "Name":
            return (self.tracksArrayController.arrangedObjects as! [TrackView])[row].track!.name
        case "Time":
            return timeFormatter.string(for: (self.tracksArrayController.arrangedObjects as! [TrackView])[row].track!.time)
        default:
            return "poop"
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return CGFloat(24)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.tracks.count
    }
}
