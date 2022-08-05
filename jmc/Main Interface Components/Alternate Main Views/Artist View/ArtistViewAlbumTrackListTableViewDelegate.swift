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
    var parent: ArtistViewTableCellView!
    var draggedRowIndexes: IndexSet?

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
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        print("table view writerows called")
        let tracks = self.parent.artistViewController.albumsView.getSelectedTrackViews().sorted(by: {return $0.album_artist_order!.isLessThan($1.album_artist_order!)})
        pboard.clearContents()
        pboard.declareTypes([NSPasteboard.PasteboardType(kUTTypeURL as String)], owner: self)
        let rows = NSMutableArray()
        var fileURLs = [NSURL]()
        for track in tracks {
            rows.add(track.track!.objectID.uriRepresentation())
            fileURLs.append(URL(string: track.track!.location!)! as NSURL)
        }
        print("writing urls")
        //pboard.addTypes([NSURLPboardType], owner: nil)
        //TODO fix this is broken
        //pboard.setPropertyList(fileURLs, forType: .URL)
        //pboard.writeObjects(fileURLs)
        //draggedRowIndexes = rowIndexes
        let encodedIDs = NSKeyedArchiver.archivedData(withRootObject: rows)
        let context = self.parent.artistViewController?.mainWindowController?.currentSourceListItem?.name
        print("context is \(context)")
        if context != nil {
            pboard.setString(context!, forType: NSPasteboard.PasteboardType(rawValue: "context"))
        }
        if self.parent.artistViewController?.mainWindowController?.currentSourceListItem?.is_network == true {
            print("settin network pboard data")
            pboard.setData(encodedIDs, forType: NSPasteboard.PasteboardType(rawValue: "NetworkTrack"))
        } else {
            pboard.setData(encodedIDs, forType: NSPasteboard.PasteboardType(rawValue: "Track"))
        }
        return true
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
    
    
    func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        return self.parent.artistViewController.albumsView.selectionHandler.getSelection(forProposedSelection: proposedSelectionIndexes, tableView: tableView, album: self.parent.album!)
    }
    
    /*func tableViewSelectionDidChange(_ notification: Notification) {
        self.tracksArrayController.setSelectionIndexes(self.parent.tracksTableView.selectedRowIndexes)
    }*/
}
