//
//  LibraryTableViewController.swift
//  minimalTunes
//
//  Created by John Moody on 12/1/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class LibraryTableViewController: NSViewController, NSMenuDelegate {

    @IBOutlet weak var libraryTableScrollView: SpecialScrollView!
    @IBOutlet var columnVisibilityMenu: NSMenu!
    @IBOutlet var trackViewArrayController: DragAndDropArrayController!
    @IBOutlet weak var tableView: TableViewYouCanPressSpacebarOn!
    
    var mainWindowController: MainWindowController?
    var rightMouseDownTarget: [TrackView]?
    var item: SourceListItem?
    var managedContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    var isVisibleDict = NSMutableDictionary()
    func populateIsVisibleDict() {
        if self.trackViewArrayController != nil {
            for track in self.trackViewArrayController.arrangedObjects as! [TrackView] {
                isVisibleDict[(track).track!.id!] = true
            }
        }
    }
    
    func getTrackWithNoContext(shuffleState: Int) -> Track? {
        guard trackViewArrayController.arrangedObjects.count > 0 else {return nil}
        
        if tableView?.selectedRow >= 0 {
            return (trackViewArrayController?.arrangedObjects as! [TrackView])[tableView!.selectedRow].track!
        } else {
            var item: Track?
            if shuffleState == NSOffState {
                item = (trackViewArrayController?.arrangedObjects as! [TrackView])[0].track!
            } else if shuffleState == NSOnState {
                let random_index = Int(arc4random_uniform(UInt32(((trackViewArrayController?.arrangedObjects as! [TrackView]).count))))
                item = (trackViewArrayController?.arrangedObjects as! [TrackView])[random_index].track!
            }
            return item!
        }
    }
    
    func interpretEnterEvent() {
        guard tableView!.selectedRow >= 0 else {
            return
        }
        let item = (trackViewArrayController?.arrangedObjects as! [TrackView])[tableView!.selectedRow].track
        mainWindowController!.playSong(item!)
    }
    
    @IBAction func getInfoFromTableView(sender: AnyObject) {
        let selectedTracks = rightMouseDownTarget!.map({return $0.track!})
        self.mainWindowController?.launchGetInfo(selectedTracks)
    }
    
    @IBAction func addToQueueFromTableView(sender: AnyObject) {
        let selectedTracks = rightMouseDownTarget!.map({return $0.track!})
        self.mainWindowController?.addTracksToQueue(selectedTracks)
    }
    
    @IBAction func playFromTableView(sender: AnyObject) {
        let tracksToPlay = rightMouseDownTarget!.map({return $0.track!})
        self.mainWindowController?.playSong(tracksToPlay[0])
        if tracksToPlay.count > 1 {
            let tracks = Array(tracksToPlay[1...tracksToPlay.count])
            self.mainWindowController!.addTracksToQueue(tracks)
        }
    }
    
    func interpretSpacebarEvent() {
        mainWindowController?.interpretSpacebarEvent()
    }
    
    func tableViewDoubleClick(sender: AnyObject) {
        guard tableView!.selectedRow >= 0 else {
            return
        }
        let item = (trackViewArrayController?.arrangedObjects as! [TrackView])[tableView!.selectedRow].track
        mainWindowController!.playSong(item!)
    }
    
    override func keyDown(theEvent: NSEvent) {
        print(theEvent.keyCode)
        if (theEvent.keyCode == 36) {
            guard tableView!.selectedRow >= 0 else {
                return
            }
            let item = (trackViewArrayController?.arrangedObjects as! [TrackView])[tableView!.selectedRow].track
            mainWindowController!.playSong(item!)
        }
        else if theEvent.keyCode == 124 {
            mainWindowController!.skip()
        }
        else if theEvent.keyCode == 123 {
            mainWindowController?.skipBackward()
        } else {
            super.keyDown(theEvent)
        }
    }
    
    func jumpToSelection() {
        tableView.scrollRowToVisible(tableView.selectedRow)
    }
    
    func determineRightMouseDownTarget(row: Int) {
        let selectedRows = self.tableView.selectedRowIndexes
        if selectedRows.containsIndex(row) {
            self.rightMouseDownTarget = trackViewArrayController.selectedObjects as? [TrackView]
        } else {
            self.rightMouseDownTarget = [(trackViewArrayController.arrangedObjects as! [TrackView])[row]]
        }
    }
    
    func interpretDeleteEvent() {
        
    }
    
    func getUpcomingIDsForPlayEvent(shuffleState: Int, id: Int) -> [Int] {
        var idArray = (self.trackViewArrayController.arrangedObjects as! [TrackView]).map({return Int($0.track!.id!)})
        if shuffleState == NSOnState {
            idArray.removeAtIndex(idArray.indexOf(id)!)
            shuffle_array(&idArray)
            return idArray
        } else {
            let result = Array(idArray.suffix(idArray.count - idArray.indexOf(id)!))
            return result
        }
    }
    
    func fixPlayOrderForChangedFilterPredicate(current_source_play_order: [Int], shuffleState: Int) -> [Int] {
        let current_track_ids = (trackViewArrayController?.arrangedObjects as! [TrackView]).map( {return $0.track!.id as! Int} )
        var new_play_order = current_source_play_order
        if shuffleState == NSOnState {
            if trackViewArrayController?.filterPredicate != nil {
                for track_id in current_track_ids {
                    self.isVisibleDict[track_id] = true
                }
                new_play_order = current_source_play_order.filter({return (isVisibleDict[$0] as? Bool) == true})
                isVisibleDict = [:]
            } else {
                shuffle_array(&new_play_order)
            }
        }
        return new_play_order
    }

    
    func initializeColumnVisibilityMenu(tableView: NSTableView) {
        var savedColumns = NSUserDefaults.standardUserDefaults().dictionaryForKey(DEFAULTS_SAVED_COLUMNS_STRING)
        if savedColumns == nil {
            savedColumns = DEFAULT_COLUMN_VISIBILITY_DICTIONARY
            NSUserDefaults.standardUserDefaults().setObject(savedColumns, forKey: DEFAULTS_SAVED_COLUMNS_STRING)
        }
        
        let menu = tableView.headerView?.menu
        for column in tableView.tableColumns {
            if column.identifier == "name" || column.identifier == "is_playing" || column.identifier == "playlist_number" {
                continue
            }
            let menuItem: NSMenuItem
            if column.identifier == "is_enabled" {
                menuItem = NSMenuItem(title: "Enabled", action: #selector(toggleColumn), keyEquivalent: "")
            } else {
                menuItem = NSMenuItem(title: column.headerCell.title, action: #selector(toggleColumn), keyEquivalent: "")
            }
            if (savedColumns != nil) {
                let isHidden = savedColumns![column.identifier] as! Bool
                column.hidden = isHidden
            }
            menuItem.target = self
            menuItem.representedObject = column
            menuItem.state = column.hidden ? NSOffState : NSOnState
            menu?.addItem(menuItem)
        }
    }
    
    func toggleColumn(menuItem: NSMenuItem) {
        let column = menuItem.representedObject as! NSTableColumn
        column.hidden = !column.hidden
        menuItem.state = column.hidden ? NSOffState : NSOnState
        let columnVisibilityDictionary = NSMutableDictionary()
        for column in tableView.tableColumns {
            columnVisibilityDictionary[column.identifier] = column.hidden
        }
        NSUserDefaults.standardUserDefaults().setObject(columnVisibilityDictionary, forKey: DEFAULTS_SAVED_COLUMNS_STRING)
    }
    
    func menuWillOpen(menu: NSMenu) {
        for menuItem in menu.itemArray {
            if menuItem.representedObject != nil {
                menuItem.state = (menuItem.representedObject as! NSTableColumn).hidden ? NSOffState : NSOnState
            }
        }
    }
    
    override func viewDidLoad() {
        //tableView.canDrawSubviewsIntoLayer = true
        tableView.doubleAction = #selector(tableViewDoubleClick)
        columnVisibilityMenu.delegate = self
        self.initializeColumnVisibilityMenu(self.tableView)
        tableView.setDelegate(trackViewArrayController)
        tableView.setDataSource(trackViewArrayController)
        tableView.libraryTableViewController = self
        tableView.reloadData()
        trackViewArrayController.mainWindow = self.mainWindowController
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
