//
//  LibraryTableViewController.swift
//  minimalTunes
//
//  Created by John Moody on 12/1/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
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
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}

private var my_context = 0

class LibraryTableViewController: NSViewController, NSMenuDelegate {

    @IBOutlet weak var libraryTableScrollView: NSScrollView!
    @IBOutlet var columnVisibilityMenu: NSMenu!
    @IBOutlet var trackViewArrayController: DragAndDropArrayController!
    @IBOutlet weak var tableView: TableViewYouCanPressSpacebarOn!
    
    var mainWindowController: MainWindowController?
    var rightMouseDownTarget: [TrackView]?
    var rightMouseDownRow: Int?
    var item: SourceListItem?
    @objc var managedContext = (NSApplication.shared.delegate as! AppDelegate).managedObjectContext
    var searchString: String?
    var playlist: SongCollection?
    var advancedFilterVisible: Bool = false
    var hasInitialized = false
    var hasCreatedPlayOrder = false
    var needsPlaylistRefresh = false
    var currentTrackRow = 0
    
    let getInfoMenuItem = NSMenuItem(title: "Get Info", action: #selector(getInfoFromTableView), keyEquivalent: "")
    let addToQueueMenuItem = NSMenuItem(title: "Add to Queue", action: #selector(addToQueueFromTableView), keyEquivalent: "")
    let playMenuItem = NSMenuItem(title: "Play", action: #selector(playFromTableView), keyEquivalent: "")
    let separatorMenuItem = NSMenuItem.separator()
    let toggleEnabledMenuItem = NSMenuItem(title: "Toggle Enabled/Disabled", action: #selector(toggleEnabled), keyEquivalent: "")
    let showInFinderMenuItem = NSMenuItem(title: "Show in Finder", action: #selector(showInFinderAction), keyEquivalent: "")
    
    var normalMenuItemsArray: [NSMenuItem]!
    
    var isVisibleDict = NSMutableDictionary()
    func populateIsVisibleDict() {
        if self.trackViewArrayController != nil {
            for track in self.trackViewArrayController.arrangedObjects as! [TrackView] {
                isVisibleDict[(track).track!.id!] = true
            }
        }
    }
    
    @IBAction func tableViewAction(_ sender: Any) {
        guard tableView.clickedColumn == 0 else { return }
        guard let track = ((self.trackViewArrayController.arrangedObjects as? NSArray)?[tableView.clickedRow] as? TrackView)?.track else { return }
        if track.is_available == false {
            print("clicked unavailable \(track.name)")
            //self.mainWindowController?.delegate?.openLibraryManager(self)
            self.mainWindowController?.delegate?.preferencesWindowController?.libraryManagerViewController?.tabView.selectTabViewItem(at: 1)
            self.mainWindowController?.delegate?.preferencesWindowController?.libraryManagerViewController?.verifyLocationsPressed(self)
            
        }
    }
    
    @IBAction func toggleEnabled(_ sender: Any) {
        guard self.trackViewArrayController.selectedObjects.count > 0 else { return }
        for trackView in trackViewArrayController.selectedObjects as! [TrackView] {
            trackView.track!.status = !(trackView.track!.status?.boolValue ?? false) as NSNumber?
        }
    }
    
    @IBAction func showInFinderAction(_ sender: Any) {
        guard let tracks = (self.trackViewArrayController.selectedObjects as? [TrackView])?.map({return $0.track!}), tracks.count > 0 else { return }
        let urls = tracks.map({return URL(string: $0.location!)!})
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }
    
    func reloadNowPlayingForTrack(_ track: Track) {
        if let row = (trackViewArrayController.arrangedObjects as! [TrackView]).index(of: track.view!) {
            self.currentTrackRow = row
            let tableRowIndexSet = IndexSet(integer: row)
            let indexOfPlaysColumn = self.tableView.column(withIdentifier: NSUserInterfaceItemIdentifier.init("play_count"))
            let indexOfSkipsColumn = self.tableView.column(withIdentifier: NSUserInterfaceItemIdentifier.init("skip_count"))
            let tableColumnIndexSet = IndexSet([0, indexOfPlaysColumn, indexOfSkipsColumn])
            tableView.reloadData(forRowIndexes: tableRowIndexSet, columnIndexes: tableColumnIndexSet)
        }
    }
    
    func reloadDataForTrack(_ track: Track, orRow row: Int?) {
        if let row = row {
            tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(0..<tableView.tableColumns.count))
        } else {
            let row = (trackViewArrayController.arrangedObjects as! [TrackView]).index(of: track.view!)!
            tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(0..<tableView.tableColumns.count))
        }
    }
    
    func scrollToNewTrack() {
        if currentTrackRow != 0, currentTrackRow < tableView.numberOfRows {
            tableView.scrollRowToVisible(currentTrackRow)
        }
    }
    
    func getTrackWithNoContext(_ shuffleState: Int) -> Track? {
        guard (trackViewArrayController.arrangedObjects as AnyObject).count > 0 else {return nil}
        
        if tableView?.selectedRow >= 0 {
            return (trackViewArrayController?.arrangedObjects as! [TrackView])[tableView!.selectedRow].track!
        } else {
            var item: Track?
            if shuffleState == NSControl.StateValue.off.rawValue {
                item = (trackViewArrayController?.arrangedObjects as! [TrackView])[0].track!
            } else if shuffleState == NSControl.StateValue.on.rawValue {
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
        var items = (trackViewArrayController.selectedObjects as! [TrackView]).map({return $0.track!})
        if mainWindowController!.playSong(items.removeFirst(), row: nil) {
            mainWindowController?.trackQueueViewController?.addTracksToQueue(nil, tracks: items)
        }
    }
    
    @IBAction func getInfoFromTableView(_ sender: AnyObject) {
        let selectedTracks = rightMouseDownTarget!.map({return $0.track!})
        self.mainWindowController?.launchGetInfo(selectedTracks)
    }
    
    @IBAction func addToQueueFromTableView(_ sender: AnyObject) {
        let selectedTracks = rightMouseDownTarget!.map({return $0.track!})
        self.mainWindowController?.trackQueueViewController?.addTracksToQueue(nil, tracks: selectedTracks)
    }
    
    @IBAction func playFromTableView(_ sender: AnyObject) {
        let tracksToPlay = rightMouseDownTarget!.map({return $0.track!})
        if self.mainWindowController!.playSong(tracksToPlay[0], row: rightMouseDownRow) {
            if tracksToPlay.count > 1 {
                let tracks = Array(tracksToPlay[1...tracksToPlay.count])
                self.mainWindowController!.trackQueueViewController?.addTracksToQueue(nil, tracks: tracks)
            }
        }
    }
    
    func jumpToCurrentSong(_ track: Track?) {
        if track != nil {
            let index = (trackViewArrayController.arrangedObjects as! [TrackView]).index(of: track!.view!)
            if index != nil {
                tableView.scrollRowToVisible(index!)
            }
        }
    }
    
    func interpretSpacebarEvent() {
        mainWindowController?.interpretSpacebarEvent()
    }
    
    @objc func tableViewDoubleClick(_ sender: AnyObject) {
        guard tableView!.selectedRow >= 0 && tableView!.clickedRow >= 0 else {
            return
        }
        let item = (trackViewArrayController?.arrangedObjects as! [TrackView])[tableView!.selectedRow].track
        mainWindowController!.playSong(item!, row: tableView!.selectedRow)
    }
    
    override func keyDown(with theEvent: NSEvent) {
        print(theEvent.keyCode)
        if (theEvent.keyCode == 36) {
            guard tableView!.selectedRow >= 0 else {
                return
            }
            let item = (trackViewArrayController?.arrangedObjects as! [TrackView])[tableView!.selectedRow].track
            mainWindowController!.playSong(item!, row: tableView!.selectedRow)
        }
        else if theEvent.keyCode == 124 {
            print("skipping")
            mainWindowController!.skip()
        }
        else if theEvent.keyCode == 123 {
            mainWindowController?.skipBackward()
        } else {
            super.keyDown(with: theEvent)
        }
    }
    
    func jumpToSelection() {
        tableView.scrollRowToVisible(tableView.selectedRow)
    }
    
    func determineRightMouseDownTarget(_ row: Int) {
        let selectedRows = self.tableView.selectedRowIndexes
        if selectedRows.contains(row) {
            self.rightMouseDownTarget = trackViewArrayController.selectedObjects as? [TrackView]
        } else {
            self.rightMouseDownTarget = [(trackViewArrayController.arrangedObjects as! [TrackView])[row]]
            self.rightMouseDownRow = row
        }
    }
    
    func interpretDeleteEvent() {
        guard trackViewArrayController.selectedObjects.count > 0 else {return}
        let selectedObjects = trackViewArrayController.selectedObjects as! [TrackView]
        mainWindowController!.interpretDeleteEvent(selectedObjects)
    }
    
    func modifyPlayOrderForSortDescriptors(_ poo: PlayOrderObject, trackID: Int) -> Int {
        var idArray = (self.trackViewArrayController.arrangedObjects as! [TrackView]).map({return Int($0.track!.id!)})
        poo.currentPlayOrder = idArray
        let queuedTrackIDs = Set(mainWindowController!.trackQueueViewController!.trackQueue.filter({$0.viewType == .futureTrack})).map({return Int($0.track!.id!)})
        poo.currentPlayOrder = poo.currentPlayOrder!.filter({!queuedTrackIDs.contains($0)})
        return idArray.index(of: trackID)!
    }

    func getUpcomingIDsForPlayEvent(_ shuffleState: Int, id: Int, row: Int?) -> Int {
        let volumes = Set((trackViewArrayController.arrangedObjects as! [TrackView]).flatMap({return $0.track?.volume}))
        var count = 0
        for volume in volumes {
            if !volumeIsAvailable(volume: volume) {
                count += 1
            }
        }
        if count > 0 {
            print("library status has changed, reloading data")
            mainWindowController?.sourceListViewController?.reloadData()
        }
        let idArray = (trackViewArrayController.arrangedObjects as! [TrackView]).map({return Int($0.track!.id!)})
        if shuffleState == NSControl.StateValue.on.rawValue {
            //secretly adjust the shuffled array such that it behaves mysteriously like a ring buffer. ssshhhh
            let currentShuffleArray = self.item!.playOrderObject!.shuffledPlayOrder!
            let indexToSwap = currentShuffleArray.index(of: id)!
            let beginningOfArray = currentShuffleArray[0..<indexToSwap]
            let endOfArray = currentShuffleArray[indexToSwap..<currentShuffleArray.count]
            let newArraySliceConcatenation = endOfArray + beginningOfArray
            self.item?.playOrderObject?.shuffledPlayOrder = Array(newArraySliceConcatenation)
            if self.item!.playOrderObject!.currentPlayOrder! != self.item!.playOrderObject!.shuffledPlayOrder! {
                let idSet = Set(idArray)
                self.item?.playOrderObject?.currentPlayOrder = self.item!.playOrderObject!.shuffledPlayOrder!.filter({idSet.contains($0)})
            } else {
                self.item?.playOrderObject?.currentPlayOrder = self.item!.playOrderObject!.shuffledPlayOrder!
            }
            return 0
        } else {
            self.item?.playOrderObject?.currentPlayOrder = idArray
            if row != nil {
                return row!
            } else {
                return idArray.index(of: id)!
            }
        }
    }
    
    func fixPlayOrderForChangedFilterPredicate(_ shuffleState: Int) {
        print("fixing play order for changed filter predicate")
        if shuffleState == NSControl.StateValue.on.rawValue {
            let idSet = Set((trackViewArrayController?.arrangedObjects as! [TrackView]).map( {return $0.track!.id as! Int}))
            let newPlayOrder = self.item!.playOrderObject!.shuffledPlayOrder!.filter({idSet.contains($0)})
            self.item!.playOrderObject!.currentPlayOrder = newPlayOrder
        } else {
            self.item?.playOrderObject?.currentPlayOrder = (trackViewArrayController?.arrangedObjects as! [TrackView]).map( {return $0.track!.id as! Int})
            if mainWindowController?.trackQueueViewController?.currentAudioSource == self.item {
                if let index = self.item?.playOrderObject?.currentPlayOrder?.index(of: Int(mainWindowController!.currentTrack!.id!)) {
                    mainWindowController?.trackQueueViewController?.currentSourceIndex = index
                } else {
                    mainWindowController?.trackQueueViewController?.currentSourceIndex = -1
                }
                let queuedTrackIDs = Set(mainWindowController!.trackQueueViewController!.trackQueue.filter({$0.viewType == .futureTrack})).map({return Int($0.track!.id!)})
                self.item!.playOrderObject!.currentPlayOrder = self.item!.playOrderObject!.currentPlayOrder!.filter({!queuedTrackIDs.contains($0)})
            }
        }
    }
    
    func initializeSmartPlaylist() {
        let smart_criteria = playlist!.smart_criteria
        let smart_predicate = smart_criteria?.predicate as! NSPredicate
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TrackView")
        fetchRequest.predicate = smart_predicate
        do {
            var results = try managedContext.fetch(fetchRequest) as? NSArray
            if results != nil {
                results = (results as! [TrackView]).map({return $0.track!}) as NSArray
                if smart_criteria?.ordering_criterion != nil {
                    switch smart_criteria!.ordering_criterion! {
                    case "random":
                        results = shuffleArray(results as! [Track]) as NSArray
                    case "name":
                        results = results!.sortedArray(using: #selector(Track.compareName)) as NSArray
                    case "artist":
                        results = results!.sortedArray(using: #selector(Track.compareArtist)) as NSArray
                    case "album":
                        results = results!.sortedArray(using: #selector(Track.compareAlbum)) as NSArray
                    case "composer":
                        let sortDescriptor = NSSortDescriptor(key: "composer.name", ascending: true)
                        results = results?.sortedArray(using: [sortDescriptor]) as NSArray?
                    case "genre":
                        results = results!.sortedArray(using: #selector(Track.compareGenre)) as NSArray
                    case "most recently added":
                        results = results!.sortedArray(using: #selector(Track.compareDateAdded)) as NSArray
                    case "least recently added":
                        results = results!.sortedArray(using: #selector(Track.compareDateAdded)).reversed() as NSArray
                    case "most played":
                        let sortDescriptor = NSSortDescriptor(key: "play_count", ascending: false)
                        results = results?.sortedArray(using: [sortDescriptor]) as NSArray?
                    case "least played":
                        let sortDescriptor = NSSortDescriptor(key: "play_count", ascending: true)
                        results = results?.sortedArray(using: [sortDescriptor]) as NSArray?
                    case "most skipped":
                        let sortDescriptor = NSSortDescriptor(key: "skip_count", ascending: false)
                        results = results?.sortedArray(using: [sortDescriptor]) as NSArray?
                    case "least skipped":
                        let sortDescriptor = NSSortDescriptor(key: "skip_count", ascending: true)
                        results = results?.sortedArray(using: [sortDescriptor]) as NSArray?
                    case "most recently played":
                        let sortDescriptor = NSSortDescriptor(key: "date_last_played", ascending: true)
                        results = results?.sortedArray(using: [sortDescriptor]) as NSArray?
                    case "least recently played":
                        let sortDescriptor = NSSortDescriptor(key: "date_last_played", ascending: false)
                        results = results?.sortedArray(using: [sortDescriptor]) as NSArray?
                    default:
                        print("fuck")
                    }
                }
                var limit: Float = 0.0
                var prunedResults = [Track]()
                if smart_criteria?.fetch_limit != nil {
                    let fetchType = smart_criteria!.fetch_limit_type!
                    let fetchLimit = Float(smart_criteria!.fetch_limit!)
                    for thing in results! {
                        switch fetchType {
                        case "hours":
                            limit += (Float((thing as! Track).time!) / 1000)/60/60
                        case "minutes":
                            limit += (Float((thing as! Track).time!) / 1000)/60
                        case "GB":
                            limit += (Float((thing as! Track).size!)/1000000000)
                        case "MB":
                            limit += (Float((thing as! Track).size!)/1000000)
                        case "items":
                            limit += 1
                        default:
                            limit += 1
                        }
                        if limit > fetchLimit {
                            break
                        } else {
                            prunedResults.append(thing as! Track)
                        }
                    }
                } else {
                    prunedResults = results as! [Track]
                }
                playlist!.tracks = NSOrderedSet(array: prunedResults.map({return $0.view!}))
            }
        } catch {
            print(error)
        }
        do {
            try managedContext.save()
        } catch {
            print(error)
        }
    }

    
    func initializeColumnVisibilityMenu(_ tableView: NSTableView) {
        var savedColumns = UserDefaults.standard.dictionary(forKey: DEFAULTS_SAVED_COLUMNS_STRING)
        /*if savedColumns == nil {
            savedColumns = DEFAULT_COLUMN_VISIBILITY_DICTIONARY
            NSUserDefaults.standardUserDefaults().setObject(savedColumns, forKey: DEFAULTS_SAVED_COLUMNS_STRING)
        }*/
        
        let menu = tableView.headerView?.menu
        for column in tableView.tableColumns {
            if column.identifier.rawValue == "name" || column.identifier.rawValue == "is_playing" || column.identifier.rawValue == "playlist_number" {
                continue
            }
            let menuItem: NSMenuItem
            if column.identifier.rawValue == "is_enabled" {
                menuItem = NSMenuItem(title: "Enabled", action: #selector(toggleColumn), keyEquivalent: "")
            } else {
                menuItem = NSMenuItem(title: column.headerCell.title, action: #selector(toggleColumn), keyEquivalent: "")
            }
            if (savedColumns != nil) {
                let isHidden = savedColumns![column.identifier.rawValue] as! Bool
                column.isHidden = isHidden
            }
            menuItem.target = self
            menuItem.representedObject = column
            menuItem.state = column.isHidden ? NSControl.StateValue.off : NSControl.StateValue.on
            menu?.addItem(menuItem)
        }
    }
    
    @objc func toggleColumn(_ menuItem: NSMenuItem) {
        let column = menuItem.representedObject as! NSTableColumn
        column.isHidden = !column.isHidden
        menuItem.state = column.isHidden ? NSControl.StateValue.off : NSControl.StateValue.on
        let columnVisibilityDictionary = NSMutableDictionary()
        for column in tableView.tableColumns {
            columnVisibilityDictionary[column.identifier] = column.isHidden
        }
        UserDefaults.standard.set(columnVisibilityDictionary, forKey: DEFAULTS_SAVED_COLUMNS_STRING)
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        switch menu {
        case self.columnVisibilityMenu:
            for menuItem in menu.items {
                if menuItem.representedObject != nil {
                    menuItem.state = (menuItem.representedObject as! NSTableColumn).isHidden ? NSControl.StateValue.off : NSControl.StateValue.on
                }
            }
        default:
            guard let _ = self.trackViewArrayController.object(at: tableView.clickedRow) else { menu.removeAllItems(); return }
            if menu.items.count == 0 {
                for item in self.normalMenuItemsArray {
                    menu.addItem(item)
                }
            }
        }
    }
    
    func initializePlayOrderObject() {
        print("creating play order object")
        print((self.trackViewArrayController.arrangedObjects as! NSArray).count)
        let currentIDArray = (self.trackViewArrayController.arrangedObjects as! [TrackView]).map({return Int($0.track!.id!)})
        let newPoo = NSEntityDescription.insertNewObject(forEntityName: "PlayOrderObject", into: managedContext) as! PlayOrderObject
        var shuffledArray = currentIDArray
        shuffle_array(&shuffledArray)
        newPoo.shuffledPlayOrder = shuffledArray
        if mainWindowController?.shuffle == true {
            newPoo.currentPlayOrder = shuffledArray
        } else {
            newPoo.currentPlayOrder = currentIDArray
        }
        self.item?.playOrderObject = newPoo
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "arrangedObjects" {
            if self.hasCreatedPlayOrder == false && (self.trackViewArrayController.arrangedObjects as! NSArray).count > 0 {
                if self.item?.playOrderObject == nil {
                    initializePlayOrderObject()
                }
                mainWindowController!.trackQueueViewController!.activePlayOrders.append(self.item!.playOrderObject!)
                self.item!.tableViewController = self
                print("initialized poo for new view")
                self.hasCreatedPlayOrder = true
                self.trackViewArrayController.hasInitialized = true
            } else {
                if (self.trackViewArrayController.arrangedObjects as! NSArray).count > self.item?.playOrderObject?.shuffledPlayOrder?.count ?? 0 {
                    self.initializePlayOrderObject()
                    print("reinitializing poo")
                }
            }
        }
    }
    
    func initializeForPlaylist() {
        print("initializing for playlist")
        trackViewArrayController.content = item!.playlist!.tracks!.array as! [TrackView]
        for (index, trackView) in item!.playlist!.tracks!.array.enumerated() {
            (trackView as! TrackView).playlist_order = index + 1 as NSNumber
        }
        trackViewArrayController.rearrangeObjects()
    }
    
    func initializeForLibrary() {
        //trackViewArrayController.fetchPredicate = NSPredicate(format: "track.is_network != true", self.item!.library!)
        trackViewArrayController.fetchPredicate = nil
        trackViewArrayController.fetch(nil)
    }
    
    func initializeForVolume() {
        let predicate = NSPredicate(format: "track.volume == %@", self.item!.volume!)
        trackViewArrayController.fetchPredicate = predicate
        trackViewArrayController.fetch(nil)
    }
    
    override func viewDidLoad() {
        print("view did load")
        self.normalMenuItemsArray = [self.getInfoMenuItem, self.addToQueueMenuItem, self.playMenuItem, self.separatorMenuItem, self.toggleEnabledMenuItem, self.showInFinderMenuItem]
        trackViewArrayController.addObserver(self, forKeyPath: "arrangedObjects", options: .new, context: &my_context)
        self.trackViewArrayController?.addObserver(self.mainWindowController!, forKeyPath: "arrangedObjects", options: .new, context: &self.mainWindowController!.my_context)
        self.trackViewArrayController.addObserver(self.mainWindowController!, forKeyPath: "filterPredicate", options: .new, context: &self.mainWindowController!.my_context)
        self.trackViewArrayController.addObserver(self.mainWindowController!, forKeyPath: "sortDescriptors", options: .new, context: &self.mainWindowController!.my_context)
        trackViewArrayController.tableViewController = self as! LibraryTableViewControllerCellBased
        tableView.target = self
        tableView.menu?.delegate = self
        tableView.doubleAction = #selector(tableViewDoubleClick)
        //tableView.enclosingScrollView?.wantsLayer = true
        columnVisibilityMenu.delegate = self
        //self.initializeColumnVisibilityMenu(self.tableView)
        tableView.delegate = trackViewArrayController
        tableView.dataSource = trackViewArrayController
        tableView.libraryTableViewController = self
        tableView.reloadData()
        tableView.registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeURL as String)])
        trackViewArrayController.mainWindow = self.mainWindowController
        if playlist != nil {
            print("initializing for playlist")
            tableView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: "Track")]) //to enable d&d reordering
            tableView.tableColumns[1].isHidden = false
            tableView.sortDescriptors = [tableView.tableColumns[1].sortDescriptorPrototype!]
            if playlist?.smart_criteria != nil {
                initializeSmartPlaylist()
            }
            initializeForPlaylist()
        } else if item?.library != nil {
            print("initializing for library")
            tableView.tableColumns[1].isHidden = true
            if let sortData = UserDefaults.standard.object(forKey: DEFAULTS_LIBRARY_SORT_DESCRIPTOR_STRING) {
                if let sortDescriptors = NSKeyedUnarchiver.unarchiveObject(with: sortData as! Data) {
                    tableView.sortDescriptors = sortDescriptors as! [NSSortDescriptor]
                }
            }
            initializeForLibrary()
        } else if item?.volume != nil {
            tableView.tableColumns[1].isHidden = true
            if let sortData = UserDefaults.standard.object(forKey: DEFAULTS_LIBRARY_SORT_DESCRIPTOR_STRING) {
                if let sortDescriptors = NSKeyedUnarchiver.unarchiveObject(with: sortData as! Data) {
                    tableView.sortDescriptors = sortDescriptors as! [NSSortDescriptor]
                }
            }
            initializeForVolume()
        }
        super.viewDidLoad()
        // Do view setup here.
        self.tableView.canDrawConcurrently = false
    }
    
}
