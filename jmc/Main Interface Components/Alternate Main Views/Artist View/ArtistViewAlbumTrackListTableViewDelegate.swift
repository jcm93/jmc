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
    var tracks: [Track]
    var timeFormatter: TimeFormatter!

    init(album: Album) {
        self.album = album
        self.tracks = (self.album.tracks!.allObjects as! [Track]).sorted(by: {(t1: Track, t2: Track) -> Bool in
            let firstValue = t1.track_num?.intValue ?? 0
            let secondValue = t2.track_num?.intValue ?? 0
            return firstValue < secondValue
            })
        self.timeFormatter = TimeFormatter()
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        switch tableColumn?.identifier.rawValue {
        case "Track":
            return row + 1
        case "Name":
            return self.tracks[row].name
        case "Time":
            return timeFormatter.string(for: self.tracks[row].time)
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
