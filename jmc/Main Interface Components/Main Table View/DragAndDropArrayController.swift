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
    var tableViewController: LibraryTableViewControllerCellBased!
    var draggedRowIndexes: IndexSet?
    var countTest = 0
    var hasInitialized = false
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        //cast to NSArray to avoid typechecking every single object in array, as in when we cast to [TrackView]
        let track = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!
        let status = track.is_available as? Bool ?? track.library?.is_available as? Bool ?? true
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
                if track.is_available == false {
                    return NSImage(named: "NSRevealFreestandingTemplate")
                }
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
        case tableViewController!.albumByArtistColumn:
            return track.artist?.name
        case tableViewController!.albumArtistColumn:
            return track.album?.album_artist?.name
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

    
    func imageClicked(_ sender: Any) {
        guard let track = ((self.arrangedObjects as? NSArray)?[tableViewController!.tableView.clickedRow] as? TrackView)?.track else { return }
        print("clicked \(track.name)")
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        print("set object value for table column called")
        //todo get property to edit from tableColumn and call edit function
        switch tableColumn! {
        case tableViewController!.nameColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!.name!
            guard (object as! String) != oldValue else { return }   
            mainWindow?.delegate?.databaseManager?.nameEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! TrackView).track!], value: object as! String)
        case tableViewController!.artistColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!.artist?.name ?? ""
            guard (object as! String) != oldValue else { return }
            mainWindow?.delegate?.databaseManager?.artistEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! TrackView).track!], value: object as! String)
        case tableViewController!.albumColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!.album?.name ?? ""
            guard (object as! String) != oldValue else { return }
            mainWindow?.delegate?.databaseManager?.albumEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! TrackView).track!], value: object as! String)
        case tableViewController!.trackNumColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!.track_num
            guard (object as? NSNumber) != oldValue else { return }
            mainWindow?.delegate?.databaseManager?.trackNumEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! TrackView).track!], value: object as? Int ?? 0)
        case tableViewController!.commentsColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!.comments ?? ""
            guard (object as! String) != oldValue else { return }
            mainWindow?.delegate?.databaseManager?.commentsEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! TrackView).track!], value: object as! String)
        case tableViewController!.composerColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!.composer?.name ?? ""
            guard (object as! String) != oldValue else { return }
            mainWindow?.delegate?.databaseManager?.composerEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! TrackView).track!], value: object as! String)
        case tableViewController!.discNumberColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!.disc_number
            guard (object as? NSNumber) != oldValue else { return }
            mainWindow?.delegate?.databaseManager?.discNumEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! TrackView).track!], value: object as? Int ?? 0)
        case tableViewController!.movementNameColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!.movement_name ?? ""
            guard (object as! String) != oldValue else { return }
            mainWindow?.delegate?.databaseManager?.movementNameEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! TrackView).track!], value: object as! String)
        case tableViewController!.movementNumColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!.movement_number
            guard (object as? NSNumber) != oldValue else { return }
            mainWindow?.delegate?.databaseManager?.movementNumEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! TrackView).track!], value: object as? Int ?? 0)
        case tableViewController!.sortAlbumColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!.sort_album ?? ""
            guard (object as! String) != oldValue else { return }
            mainWindow?.delegate?.databaseManager?.sortAlbumEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! TrackView).track!], value: object as! String)
        case tableViewController!.sortAlbumArtistColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!.sort_album_artist ?? ""
            guard (object as! String) != oldValue else { return }
            mainWindow?.delegate?.databaseManager?.sortAlbumArtistEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! TrackView).track!], value: object as! String)
        case tableViewController!.sortArtistColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!.sort_artist ?? ""
            guard (object as! String) != oldValue else { return }
            mainWindow?.delegate?.databaseManager?.sortArtistEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! TrackView).track!], value: object as! String)
        case tableViewController!.sortComposerColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!.sort_composer ?? ""
            guard (object as! String) != oldValue else { return }
            mainWindow?.delegate?.databaseManager?.sortComposerEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! TrackView).track!], value: object as! String)
        case tableViewController!.sortNameColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! TrackView).track!.sort_name ?? ""
            guard (object as! String) != oldValue else { return }
            mainWindow?.delegate?.databaseManager?.sortNameEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! TrackView).track!], value: object as! String)
        default: break
        }
        self.fetch(nil)
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if UserDefaults.standard.bool(forKey: DEFAULTS_ARTWORK_SHOWS_SELECTED) {
            if let track = (self.selectedObjects as? [TrackView])?.first?.track {
                mainWindow?.initAlbumArtwork(for: track)
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, mouseDownInHeaderOf tableColumn: NSTableColumn) {
        guard let newDescriptor = tableColumn.sortDescriptorPrototype?.key else { return }
        let cachedOrderName = keyToCachedOrderDictionary[newDescriptor]
        if cachedOrderName != nil {
            let cachedOrder = cachedOrders![cachedOrderName!]
            if cachedOrder?.needs_update == true {
                fixIndicesImmutable(order: cachedOrder!)
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        print("sort descriptors did change called")
        let archivedSortDescriptor = NSKeyedArchiver.archivedData(withRootObject: tableView.sortDescriptors)
        if tableViewController?.playlist != nil {
            UserDefaults.standard.set(archivedSortDescriptor, forKey: DEFAULTS_PLAYLIST_SORT_DESCRIPTOR_STRING)
        } else {
            UserDefaults.standard.set(archivedSortDescriptor, forKey: DEFAULTS_LIBRARY_SORT_DESCRIPTOR_STRING)
        }
        switch TableSortBehavior(rawValue: UserDefaults.standard.integer(forKey: DEFAULTS_TABLE_SORT_BEHAVIOR))! {
        case .followsCurrentTrack:
            if let currentTrackView = mainWindow?.currentTrack?.view {
                let row = (self.arrangedObjects as! NSArray).index(of: currentTrackView)
                if row > -1 {
                    tableView.scrollRowToVisible(row)
                }
            }
        case .followsSelection:
            tableView.scrollRowToVisible(tableView.selectedRow)
        default: break
        }
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        print("table view writerows called")
        pboard.clearContents()
        pboard.declareTypes([NSPasteboard.PasteboardType(kUTTypeURL as String)], owner: self)
        let rows = NSMutableArray()
        var fileURLs = [NSURL]()
        for index in rowIndexes {
            let trackView = (self.arrangedObjects as! NSArray)[index] as! TrackView
            rows.add(trackView.track!.objectID.uriRepresentation())
            fileURLs.append(URL(string: trackView.track!.location!)! as NSURL)
        }
        print("writing urls")
        //pboard.addTypes([NSURLPboardType], owner: nil)
        pboard.writeObjects(fileURLs)
        draggedRowIndexes = rowIndexes
        let encodedIDs = NSKeyedArchiver.archivedData(withRootObject: rows)
        let context = mainWindow?.currentSourceListItem?.name
        print("context is \(context)")
        if context != nil {
            pboard.setString(context!, forType: NSPasteboard.PasteboardType(rawValue: "context"))
        }
        if mainWindow?.currentSourceListItem?.is_network == true {
            print("settin network pboard data")
            pboard.setData(encodedIDs, forType: NSPasteboard.PasteboardType(rawValue: "NetworkTrack"))
        } else {
            pboard.setData(encodedIDs, forType: NSPasteboard.PasteboardType(rawValue: "Track"))
        }
        return true
    }
    
    func object(at index: Int) -> TrackView? {
        guard let array = self.arrangedObjects as? NSArray else { return nil }
        guard index > -1, array.count > index else { return nil }
        return array[index] as? TrackView
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        if info.draggingPasteboard.types!.contains(NSPasteboard.PasteboardType(rawValue: "public.file-url")) && !info.draggingPasteboard.types!.contains(NSPasteboard.PasteboardType(rawValue: "Track")) {
            let files = info.draggingPasteboard.pasteboardItems!.filter({return $0.types.contains(NSPasteboard.PasteboardType(rawValue: "public.file-url"))}).map({return $0.string(forType: NSPasteboard.PasteboardType(rawValue: "public.file-url"))})
            let urls = files.compactMap({return URL(string: $0 ?? "")})
            let appDelegate = (NSApplication.shared.delegate as! AppDelegate)
            var errors = [FileAddToDatabaseError]()
            let databaseManager = DatabaseManager()
            let urlParseResult = databaseManager.getMediaURLsInDirectoryURLs(urls)
            errors.append(contentsOf: urlParseResult.1)
            let mediaURLs = urlParseResult.0
            let newErrors = databaseManager.addTracksFromURLs(mediaURLs, to: globalRootLibrary!, context: managedContext, visualUpdateHandler: nil, callback: nil)
            errors.append(contentsOf: newErrors)
            for error in errors {
                error.urlString = error.urlString.removingPercentEncoding!
            }
            appDelegate.showImportErrors(errors)
            return true
        } else {
            //if we've reached this point, we must be in a playlist with a valid track id list, and the table must be sorted by playlist order
            managedContext.processPendingChanges()
            managedContext.undoManager?.beginUndoGrouping()
            var rowAtWhichToInsert = row
            for index in draggedRowIndexes! {
                if index < row {
                    rowAtWhichToInsert -= 1
                }
            }
            let objects = tableViewController!.playlist!.tracks!.objects(at: draggedRowIndexes!)
            tableViewController?.playlist?.removeFromTracks(at: draggedRowIndexes! as NSIndexSet)
            let indexSet = IndexSet(integersIn: rowAtWhichToInsert..<rowAtWhichToInsert + objects.count)
            tableViewController?.playlist?.mutableOrderedSetValue(forKey: "Tracks").insert(objects, at: indexSet)
            tableViewController?.initializeForPlaylist()
            draggedRowIndexes = nil
            managedContext.processPendingChanges()
            managedContext.undoManager?.setActionName("Edit Playlist Order")
            managedContext.undoManager?.endUndoGrouping()
            return true
        }
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if info.draggingPasteboard.types!.contains(NSPasteboard.PasteboardType(rawValue: "public.file-url")) && !info.draggingPasteboard.types!.contains(NSPasteboard.PasteboardType(rawValue: "Track")) {
            print("doingle")
            tableView.setDropRow(-1, dropOperation: NSTableView.DropOperation.on)
            return .copy
        }
        if draggedRowIndexes != nil && dropOperation == .above && tableView.sortDescriptors.first == tableView.tableColumns[1].sortDescriptorPrototype! && tableViewController?.playlist?.smart_criteria == nil {
            return .move
        } else {
            return NSDragOperation()
        }
    }
}
