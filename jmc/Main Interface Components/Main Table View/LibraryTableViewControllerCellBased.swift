//
//  LibraryTableViewController.swift
//  minimalTunes
//
//  Created by John Moody on 12/1/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class LibraryTableViewControllerCellBased: LibraryTableViewController {
    
    @IBOutlet weak var isPlayingColumn: NSTableColumn!
    @IBOutlet weak var playlistNumberColumn: NSTableColumn!
    @IBOutlet weak var isEnabledColumn: NSTableColumn!
    @IBOutlet weak var nameColumn: NSTableColumn!
    @IBOutlet weak var timeColumn: NSTableColumn!
    @IBOutlet weak var albumByArtistColumn: NSTableColumn!
    @IBOutlet weak var artistColumn: NSTableColumn!
    @IBOutlet weak var albumColumn: NSTableColumn!
    @IBOutlet weak var albumArtistColumn: NSTableColumn!
    @IBOutlet weak var kindColumn: NSTableColumn!
    @IBOutlet weak var bitRateColumn: NSTableColumn!
    @IBOutlet weak var sizeColumn: NSTableColumn!
    @IBOutlet weak var trackNumColumn: NSTableColumn!
    @IBOutlet weak var dateAddedColumn: NSTableColumn!
    @IBOutlet weak var genreColumn: NSTableColumn!
    @IBOutlet weak var dateModifiedColumn: NSTableColumn!
    @IBOutlet weak var dateReleasedColumn: NSTableColumn!
    @IBOutlet weak var commentsColumn: NSTableColumn!
    @IBOutlet weak var composerColumn: NSTableColumn!
    @IBOutlet weak var discNumberColumn: NSTableColumn!
    @IBOutlet weak var equalizerColumn: NSTableColumn!
    @IBOutlet weak var lastPlayedColumn: NSTableColumn!
    @IBOutlet weak var lastSkippedColumn: NSTableColumn!
    @IBOutlet weak var movementNameColumn: NSTableColumn!
    @IBOutlet weak var movementNumColumn: NSTableColumn!
    @IBOutlet weak var playCountColumn: NSTableColumn!
    @IBOutlet weak var ratingColumn: NSTableColumn!
    @IBOutlet weak var sampleRateColumn: NSTableColumn!
    @IBOutlet weak var skipCountColumn: NSTableColumn!
    @IBOutlet weak var sortAlbumColumn: NSTableColumn!
    @IBOutlet weak var sortAlbumArtistColumn: NSTableColumn!
    @IBOutlet weak var sortArtistColumn: NSTableColumn!
    @IBOutlet weak var sortComposerColumn: NSTableColumn!
    @IBOutlet weak var sortNameColumn: NSTableColumn!
    
    
    override func viewDidLoad() {
        self.tableView.doubleAction = #selector(tableViewDoubleClick)
        columnVisibilityMenu.delegate = self
        self.initializeColumnVisibilityMenu(self.tableView)
        tableView.delegate = trackViewArrayController
        tableView.dataSource = trackViewArrayController
        tableView.libraryTableViewController = self
        tableView.reloadData()
        tableView.focusRingType = .none
        self.view.window?.makeFirstResponder(self)
        super.viewDidLoad()
        // Do view setup here.
    }
}
