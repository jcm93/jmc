//
//  trackQueueTableDelegate.swift
//  minimalTunes
//
//  Created by John Moody on 6/23/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Foundation
import Cocoa

class TrackNameTableCell: NSTableCellView {}

class NowPlayingCell: NSTableCellView {}

class FutureTrackCell: NSTableCellView {}

class PastTrackCell: NSTableCellView {}

class FromSourceDividerCell: NSTableCellView {}

class FromSourceCell: NSTableCellView {}

class TrackQueueTableViewDelegate: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    
    var trackQueue: [TrackQueueView] = [TrackQueueView]()
    var mainWindowController: MainWindowController?
    var tableView: TableViewYouCanPressSpacebarOn?
    var dragTypes = ["Track", "public.TrackQueueView"]
    
    var currentContext: String?
    var currentTrackIndex: Int?
    var numPastTracks = 0
    var numPastTracksToShow = 3
    var globalOffset = 0
    var showAllTracks = false
    
    func tableView(tableView: NSTableView, writeRowsWithIndexes rowIndexes: NSIndexSet, toPasteboard pboard: NSPasteboard) -> Bool {
        print(rowIndexes)
        print(tableView.numberOfRows)
        if rowIndexes.containsIndex(tableView.numberOfRows - 1) {
            print("not writing rows")
            return false
        }
        else {
            print("writing rows")
            let coded = NSKeyedArchiver.archivedDataWithRootObject(rowIndexes)
            pboard.setData(coded, forType: "public.TrackQueueView")
            return true
        }
    }
    
    func tableView(tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAtPoint screenPoint: NSPoint, forRowIndexes rowIndexes: NSIndexSet) {
        print("dragging session will begin called")
    }
    
    func changeCurrentTrack(track: Track, context: String) {
        print("change current track called")
        if (trackQueue.count == 0) {
            let newCurrentTrackView = TrackQueueView()
            newCurrentTrackView.viewType = .currentTrack
            newCurrentTrackView.track = track
            trackQueue.append(newCurrentTrackView)
            let newSourceView = TrackQueueView()
            newSourceView.source = context
            newSourceView.viewType = .source
            trackQueue.append(newSourceView)
            currentTrackIndex = 0
        }
        else {
            (trackQueue[currentTrackIndex!]).viewType = .pastTrack
            currentTrackIndex! += 1
            numPastTracks += 1
            if numPastTracks >= numPastTracksToShow {
                globalOffset += 1
            }
            let newCurrentTrackView = TrackQueueView()
            newCurrentTrackView.viewType = .currentTrack
            newCurrentTrackView.track = track
            trackQueue.insert(newCurrentTrackView, atIndex: currentTrackIndex!)
        }
        tableView?.reloadData()
    }
    
    func addTrackToQueue(track: Track, context: String, tense: Int) {
        let newFutureTrackView = TrackQueueView()
        if (tense == 0) {
            newFutureTrackView.viewType = .currentTrack
        }
        else {
            newFutureTrackView.viewType = .futureTrack
        }
        newFutureTrackView.track = track
        trackQueue.removeLast()
        trackQueue.append(newFutureTrackView)
        let newSourceView = TrackQueueView()
        newSourceView.source = context
        newSourceView.viewType = .source
        trackQueue.append(newSourceView)
        tableView?.reloadData()
    }
    
    func togglePastTracks() {
        if showAllTracks == true {
            showAllTracks = false
        }
        else if showAllTracks == false {
            showAllTracks = true
        }
        tableView?.reloadData()
    }
    
    func insertTrackInQueue(track: Track, index: Int, context: String) {
        if index < trackQueue.count {
            let newTrackView = TrackQueueView()
            newTrackView.track = track
            newTrackView.source = context
            newTrackView.viewType = .futureTrack
            trackQueue.insert(newTrackView, atIndex: index)
        }
        else {
            addTrackToQueue(track, context: context, tense: 1)
        }
        tableView?.reloadData()
    }
    
    func nextTrack() {
        print("next track in track queue called")
        if currentTrackIndex != nil && trackQueue.count > 0 && (trackQueue[currentTrackIndex! + 1]).viewType == .futureTrack {
            (trackQueue[currentTrackIndex!]).viewType = .pastTrack
            currentTrackIndex! += 1
            numPastTracks += 1
            if numPastTracks >= numPastTracksToShow {
                globalOffset += 1
            }
            if (trackQueue.count > currentTrackIndex! + 1) {
                print("detected queued tracks")
                trackQueue[currentTrackIndex!].viewType = .currentTrack
            }
        }
        else {
            print("callin change current track")
            let track = mainWindowController?.currentTrack
            let context = mainWindowController?.currentAudioSource?.name
            changeCurrentTrack(track!, context: context!)
        }
        tableView?.reloadData()
    }
    
    func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        let actualRow: Int
        switch showAllTracks {
        case true:
            actualRow = row
        default:
            actualRow = row + globalOffset
        }
        if actualRow <= currentTrackIndex! {
            return NSDragOperation.None
        }
        else {
            return NSDragOperation.Every
        }
    }
    
    func makePlaylistFromSelection() {
        let fetch_req = NSFetchRequest(entityName: "SourceListItem")
        let pred = NSPredicate(format: "is_header == %@", NSNumber(bool: true))
        fetch_req.predicate = pred
        var result: [SourceListItem]?
        do {
            result = try mainWindowController?.managedContext.executeFetchRequest(fetch_req) as! [SourceListItem]
        } catch {
            print("error: \(error)")
        }
        result = result?.filter( { $0.name == "Playlists" })
        let newPlaylist = NSEntityDescription.insertNewObjectForEntityForName("SongCollection", inManagedObjectContext: (self.mainWindowController?.managedContext)!) as! SongCollection
        let newPlaylistSourceListItem = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: (self.mainWindowController?.managedContext)!) as! SourceListItem
        var track_id_list = [Int]()
        let select_offset: Int
        switch showAllTracks {
        case true:
            select_offset = 0
        default:
            select_offset = globalOffset
        }
        tableView?.selectedRowIndexes.enumerateIndexesUsingBlock({(index, stop) -> Void in
            let id = self.trackQueue[index + select_offset].track!.id
            track_id_list.append(Int(id!))
            
        })
        newPlaylist.track_id_list = track_id_list
        newPlaylist.list_item = newPlaylistSourceListItem
        newPlaylist.name = "dogie"
        newPlaylistSourceListItem.name = "dogie2"
        newPlaylistSourceListItem.parent = result![0]
        mainWindowController?.sourceListView.reloadData()
    }
    
    func tableView(tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        print("accept drop")
        let actualRow: Int
        switch showAllTracks {
        case true:
            actualRow = row
        default:
            actualRow = row + globalOffset
        }
        if (info.draggingPasteboard().types!.contains("Track")) {
            let thing = info.draggingPasteboard().dataForType("Track")
            let unCodedThing = NSKeyedUnarchiver.unarchiveObjectWithData(thing!) as! NSMutableArray
            let tracks = { () -> [Track] in
                var result = [Track]()
                for trackURI in unCodedThing {
                    let id = managedContext.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(trackURI as! NSURL)
                    result.append(managedContext.objectWithID(id!) as! Track)
                }
                return result
            }()
            for track in tracks {
                insertTrackInQueue(track, index: actualRow, context: "djlkqe")
                mainWindowController?.queue.addTrackToQueue(track, index: actualRow - currentTrackIndex! - 1)
                mainWindowController?.trackQueue.append(track)
            }
        }
        if (info.draggingPasteboard().types!.contains("public.TrackQueueView")) {
            let codedViews = info.draggingPasteboard().dataForType("public.TrackQueueView")
            let rows = NSKeyedUnarchiver.unarchiveObjectWithData(codedViews!) as! NSIndexSet
            var row_offset = 0
            rows.enumerateIndexesUsingBlock({(index, stop) -> Void in
                tableView.moveRowAtIndex(index, toIndex: row + row_offset)
                print(index)
                print(row)
                let actualIndex: Int
                switch self.showAllTracks {
                case true:
                    actualIndex = index
                default:
                    actualIndex = index + self.globalOffset
                }
                swap(&self.trackQueue[actualIndex], &self.trackQueue[actualRow + row_offset])
                self.mainWindowController?.queue.swapTracks(actualIndex - self.currentTrackIndex! - 1, second_index: actualRow + row_offset - self.currentTrackIndex! - 1)
                row_offset += 1
            })

        }
        tableView.reloadData()
        return true
    }
    
    
    func updateContext(name: String) {
        if trackQueue.count > 1 {
            trackQueue.removeLast()
        }
        let newSourceView = TrackQueueView()
        newSourceView.source = name
        newSourceView.viewType = .source
        trackQueue.append(newSourceView)
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        switch showAllTracks {
        case true:
            return trackQueue.count
        default:
            return trackQueue.count - globalOffset
        }
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        //uses cell.subviews[x] because IB can't connect outlets from elements to nstablecellview subclasses using .xibs, apparently
        var object: TrackQueueView
        switch showAllTracks {
        case true:
            object = trackQueue[row]
        default:
            object = trackQueue[row + globalOffset]
        }
        if tableColumn?.identifier == "Is Playing" {
            switch object.viewType! {
            case .currentTrack:
                return tableView.makeViewWithIdentifier("nowPlaying", owner: nil) as! NowPlayingCell
            default:
                return nil
            }
        }
        else {
            switch object.viewType! {
            case .pastTrack:
                let result = tableView.makeViewWithIdentifier("pastTrack", owner: nil) as! PastTrackCell
                (result.subviews[2] as! NSTextField).stringValue = object.track!.name!
                var artist_aa_string = ""
                if object.track!.artist != nil {
                    artist_aa_string += object.track!.artist!.name!
                }
                if object.track!.album != nil {
                    artist_aa_string += " - " + object.track!.album!.name!
                }
                (result.subviews[1] as! NSTextField).stringValue = artist_aa_string
                if object.track!.album?.primary_art != nil {
                    let art = object.track?.album?.primary_art
                    let path = art?.artwork_location!
                    let url = NSURL(string: path!)
                    let image = NSImage(contentsOfURL: url!)
                    (result.subviews[0] as! NSImageView).image = image
                }
                else {
                    (result.subviews[0] as! NSImageView).image = nil
                }
                return result
            case .currentTrack:
                let result = tableView.makeViewWithIdentifier("futureTrack", owner: nil) as! TrackNameTableCell
                (result.subviews[2] as! NSTextField).stringValue = object.track!.name!
                var artist_aa_string = ""
                if object.track!.artist != nil {
                    artist_aa_string += object.track!.artist!.name!
                }
                if object.track!.album != nil {
                    artist_aa_string += " - " + object.track!.album!.name!
                }
                (result.subviews[1] as! NSTextField).stringValue = artist_aa_string
                if object.track!.album?.primary_art != nil {
                    let art = object.track?.album?.primary_art
                    let path = art?.artwork_location!
                    let url = NSURL(string: path!)
                    let image = NSImage(contentsOfURL: url!)
                    (result.subviews[0] as! NSImageView).image = image
                }
                else {
                    (result.subviews[0] as! NSImageView).image = nil
                }
                return result
            case .source:
                let result = tableView.makeViewWithIdentifier("source", owner: nil) as! FromSourceCell
                (result.subviews[1] as! NSTextField).stringValue = object.source!
                return result
            case .futureTrack:
                let result = tableView.makeViewWithIdentifier("futureTrack", owner: nil) as! TrackNameTableCell
                (result.subviews[2] as! NSTextField).stringValue = object.track!.name!
                var artist_aa_string = ""
                if object.track!.artist != nil {
                    artist_aa_string += object.track!.artist!.name!
                }
                if object.track!.album != nil {
                    artist_aa_string += " - " + object.track!.album!.name!
                }
                (result.subviews[1] as! NSTextField).stringValue = artist_aa_string
                if object.track!.album?.primary_art != nil {
                    let art = object.track?.album?.primary_art
                    let path = art?.artwork_location!
                    let url = NSURL(string: path!)
                    let image = NSImage(contentsOfURL: url!)
                    (result.subviews[0] as! NSImageView).image = image
                }
                else {
                    (result.subviews[0] as! NSImageView).image = nil
                }
                return result
            }
        }
    }
}
