//
//  LibraryTableViewController.swift
//  minimalTunes
//
//  Created by John Moody on 12/1/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
private var my_context = 0

class DumbArrayController: NSArrayController, NSTableViewDataSource, NSTableViewDelegate {
    
    var databaseManager = DatabaseManager()
    
    @IBOutlet weak var nameColumn: NSTableColumn!
    @IBOutlet weak var artistColumn: NSTableColumn!
    @IBOutlet weak var albumColumn: NSTableColumn!
    @IBOutlet weak var trackNumColumn: NSTableColumn!
    @IBOutlet weak var commentsColumn: NSTableColumn!
    @IBOutlet weak var composerColumn: NSTableColumn!
    @IBOutlet weak var discNumColumn: NSTableColumn!
    @IBOutlet weak var equalizerColumn: NSTableColumn!
    @IBOutlet weak var movementNameColumn: NSTableColumn!
    @IBOutlet weak var movementNumColumn: NSTableColumn!
    @IBOutlet weak var sortAlbumColumn: NSTableColumn!
    @IBOutlet weak var sortAlbumArtistColumn: NSTableColumn!
    @IBOutlet weak var sortArtistColumn: NSTableColumn!
    @IBOutlet weak var sortComposerColumn: NSTableColumn!
    @IBOutlet weak var sortNameColumn: NSTableColumn!
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        print("set object value for table column called")
        //todo get property to edit from tableColumn and call edit function
        switch tableColumn! {
        case self.nameColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track.name!
            guard (object as! String) != oldValue else { return }
            self.databaseManager.nameEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track], value: object as! String)
        case self.artistColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track.artist?.name ?? ""
            guard (object as! String) != oldValue else { return }
            self.databaseManager.artistEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track], value: object as! String)
        case self.albumColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track.album?.name ?? ""
            guard (object as! String) != oldValue else { return }
            self.databaseManager.albumEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track], value: object as! String)
        case self.trackNumColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track.track_num
            guard (object as? NSNumber) != oldValue else { return }
            self.databaseManager.trackNumEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track], value: object as? Int ?? 0)
        case self.commentsColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track.comments ?? ""
            guard (object as! String) != oldValue else { return }
            self.databaseManager.commentsEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track], value: object as! String)
        case self.composerColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track.composer?.name ?? ""
            guard (object as! String) != oldValue else { return }
            self.databaseManager.composerEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track], value: object as! String)
        case self.discNumColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track.disc_number
            guard (object as? NSNumber) != oldValue else { return }
            self.databaseManager.discNumEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track], value: object as? Int ?? 0)
        case self.movementNameColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track.movement_name ?? ""
            guard (object as! String) != oldValue else { return }
            self.databaseManager.movementNameEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track], value: object as! String)
        case self.movementNumColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track.movement_number
            guard (object as? NSNumber) != oldValue else { return }
            self.databaseManager.movementNumEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track], value: object as? Int ?? 0)
        case self.sortAlbumColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track.sort_album ?? ""
            guard (object as! String) != oldValue else { return }
            self.databaseManager.sortAlbumEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track], value: object as! String)
        case self.sortAlbumArtistColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track.sort_album_artist ?? ""
            guard (object as! String) != oldValue else { return }
            self.databaseManager.sortAlbumArtistEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track], value: object as! String)
        case self.sortArtistColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track.sort_artist ?? ""
            guard (object as! String) != oldValue else { return }
            self.databaseManager.sortArtistEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track], value: object as! String)
        case self.sortComposerColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track.sort_composer ?? ""
            guard (object as! String) != oldValue else { return }
            self.databaseManager.sortComposerEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track], value: object as! String)
        case self.sortNameColumn:
            let oldValue = ((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track.sort_name ?? ""
            guard (object as! String) != oldValue else { return }
            self.databaseManager.sortNameEdited(tracks: [((self.arrangedObjects as! NSArray)[row] as! DisparateTrack).track], value: object as! String)
        default: break
        }
        self.fetch(nil)
    }
    
}

class LibraryConsolidatorTableViewController: NSViewController, NSMenuDelegate {

    @IBOutlet weak var libraryTableScrollView: NSScrollView!
    @IBOutlet var columnVisibilityMenu: NSMenu!
    @IBOutlet var trackViewArrayController: DumbArrayController!
    @IBOutlet weak var tableView: NSTableView!

    
    
    @IBAction func getInfoFromTableView(_ sender: AnyObject) {
        //let selectedTracks = rightMouseDownTarget!.map({return $0.track!})
        //self.mainWindowController?.launchGetInfo(selectedTracks)
    }
    

    
    func jumpToSelection() {
        tableView.scrollRowToVisible(tableView.selectedRow)
    }
    

    
    func initializeColumnVisibilityMenu(_ tableView: NSTableView) {
        var savedColumns = UserDefaults.standard.dictionary(forKey: DEFAULTS_SAVED_COLUMNS_STRING_CONSOLIDATOR)
        if savedColumns == nil {
            savedColumns = DEFAULT_COLUMN_VISIBILITY_DICTIONARY_CONSOLIDATOR
            UserDefaults.standard.set(savedColumns, forKey: DEFAULTS_SAVED_COLUMNS_STRING_CONSOLIDATOR)
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
                let isHidden = savedColumns![column.identifier] as? Int
                column.isHidden = isHidden != nil ? isHidden! != 0 : false
            }
            menuItem.target = self
            menuItem.representedObject = column
            menuItem.state = column.isHidden ? NSOffState : NSOnState
            menu?.addItem(menuItem)
        }
    }
    
    func toggleColumn(_ menuItem: NSMenuItem) {
        let column = menuItem.representedObject as! NSTableColumn
        column.isHidden = !column.isHidden
        menuItem.state = column.isHidden ? NSOffState : NSOnState
        let columnVisibilityDictionary = NSMutableDictionary()
        for column in tableView.tableColumns {
            columnVisibilityDictionary[column.identifier] = column.isHidden
        }
        UserDefaults.standard.set(columnVisibilityDictionary, forKey: DEFAULTS_SAVED_COLUMNS_STRING_CONSOLIDATOR)
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        for menuItem in menu.items {
            if menuItem.representedObject != nil {
                menuItem.state = (menuItem.representedObject as! NSTableColumn).isHidden ? NSOffState : NSOnState
            }
        }
    }
    
    override func viewDidLoad() {
        print("view did load")
        columnVisibilityMenu.delegate = self
        self.initializeColumnVisibilityMenu(self.tableView)
        tableView.reloadData()
        tableView.delegate = trackViewArrayController
        tableView.dataSource = trackViewArrayController
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
