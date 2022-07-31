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
    var tracksArrayController: NSArrayController!
    var parent: ArtistViewTableCellView!

    init(album: Album, tracks: [TrackView], parent: ArtistViewTableCellView) {
        self.parent = parent
        self.album = album
        self.tracks = tracks
        self.tracksArrayController = NSArrayController(content: tracks)
        print("array controller stuff added")
        self.timeFormatter = TimeFormatter()
        self.tracksArrayController.sortDescriptors = [NSSortDescriptor(key: "track.disc_number", ascending: true), NSSortDescriptor(key: "track.track_num", ascending: true)]
        self.tracksArrayController.rearrangeObjects()
        super.init()
        self.tracksArrayController.addObserver(self, forKeyPath: "arrangedObjects", options: .new, context: nil)
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
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return EmphasizedTableRowView()
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "arrangedObjects" {
            print("poopy")
        }
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        switch tableColumn?.identifier.rawValue {
        case "Track":
            return (self.tracksArrayController.arrangedObjects as! [TrackView])[row].track!.track_num
        case "Name":
            return (self.tracksArrayController.arrangedObjects as! [TrackView])[row].track!.name
        case "Time":
            return timeFormatter.string(for: (self.tracksArrayController.arrangedObjects as! [TrackView])[row].track!.time)
        case "Is Playing":
            return (self.tracksArrayController.arrangedObjects as! [TrackView])[row].track!.is_playing
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
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        self.tracksArrayController.setSelectionIndexes(self.parent.tracksTableView.selectedRowIndexes)
    }
}
