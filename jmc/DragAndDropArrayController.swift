//
//  DragAndDropArrayController.swift
//  minimalTunes
//
//  Created by John Moody on 7/1/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class DragAndDropArrayController: NSArrayController, NSTableViewDataSource, NSTableViewDelegate {
    
    var mainWindow: MainWindowController?
    var tableViewController: LibraryTableViewControllerCellBased?
    var draggedRowIndexes: IndexSet?
    var countTest = 0
    var hasInitialized = false
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        //cast to NSArray to avoid typechecking every single object in array, as in when we cast to [TrackView]
        let track = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!
        let status = track.library?.is_available as? Bool ?? true
        let value = { () -> Any? in
        switch tableColumn! {
        case tableViewController!.isPlayingColumn:
            if track.is_playing == true {
                if mainWindow?.paused == true {
                    return NSImage(named: "NSAudioOutputVolumeOffTemplate")
                } else {
                    return NSImage(named: "NSAudioOutputVolumeMedTemplate")
                }
            } else {
                return nil
            }
        case tableViewController!.playlistNumberColumn:
            return track.view?.playlist_order
        case tableViewController!.isEnabledColumn:
            return track.status
        case tableViewController!.nameColumn:
            return track.name
        case tableViewController!.timeColumn:
            return track.time
        case tableViewController!.artistColumn:
            return track.artist?.name
        case tableViewController!.albumColumn:
            return track.album?.name
        case tableViewController!.kindColumn:
            return track.file_kind
        case tableViewController!.bitRateColumn:
            return track.bit_rate
        case tableViewController!.sizeColumn:
            return track.size
        case tableViewController!.trackNumColumn:
            return track.track_num
        case tableViewController!.dateAddedColumn:
            return track.date_added
        case tableViewController!.genreColumn:
            return track.genre
        case tableViewController!.dateModifiedColumn:
            return track.date_modified
        case tableViewController!.dateReleasedColumn:
            return track.album?.release_date
        case tableViewController!.commentsColumn:
            return track.comments
        case tableViewController!.composerColumn:
            return track.composer?.name
        case tableViewController!.discNumberColumn:
            return track.disc_number
        case tableViewController!.equalizerColumn:
            return track.equalizer_preset
        case tableViewController!.lastPlayedColumn:
            return track.date_last_played
        case tableViewController!.lastSkippedColumn:
            return track.date_last_skipped
        case tableViewController!.movementNameColumn:
            return track.movement_name
        case tableViewController!.movementNumColumn:
            return track.movement_number
        case tableViewController!.playCountColumn:
            return track.play_count
        case tableViewController!.ratingColumn:
            return track.rating
        case tableViewController!.sampleRateColumn:
            return track.sample_rate
        case tableViewController!.skipCountColumn:
            return track.skip_count
        case tableViewController!.sortAlbumColumn:
            return track.sort_album
        case tableViewController!.sortAlbumArtistColumn:
            return track.sort_album_artist
        case tableViewController!.sortArtistColumn:
            return track.sort_artist
        case tableViewController!.sortComposerColumn:
            return track.sort_composer
        case tableViewController!.sortNameColumn:
            return track.sort_name
        default:
            return ""
        }
        }()
        return (value, status)
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        print("sort descriptors did change called")
        let archivedSortDescriptor = NSKeyedArchiver.archivedData(withRootObject: tableView.sortDescriptors)
        if tableViewController?.playlist?.track_id_list != nil {
            UserDefaults.standard.set(archivedSortDescriptor, forKey: DEFAULTS_PLAYLIST_SORT_DESCRIPTOR_STRING)
        } else {
            UserDefaults.standard.set(archivedSortDescriptor, forKey: DEFAULTS_LIBRARY_SORT_DESCRIPTOR_STRING)
        }
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        print("table view writerows called")
        let rows = NSMutableArray()
        for index in rowIndexes {
            let trackView = (self.arrangedObjects as! [TrackView])[index]
            rows.add(trackView.track!.objectID.uriRepresentation())
        }
        draggedRowIndexes = rowIndexes
        let encodedIDs = NSKeyedArchiver.archivedData(withRootObject: rows)
        let context = mainWindow?.currentSourceListItem?.name
        print("context is \(context)")
        if context != nil {
            pboard.setString(context!, forType: "context")
        }
        if mainWindow?.currentSourceListItem?.is_network == true {
            print("settin network pboard data")
            pboard.setData(encodedIDs, forType: "NetworkTrack")
        } else {
            pboard.setData(encodedIDs, forType: "Track")
        }
        return true
    }
    
    func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet) {
        print("dragypoo called")
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        if info.draggingPasteboard().types!.contains(NSFilenamesPboardType) {
            let files = info.draggingPasteboard().propertyList(forType: NSFilenamesPboardType) as! NSArray
            let urls = files.map({return URL(fileURLWithPath: $0 as! String)})
            let appDelegate = (NSApplication.shared().delegate as! AppDelegate)
            var errors = [FileAddToDatabaseError]()
            let databaseManager = DatabaseManager()
            let urlParseResult = databaseManager.getMediaURLsInDirectoryURLs(urls)
            errors.append(contentsOf: urlParseResult.1)
            let mediaURLs = urlParseResult.0
            let newErrors = databaseManager.addTracksFromURLs(mediaURLs, to: self.mainWindow!.currentLibrary!, visualUpdateHandler: nil, callback: nil)
            errors.append(contentsOf: newErrors)
            for error in errors {
                error.urlString = error.urlString.removingPercentEncoding!
            }
            appDelegate.showImportErrors(errors)
            return true
        } else {
            //if we've reached this point, we must be in a playlist with a valid track id list, and the table must be sorted by playlist order
            var track_id_list = tableViewController!.playlist!.track_id_list as! [Int]
            var ids = [Int]()
            for index in draggedRowIndexes!.reversed() {
                ids.append(track_id_list[index])
                track_id_list.remove(at: index)
            }
            ids = ids.reversed()
            track_id_list.insert(contentsOf: ids, at: row)
            tableViewController!.playlist!.track_id_list = track_id_list as NSObject?
            tableViewController?.initializeForPlaylist()
            draggedRowIndexes = nil
            return true
        }
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        if info.draggingPasteboard().types!.contains(NSFilenamesPboardType) {
            print("doingle")
            tableView.setDropRow(-1, dropOperation: NSTableViewDropOperation.on)
            return .copy
        }
        if draggedRowIndexes != nil && dropOperation == .above && tableView.sortDescriptors.first == tableView.tableColumns[1].sortDescriptorPrototype! && tableViewController?.playlist?.smart_criteria == nil {
            return .move
        } else {
            return NSDragOperation()
        }
    }
}
