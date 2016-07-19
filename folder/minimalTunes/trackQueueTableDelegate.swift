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
    var tableView: NSTableView?
    
    var currentContext: String?
    var currentTrackIndex: Int?
    
    
    func changeCurrentTrack(track: Track, context: String) {
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
            let newCurrentTrackView = TrackQueueView()
            newCurrentTrackView.viewType = .currentTrack
            newCurrentTrackView.track = track
            trackQueue.insert(newCurrentTrackView, atIndex: currentTrackIndex!)
        }
        tableView?.reloadData()
    }
    
    func addTrackToQueue(track: Track, context: String) {
        let newFutureTrackView = TrackQueueView()
        newFutureTrackView.viewType = .futureTrack
        newFutureTrackView.track = track
        trackQueue.removeLast()
        trackQueue.append(newFutureTrackView)
        let newSourceView = TrackQueueView()
        newSourceView.source = context
        newSourceView.viewType = .source
        trackQueue.append(newSourceView)
        tableView?.reloadData()
    }
    
    func nextTrack() {
        (trackQueue[currentTrackIndex!]).viewType = .pastTrack
        currentTrackIndex! += 1
        trackQueue[currentTrackIndex!].viewType = .currentTrack
        tableView?.reloadData()
    }
    
    
    func swapTracks(a: Int, b: Int) {
        
    }
    
    
    func updateContext() {
        
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return trackQueue.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        //uses cell.subviews[x] because IB can't connect outlets from elements to nstablecellview subclasses using .xibs, apparently
        let object = trackQueue[row]
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
                (result.subviews[1] as! NSTextField).stringValue = object.track!.name!
                var artist_aa_string = ""
                if object.track!.artist != nil {
                    artist_aa_string += object.track!.artist!.name!
                }
                if object.track!.album != nil {
                    artist_aa_string += " - " + object.track!.album!.name!
                }
                (result.subviews[2] as! NSTextField).stringValue = artist_aa_string
                return result
            case .currentTrack:
                let result = tableView.makeViewWithIdentifier("futureTrack", owner: nil) as! TrackNameTableCell
                (result.subviews[1] as! NSTextField).stringValue = object.track!.name!
                var artist_aa_string = ""
                if object.track!.artist != nil {
                    artist_aa_string += object.track!.artist!.name!
                }
                if object.track!.album != nil {
                    artist_aa_string += " - " + object.track!.album!.name!
                }
                (result.subviews[2] as! NSTextField).stringValue = artist_aa_string
                return result
            case .source:
                let result = tableView.makeViewWithIdentifier("source", owner: nil) as! FromSourceCell
                (result.subviews[1] as! NSTextField).stringValue = object.source!
                return result
            case .futureTrack:
                let result = tableView.makeViewWithIdentifier("futureTrack", owner: nil) as! TrackNameTableCell
                (result.subviews[1] as! NSTextField).stringValue = object.track!.name!
                var artist_aa_string = ""
                if object.track!.artist != nil {
                    artist_aa_string += object.track!.artist!.name!
                }
                if object.track!.album != nil {
                    artist_aa_string += " - " + object.track!.album!.name!
                }
                (result.subviews[2] as! NSTextField).stringValue = artist_aa_string
                return result
            }
        }
    }
}
