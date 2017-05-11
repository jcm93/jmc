//
//  TrackQueueViewController.swift
//  minimalTunes
//
//  Created by John Moody on 12/1/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
import MultipeerConnectivity
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


enum TrackQueueViewType {
    case pastTrack
    case currentTrack
    case futureTrack
    case transient
    case source
}

class TrackQueueView: NSObject {
    
    var track: Track?
    var source: String?
    var sourcePlaylistOrder: PlaylistOrderObject?
    var index: Int?
    var viewType: TrackQueueViewType?
    var wasQueuedManually: Bool?
    
}

class TrackNameTableCell: NSTableCellView {
    
}

class NowPlayingCell: NSTableCellView {}

class FutureTrackCell: NSTableCellView {}

class PastTrackCell: NSTableCellView {}

class FromSourceDividerCell: NSTableCellView {}

class FromSourceCell: NSTableCellView {}

class TrackQueueViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    var trackQueue: [TrackQueueView] = [TrackQueueView]()
    var mainWindowController: MainWindowController?
    
    @IBOutlet weak var tableView: TrackQueueTableView!
    
    var dragTypes = ["Track", "public.TrackQueueView"]
    
    @IBOutlet weak var scrollView: NSScrollView!
    var currentContext: String?
    var currentTrackIndex: Int?
    var fileManager = FileManager.default
    var temporaryPooForDragging: PlaylistOrderObject?
    var temporaryPooIndexForDragging: Int?
    var currentAudioSource: SourceListItem?
    var currentSourceListItem: SourceListItem?
    var currentSourceIndex: Int?
    var currentTrack: Track?
    var shuffle: Bool = false
    var activePlayOrders = [PlaylistOrderObject]()
    
    func reloadData() {
        tableView?.reloadData()
    }
    
    func toggleHidden(_ state: Int) {
        switch state {
        case NSOnState:
            tableView?.isHidden = false
        default:
            tableView?.isHidden = true
        }
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        print(rowIndexes)
        print(tableView.numberOfRows)
        if rowIndexes.contains(tableView.numberOfRows - 1) {
            print("not writing rows")
            return false
        }
        else {
            print("writing rows")
            let coded = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
            pboard.setData(coded, forType: "public.TrackQueueView")
            return true
        }
    }
    
    func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet) {
        print("dragging session will begin called")
    }
    
    func changeCurrentTrack(_ track: Track) {
        print("change current track called")
        self.currentAudioSource = self.currentSourceListItem
        if (trackQueue.count == 0) {
            let newCurrentTrackView = TrackQueueView()
            newCurrentTrackView.viewType = .currentTrack
            newCurrentTrackView.track = track
            newCurrentTrackView.wasQueuedManually = true
            newCurrentTrackView.sourcePlaylistOrder = currentAudioSource!.playOrderObject
            trackQueue.append(newCurrentTrackView)
            let newSourceView = TrackQueueView()
            newSourceView.source = currentSourceListItem?.name
            newSourceView.viewType = .source
            trackQueue.append(newSourceView)
            currentTrackIndex = 0
            //currentSourceIndex = 0
        }
        else {
            if currentTrackIndex != nil {
                insertTrackInQueue(track, index: currentTrackIndex! + 1, context: currentSourceListItem!.name!, manually: false)
                /*let newCurrentTrackView = TrackQueueView()
                newCurrentTrackView.viewType = .futureTrack
                newCurrentTrackView.track = track
                trackQueue.insert(newCurrentTrackView, atIndex: currentTrackIndex! + 1)*/
            } else {
                currentTrackIndex = 0
                (trackQueue[currentTrackIndex!]).viewType = .currentTrack
            }
        }
        tableView?.reloadData()
    }
    
    func addTrackToQueue(_ track: Track, context: String, tense: Int, manually: Bool) {
        let newFutureTrackView = TrackQueueView()
        if (tense == 0) {
            newFutureTrackView.viewType = .currentTrack
        }
        else {
            newFutureTrackView.viewType = .futureTrack
        }
        newFutureTrackView.track = track
        if currentSourceListItem != currentAudioSource && manually == true {
            createPlayOrderArray(track, row: nil)
        }
        newFutureTrackView.sourcePlaylistOrder = currentAudioSource!.playOrderObject
        if manually == true {
            newFutureTrackView.wasQueuedManually = true
        }
        if trackQueue.count > 0 {
            trackQueue.removeLast()
        }
        trackQueue.append(newFutureTrackView)
        let newSourceView = TrackQueueView()
        newSourceView.source = context
        newSourceView.viewType = .source
        trackQueue.append(newSourceView)
        tableView!.reloadData()
    }
    
    
    @IBAction func makePlaylistFromTrackQueueSelection(_ sender: AnyObject) {
        makePlaylistFromSelection()
    }
    
    func insertTrackInQueue(_ track: Track, index: Int, context: String, manually: Bool) {
        if index < trackQueue.count {
            let newTrackView = TrackQueueView()
            newTrackView.track = track
            newTrackView.source = context
            newTrackView.viewType = .futureTrack
            newTrackView.sourcePlaylistOrder = currentAudioSource!.playOrderObject
            if manually == true {
                newTrackView.wasQueuedManually = true
            }
            trackQueue.insert(newTrackView, at: index)
        }
        else {
            addTrackToQueue(track, context: context, tense: 1, manually: manually)
        }
        tableView?.reloadData()
    }
    
    func advanceScroll() {
        print("scroll value \(scrollView.verticalScroller?.floatValue)")
        print("minimum value for scrolling to bottom \((tableView.frame.height - 92) / tableView.frame.height)")
        if CGFloat(scrollView!.verticalScroller!.floatValue) >= ((tableView.frame.height - 92) / tableView.frame.height) || tableView.frame.height <= scrollView.frame.height {
            print("scrolling to bottom")
            NSAnimationContext.runAnimationGroup({ $0.allowsImplicitAnimation = true; tableView.scroll(NSPoint(x: 0, y: tableView.frame.height))}, completionHandler: nil)
        } else {
            print("not scrolling to bottom")
        }
    }
    
    func nextTrack() {
        print("next track in track queue called")
        if currentTrackIndex != nil && trackQueue.count > 0 && ((trackQueue[currentTrackIndex! + 1]).viewType == .futureTrack || trackQueue[currentTrackIndex! + 1].viewType == .transient) {
            (trackQueue[currentTrackIndex!]).viewType = .pastTrack
            currentTrackIndex! += 1
            if (trackQueue.count > currentTrackIndex! + 1) {
                print("detected queued tracks")
                trackQueue[currentTrackIndex!].viewType = .currentTrack
                self.currentTrack = trackQueue[currentTrackIndex!].track
            }
        } else {
            if trackQueue.count > 0 {
                currentTrackIndex = 0
                trackQueue[currentTrackIndex!].viewType = .currentTrack
                self.currentTrack = trackQueue[currentTrackIndex!].track
            }
        }
        advanceScroll()
    }
    
    func cleanUp() {
        trackQueue[currentTrackIndex!].viewType = .pastTrack
        self.reloadData()
    }
    
    func uninitializeTrackQueue() {
        trackQueue.remove(at: 0)
        currentTrackIndex = nil
    }
    
    func skipToPreviousTrack() {
        print("skip to previous track called")
        //currently micromanages the MWC queue and the audio module, in spite of better judgement
        if currentTrackIndex != nil {
            if trackQueue.count > 1 {
                if currentTrackIndex! != 0 {
                    print("making tqv transient")
                    trackQueue[currentTrackIndex!].viewType = .transient
                    let track = trackQueue[currentTrackIndex! - 1]
                    self.currentTrack = track.track
                    let newFutureTrack = trackQueue[currentTrackIndex!]
                    newFutureTrack.viewType = .transient
                    trackQueue[currentTrackIndex! - 1].viewType = .currentTrack
                    currentTrackIndex! -= 1
                    mainWindowController?.delegate?.audioModule.currentTrackLocation = track.track?.location
                    mainWindowController?.delegate?.audioModule.skip_backward()
                    notEnablingUndo {
                        self.mainWindowController?.currentTrack?.is_playing = false
                    }
                    mainWindowController?.currentTableViewController?.reloadNowPlayingForTrack(mainWindowController!.currentTrack!)
                    mainWindowController?.currentTrack = track.track
                    mainWindowController?.timer?.invalidate()
                    mainWindowController?.initializeInterfaceForNewTrack()
                    notEnablingUndo {
                        self.mainWindowController?.currentTrack?.is_playing = true
                    }
                    mainWindowController?.currentTableViewController?.reloadNowPlayingForTrack(mainWindowController!.currentTrack!)
                    mainWindowController?.delegate?.audioModule.trackQueue.insert(newFutureTrack.track!, at: 0)
                } else {
                    notEnablingUndo {
                        self.mainWindowController?.currentTrack?.is_playing = false
                    }
                    mainWindowController?.currentTableViewController?.reloadNowPlayingForTrack(mainWindowController!.currentTrack!)
                    mainWindowController?.currentTrack = nil
                    self.currentTrack = nil
                    self.currentAudioSource = nil
                    mainWindowController?.delegate?.audioModule.currentTrackLocation = nil
                    mainWindowController?.delegate?.audioModule.skip_backward()
                    currentTrackIndex = nil
                }
            } else {
                print("uninitializing track queue")
                uninitializeTrackQueue()
                notEnablingUndo {
                    self.mainWindowController?.currentTrack?.is_playing = false
                }
                mainWindowController?.currentTableViewController?.reloadNowPlayingForTrack(mainWindowController!.currentTrack!)
                mainWindowController?.currentTrack = nil
                self.currentAudioSource = nil
                self.currentTrack = nil
                mainWindowController?.delegate?.audioModule.currentTrackLocation = nil
                mainWindowController?.delegate?.audioModule.skip_backward()
            }
        }
        print("current track index is \(currentTrackIndex)")
        tableView.reloadData()
        mainWindowController?.isDoneWithSkipBackOperation = true
    }
    
    func getLastTrack() -> Track? {
        guard currentTrackIndex != nil && trackQueue.count > 2 else {return nil}
        let row = currentTrackIndex! - 1
        return trackQueue[row].track
    }
    
    func getNextTrack() -> Track? {
        if trackQueue.count >= currentTrackIndex! + 3 {
            //addTrackToQueue(trackQueue[currentTrackIndex! + 1].track!, context: self.currentAudioSource!.name!, tense: 2, manually: false)
            return trackQueue[currentTrackIndex! + 1].track
        } else {
            if currentAudioSource!.playOrderObject!.current_play_order!.count <= currentSourceIndex! + 1 {
                currentAudioSource = nil
                return nil
            } else {
                var id: Int?
                id = currentAudioSource!.playOrderObject!.current_play_order![currentSourceIndex! + 1]
                currentSourceIndex! += 1
                var next_track: Track?
                if currentAudioSource?.is_network == true {
                    next_track = getNetworkTrackWithID(id!)
                } else {
                    next_track = getTrackWithID(id!)
                }
                if !fileManager.fileExists(atPath: URL(string: next_track!.location!)!.path) {
                    //are we on the main queue?
                    self.currentAudioSource?.playOrderObject?.libraryStatusNeedsUpdate()
                    self.currentSourceIndex = self.currentAudioSource?.playOrderObject?.current_play_order?.index(of: Int(self.currentTrack!.id!))
                    if currentAudioSource!.playOrderObject!.current_play_order!.count <= currentSourceIndex! + 1 {
                        currentAudioSource = nil
                        return nil
                    } else {
                        id = currentAudioSource!.playOrderObject!.current_play_order![currentSourceIndex! + 1]
                    }
                    if currentAudioSource?.is_network == true {
                        next_track = getNetworkTrackWithID(id!)
                    } else {
                        next_track = getTrackWithID(id!)
                    }
                }
                addTrackToQueue(next_track!, context: self.currentAudioSource!.name!, tense: 2, manually: false)
                return next_track
            }
        }
    }
    
    func modifyPlayOrderArrayForQueuedTracks(_ tracks: [Track]) {
        let idSet = Set(tracks.map({return Int($0.id!)}))
        var indicesToRemove = [Int]()
        var amountToOffsetCurrentSourceIndex = 0
        for (index, id) in currentAudioSource!.playOrderObject!.current_play_order!.enumerated() {
            if idSet.contains(id) && id != currentAudioSource!.playOrderObject?.current_play_order![currentSourceIndex!] {
                indicesToRemove.append(index)
                if index == currentSourceIndex {print("trying to remove from queue at currentSourceIndex")}
                if index < currentSourceIndex! {
                    amountToOffsetCurrentSourceIndex -= 1
                }
            }
        }
        for index in indicesToRemove.sorted().reversed() {
            currentAudioSource?.playOrderObject?.current_play_order?.remove(at: index)
        }
        currentSourceIndex! += amountToOffsetCurrentSourceIndex
    }
    
    func makePlayOrderChangesIfNecessaryForQueuedTracks(_ tracks: [Track]) {
        if currentSourceListItem != currentAudioSource {
            createPlayOrderArray(tracks.last!, row: nil)
        } else {
            modifyPlayOrderArrayForQueuedTracks(tracks)
        }
    }
    
    func modifyPlayOrderForSortDescriptorChange() {
        if shuffle == false {
            self.currentSourceListItem!.playOrderObject!.current_play_order = (self.currentSourceListItem?.tableViewController?.trackViewArrayController.arrangedObjects as! [TrackView]).map({return Int($0.track!.id!)})
            if currentSourceListItem == currentAudioSource {
                self.currentSourceIndex = self.currentSourceListItem?.playOrderObject?.current_play_order?.index(of: Int(self.currentTrack!.id!))
            }
        }
    }
    
    func createPlayOrderArray(_ track: Track, row: Int?) {
        print("initialize array called")
        currentAudioSource = currentSourceListItem
        self.currentSourceIndex = mainWindowController?.createPlayOrderForTrackID(Int(track.id!), row: row)
        destroyTransientTracks()
    }
    
    func shufflePressed(_ state: Int) {
        if (state == NSOnState) {
            self.shuffle = true
            UserDefaults.standard.set(true, forKey: DEFAULTS_SHUFFLE_STRING)
            for poo in activePlayOrders {
                print("shuffling")
                let idArray = poo.shuffled_play_order
                var shuffled_array = idArray
                shuffle_array(&shuffled_array!)
                if self.currentTrack != nil {
                    if let indexOfPlayedTrack = shuffled_array?.index(of: Int(self.currentTrack!.id!)) {
                        if indexOfPlayedTrack != 0 {
                            swap(&shuffled_array![shuffled_array!.index(of: Int(self.currentTrack!.id!))!], &shuffled_array![0])
                        }
                    }
                }
                poo.shuffled_play_order = shuffled_array
                currentSourceIndex = 0
                if poo.current_play_order!.count != poo.shuffled_play_order!.count {
                    let trackSet = Set(poo.current_play_order!)
                    poo.current_play_order = poo.shuffled_play_order!.filter({trackSet.contains($0)})
                } else {
                    poo.current_play_order = poo.shuffled_play_order
                }
            }
        }
        else {
            self.shuffle = false
            UserDefaults.standard.set(false, forKey: "shuffle")
            for poo in activePlayOrders {
                poo.current_play_order = (poo.sourceListItem.tableViewController?.trackViewArrayController.arrangedObjects as! [TrackView]).map({return Int($0.track!.id!)})
                if currentAudioSource?.playOrderObject == poo {
                    let queuedTrackIDs = Set(trackQueue.filter({$0.viewType == .futureTrack})).map({return Int($0.track!.id!)})
                    poo.current_play_order = poo.current_play_order!.filter({!queuedTrackIDs.contains($0)})
                    self.currentSourceIndex = poo.current_play_order?.index(of: Int(self.currentTrack!.id!))
                }
            }
        }
        destroyTransientTracks()
    }
    
    func destroyTransientTracks() {
        let transientTQVs = trackQueue.filter({return $0.viewType == .transient})
        for transientTQV in transientTQVs {
            mainWindowController?.delegate?.audioModule.trackQueue.removeFirst()
            trackQueue.remove(at: trackQueue.index(of: transientTQV)!)
        }
        tableView.reloadData()
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        if row <= currentTrackIndex {
            return NSDragOperation()
        }
        else {
            return NSDragOperation.every
        }
    }
    
    func makePlaylistFromSelection() {
        var track_id_list = [Int]()
        let thing = self.tableView!.selectedRowIndexes
        for (index, value) in thing.enumerated() {
            let id = self.trackQueue[index].track!.id
            track_id_list.append(Int(id!))
        }
        mainWindowController?.createPlaylistFromTracks(track_id_list)
    }
    
    func addTracksToQueue(_ row: Int?, tracks: [Track]) {
        var theRow = row == nil ? self.tableView.numberOfRows : row!
        for track in tracks {
            insertTrackInQueue(track, index: theRow, context: currentSourceListItem!.name!, manually: true)
            let queueIndex = currentTrackIndex == nil ? theRow : theRow - currentTrackIndex! - 1
            print("queue index \(theRow), actualRow \(theRow), currentIndex \(currentTrackIndex)")
            mainWindowController?.delegate?.audioModule.addTrackToQueue(track, index: queueIndex)
            theRow += 1
        }
        modifyPlayOrderArrayForQueuedTracks(tracks)
        tableView.reloadData()
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        print("accept drop")
        if (info.draggingPasteboard().types!.contains("Track")) {
            let thing = info.draggingPasteboard().data(forType: "Track")
            self.temporaryPooForDragging = nil
            self.temporaryPooIndexForDragging = nil
            let unCodedThing = NSKeyedUnarchiver.unarchiveObject(with: thing!) as! NSMutableArray
            let tracks = { () -> [Track] in
                var result = [Track]()
                for trackURI in unCodedThing {
                    let id = managedContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: trackURI as! URL)
                    result.append(managedContext.object(with: id!) as! Track)
                }
                return result
            }()
            addTracksToQueue(row, tracks: tracks)
        }
        if (info.draggingPasteboard().types!.contains("public.TrackQueueView")) {
            let codedViews = info.draggingPasteboard().data(forType: "public.TrackQueueView")
            let rows = NSKeyedUnarchiver.unarchiveObject(with: codedViews!) as! IndexSet
            var item_offset = 0
            var index_offset = 0
            let flippedRows = rows.reversed().map({return $0})
            for (index, element) in flippedRows.enumerated() {
                //not working properly when showing all tracks
                tableView.moveRow(at: element + item_offset, to: row + index_offset)
                let tqv = trackQueue.remove(at: element + item_offset)
                trackQueue.insert(tqv, at: row + index_offset)
                let t = self.mainWindowController!.delegate!.audioModule.trackQueue.remove(at: element + item_offset - currentTrackIndex! - 1)
                self.mainWindowController?.delegate?.audioModule.trackQueue.insert(t, at: row + index_offset - currentTrackIndex! - 1)
                if index + 1 < flippedRows.count && flippedRows[index + 1] >= row {
                    item_offset += 1
                } else {
                    item_offset = 0
                    index_offset -= 1
                }
            }
        }
        //tableView.reloadData()
        return true
    }
    
    
    func updateContext(_ name: String) {
        if trackQueue.count > 1 {
            trackQueue.removeLast()
        }
        let newSourceView = TrackQueueView()
        newSourceView.source = name
        newSourceView.viewType = .source
        trackQueue.append(newSourceView)
    }
    
    func interpretDeleteEvent() {
        guard tableView.selectedRow > -1 else {return}
        //terrible/slow implementation
        var indices = [Int]()
        for index in tableView.selectedRowIndexes {
            indices.append(index)
        }
        indices.sort()
        indices = indices.reversed()
        for index in indices {
            print("index is \(index)")
            self.trackQueue.remove(at: index)
            var newIndex: Int = index
            if self.currentTrackIndex != nil {
                newIndex -= self.currentTrackIndex!
            }
            self.mainWindowController?.delegate?.audioModule.trackQueue.remove(at: newIndex - 1)
        }
        //print(self.trackQueue)
        //print(self.mainWindowController?.trackQueue)
        tableView.reloadData()
    }
    
    func refreshForChangedData() {
        var deletedIndices = [Int]()
        for (index, view) in self.trackQueue.enumerated() {
            if view.track?.isDeleted == true {
                deletedIndices.append(index)
                if self.currentTrackIndex != nil && index < self.currentTrackIndex {
                    self.currentTrackIndex! -= 1
                }
            }
        }
        for index in deletedIndices {
            self.trackQueue.remove(at: index)
        }
        self.reloadData()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return trackQueue.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        //uses cell.subviews[x] because IB can't connect outlets from elements to nstablecellview subclasses using .xibs, apparently
        var object = trackQueue[row]
        if tableColumn?.identifier == "Is Playing" {
            switch object.viewType! {
            case .currentTrack:
                return tableView.make(withIdentifier: "nowPlaying", owner: nil) as! NowPlayingCell
            default:
                return nil
            }
        }
        else {
            switch object.viewType! {
            case .pastTrack:
                let result = tableView.make(withIdentifier: "pastTrack", owner: nil) as! PastTrackCell
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
                    let url = URL(string: path!)
                    let image = NSImage(contentsOf: url!)
                    (result.subviews[0] as! NSImageView).image = image
                }
                else {
                    (result.subviews[0] as! NSImageView).image = nil
                }
                return result
            case .currentTrack:
                let result = tableView.make(withIdentifier: "currentTrack", owner: nil) as! TrackNameTableCell
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
                    let url = URL(string: path!)
                    let image = NSImage(contentsOf: url!)
                    (result.subviews[0] as! NSImageView).image = image
                }
                else {
                    (result.subviews[0] as! NSImageView).image = nil
                }
                if mainWindowController?.paused != true {
                    (result.subviews[3] as! NSImageView).image = NSImage(named: "NSTouchBarAudioOutputVolumeMedTemplate")
                } else {
                    (result.subviews[3] as! NSImageView).image = NSImage(named: "NSTouchBarAudioOutputVolumeOffTemplate")
                }
                return result
            case .source:
                let result = tableView.make(withIdentifier: "source", owner: nil) as! FromSourceCell
                (result.subviews[1] as! NSTextField).stringValue = object.source!
                return result
            case .futureTrack:
                let result = tableView.make(withIdentifier: "futureTrack", owner: nil) as! TrackNameTableCell
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
                    let url = URL(string: path!)
                    let image = NSImage(contentsOf: url!)
                    (result.subviews[0] as! NSImageView).image = image
                }
                else {
                    (result.subviews[0] as! NSImageView).image = nil
                }
                return result
            case .transient:
                let result = tableView.make(withIdentifier: "futureTrack", owner: nil) as! TrackNameTableCell
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
                    let url = URL(string: path!)
                    let image = NSImage(contentsOf: url!)
                    (result.subviews[0] as! NSImageView).image = image
                }
                else {
                    (result.subviews[0] as! NSImageView).image = nil
                }
                return result
            }
        }
    }
    
    func reloadCurrentTrack() {
        let indexSet = IndexSet(integer: self.currentTrackIndex!)
        self.tableView.reloadData(forRowIndexes: indexSet, columnIndexes: IndexSet(integer: 0))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView!.dataSource = self
        tableView!.delegate = self
        tableView!.register(forDraggedTypes: ["Track", "public.TrackQueueView"])
        tableView.trackQueueViewController = self
        // Do view setup here.
        tableView.scroll(NSPoint(x: 0, y: tableView.frame.height))
    }

    
}
