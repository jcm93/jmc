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

    @IBOutlet weak var libraryTableScrollView: SpecialScrollView!
    @IBOutlet var columnVisibilityMenu: NSMenu!
    @IBOutlet var trackViewArrayController: DragAndDropArrayController!
    @IBOutlet weak var tableView: TableViewYouCanPressSpacebarOn!
    
    var mainWindowController: MainWindowController?
    var rightMouseDownTarget: [TrackView]?
    var rightMouseDownRow: Int?
    var item: SourceListItem?
    var managedContext = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
    var searchString: String?
    var playlist: SongCollection?
    var advancedFilterVisible: Bool = false
    var hasInitialized = false
    var hasCreatedPlayOrder = false
    var needsPlaylistRefresh = false
    
    var isVisibleDict = NSMutableDictionary()
    func populateIsVisibleDict() {
        if self.trackViewArrayController != nil {
            for track in self.trackViewArrayController.arrangedObjects as! [TrackView] {
                isVisibleDict[(track).track!.id!] = true
            }
        }
    }
    
    func reloadNowPlayingForTrack(_ track: Track) {
        if let row = (trackViewArrayController.arrangedObjects as! [TrackView]).index(of: track.view!) {
            let tableRowIndexSet = IndexSet(integer: row)
            let tableColumnIndexSet = IndexSet(integer: 0)
            tableView.reloadData(forRowIndexes: tableRowIndexSet, columnIndexes: tableColumnIndexSet)
        }
    }
    
    func getTrackWithNoContext(_ shuffleState: Int) -> Track? {
        guard (trackViewArrayController.arrangedObjects as AnyObject).count > 0 else {return nil}
        
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
        /*
        single
        let item = (trackViewArrayController?.arrangedObjects as! [TrackView])[tableView!.selectedRow].track
        mainWindowController!.playSong(item!, row: tableView!.selectedRow)
        */
        var items = (trackViewArrayController.selectedObjects as! [TrackView]).map({return $0.track!})
        mainWindowController?.playSong(items.removeFirst(), row: nil)
        mainWindowController?.trackQueueViewController?.addTracksToQueue(nil, tracks: items)
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
        self.mainWindowController?.playSong(tracksToPlay[0], row: rightMouseDownRow)
        if tracksToPlay.count > 1 {
            let tracks = Array(tracksToPlay[1...tracksToPlay.count])
            self.mainWindowController!.trackQueueViewController?.addTracksToQueue(nil, tracks: tracks)
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
    
    func tableViewDoubleClick(_ sender: AnyObject) {
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
    
    func modifyPlayOrderForSortDescriptors(_ poo: PlaylistOrderObject, trackID: Int) -> Int {
        let idArray = (self.trackViewArrayController.arrangedObjects as! [TrackView]).map({return Int($0.track!.id!)})
        poo.current_play_order = idArray
        let queuedTrackIDs = Set(mainWindowController!.trackQueueViewController!.trackQueue.filter({$0.viewType == .futureTrack})).map({return Int($0.track!.id!)})
        poo.current_play_order = poo.current_play_order!.filter({!queuedTrackIDs.contains($0)})
        return idArray.index(of: trackID)!
    }

    func getUpcomingIDsForPlayEvent(_ shuffleState: Int, id: Int, row: Int?) -> Int {
        let libraries = Set((trackViewArrayController.arrangedObjects as! [TrackView]).flatMap({return $0.track?.library}))
        var count = 0
        for library in libraries {
            if (library.is_available as! Bool) != libraryIsAvailable(library: library) {
                count += 1
            }
        }
        if count > 0 {
            print("library status has changed, reloading data")
            mainWindowController?.sourceListViewController?.reloadData()
        }
        let idArray = (trackViewArrayController.arrangedObjects as! [TrackView]).filter({return $0.track?.library?.is_available == true}).map({return Int($0.track!.id!)})
        if shuffleState == NSOnState {
            //secretly adjust the shuffled array such that it behaves mysteriously like a ring buffer. ssshhhh
            let currentShuffleArray = self.item!.playOrderObject!.shuffled_play_order!
            let indexToSwap = currentShuffleArray.index(of: id)!
            let beginningOfArray = currentShuffleArray[0..<indexToSwap]
            let endOfArray = currentShuffleArray[indexToSwap..<currentShuffleArray.count]
            let newArraySliceConcatenation = endOfArray + beginningOfArray
            self.item?.playOrderObject?.shuffled_play_order = Array(newArraySliceConcatenation)
            if self.item!.playOrderObject!.current_play_order! != self.item!.playOrderObject!.shuffled_play_order! {
                let idSet = Set(idArray)
                self.item?.playOrderObject?.current_play_order = self.item!.playOrderObject!.shuffled_play_order!.filter({idSet.contains($0)})
            } else {
                self.item?.playOrderObject?.current_play_order = self.item!.playOrderObject!.shuffled_play_order!
            }
            return 0
        } else {
            self.item?.playOrderObject?.current_play_order = idArray
            if row != nil {
                return row!
            } else {
                return idArray.index(of: id)!
            }
        }
    }
    
    func fixPlayOrderForChangedFilterPredicate(_ shuffleState: Int) {
        print("fixing play order for changed filter predicate")
        if shuffleState == NSOnState {
            let idSet = Set((trackViewArrayController?.arrangedObjects as! [TrackView]).map( {return $0.track!.id as! Int}))
            let newPlayOrder = self.item!.playOrderObject!.shuffled_play_order!.filter({idSet.contains($0)})
            self.item!.playOrderObject!.current_play_order = newPlayOrder
        } else {
            self.item?.playOrderObject?.current_play_order = (trackViewArrayController?.arrangedObjects as! [TrackView]).map( {return $0.track!.id as! Int})
            if mainWindowController?.trackQueueViewController?.currentAudioSource == self.item {
                if let index = self.item?.playOrderObject?.current_play_order?.index(of: Int(mainWindowController!.currentTrack!.id!)) {
                    mainWindowController?.trackQueueViewController?.currentSourceIndex = index
                } else {
                    mainWindowController?.trackQueueViewController?.currentSourceIndex = -1
                }
                let queuedTrackIDs = Set(mainWindowController!.trackQueueViewController!.trackQueue.filter({$0.viewType == .futureTrack})).map({return Int($0.track!.id!)})
                self.item!.playOrderObject!.current_play_order = self.item!.playOrderObject!.current_play_order!.filter({!queuedTrackIDs.contains($0)})
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
                        results = shuffleArray(results as! [Track]) as! NSArray
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
                let track_id_list = prunedResults.map({return $0.id as! Int})
                playlist?.track_id_list = track_id_list as NSObject?
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
                column.isHidden = isHidden
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
        UserDefaults.standard.set(columnVisibilityDictionary, forKey: DEFAULTS_SAVED_COLUMNS_STRING)
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        for menuItem in menu.items {
            if menuItem.representedObject != nil {
                menuItem.state = (menuItem.representedObject as! NSTableColumn).isHidden ? NSOffState : NSOnState
            }
        }
    }
    
    func initializePlayOrderObject() {
        print("creating play order object")
        print((self.trackViewArrayController.arrangedObjects as! NSArray).count)
        let currentIDArray = (self.trackViewArrayController.arrangedObjects as! [TrackView]).map({return Int($0.track!.id!)})
        let newPoo = PlaylistOrderObject(sli: self.item!)
        var shuffledArray = currentIDArray
        shuffle_array(&shuffledArray)
        newPoo.shuffled_play_order = shuffledArray
        if mainWindowController?.shuffle == true {
            newPoo.current_play_order = shuffledArray
        } else {
            newPoo.current_play_order = currentIDArray
        }
        self.item?.playOrderObject = newPoo
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "arrangedObjects" {
            if self.hasCreatedPlayOrder == false && (self.trackViewArrayController.arrangedObjects as! [TrackView]).count > 0 {
                initializePlayOrderObject()
                mainWindowController?.trackQueueViewController?.activePlayOrders.append(self.item!.playOrderObject!)
                self.item!.tableViewController = self
                print("initialized poo for new view")
                self.hasCreatedPlayOrder = true
                self.trackViewArrayController.hasInitialized = true
            }
        }
    }
    
    func initializeForPlaylist() {
        print("initializing for playlist")
        var track_id_list: [Int] = []
        var predicates = [NSPredicate]()
        if item!.playlist?.track_id_list != nil {
            track_id_list = item!.playlist!.track_id_list as! [Int]
            let predicate = NSPredicate(format: "track.id in %@", track_id_list)
            predicates.append(predicate)
            
            let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "TrackView")
            fetchReq.predicate = predicate
            do {
                let results = try managedContext.fetch(fetchReq) as! [TrackView]
                let trackViewIDDictionary = NSMutableDictionary()
                for result in results {
                    trackViewIDDictionary[result.track!.id!] = result
                }
                var index = 1
                for id in track_id_list {
                    (trackViewIDDictionary[id] as! TrackView).playlist_order = index as NSNumber?
                    index += 1
                }
            } catch {
                print(error)
            }
        } else {
            predicates.append(NSPredicate(format: "track.id in {}"))
        }
        if item!.is_network == true {
            predicates.append(NSPredicate(format: "track.is_network == true"))
        } else {
            predicates.append(NSPredicate(format: "track.is_network == nil or track.is_network == false"))
        }
        trackViewArrayController.fetchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    func initializeForLibrary() {
        if self.item?.library?.parent != nil {
            trackViewArrayController.fetchPredicate = NSPredicate(format: "track.library == %@", self.item!.library!)
        } else {
            let activeLibraries = { () -> [Library] in
                let fetch = NSFetchRequest<Library>(entityName: "Library")
                fetch.predicate = NSPredicate(format: "is_active == %@", NSNumber(booleanLiteral: true))
                do {
                    return try managedContext.fetch(fetch)
                } catch {
                    return [Library]()
                }
                }().filter({(library: Library) in return libraryIsAvailable(library: library)})
            trackViewArrayController.fetchPredicate = NSPredicate(format: "track.library in %@", activeLibraries)
        }
    }
    
    override func viewDidLoad() {
        print("view did load")
        trackViewArrayController.addObserver(self, forKeyPath: "arrangedObjects", options: .new, context: &my_context)
        trackViewArrayController.tableViewController = self as! LibraryTableViewControllerCellBased
        tableView.doubleAction = #selector(tableViewDoubleClick)
        columnVisibilityMenu.delegate = self
        //self.initializeColumnVisibilityMenu(self.tableView)
        tableView.delegate = trackViewArrayController
        tableView.dataSource = trackViewArrayController
        tableView.libraryTableViewController = self
        tableView.reloadData()
        tableView.register(forDraggedTypes: [NSFilenamesPboardType])
        trackViewArrayController.mainWindow = self.mainWindowController
        if playlist != nil {
            tableView.register(forDraggedTypes: ["Track"]) //to enable d&d reordering
            tableView.tableColumns[1].isHidden = false
            tableView.sortDescriptors = [tableView.tableColumns[1].sortDescriptorPrototype!]
            if playlist?.smart_criteria != nil {
                initializeSmartPlaylist()
            } else if playlist?.track_id_list != nil && self.needsPlaylistRefresh == true {
                trackViewArrayController.fetchPredicate = NSPredicate(format: "track.id in %@", playlist?.track_id_list as! [Int])
            }
            initializeForPlaylist()
        } else {
            tableView.tableColumns[1].isHidden = true
            if let sortData = UserDefaults.standard.object(forKey: DEFAULTS_LIBRARY_SORT_DESCRIPTOR_STRING) {
                if let sortDescriptors = NSKeyedUnarchiver.unarchiveObject(with: sortData as! Data) {
                    tableView.sortDescriptors = sortDescriptors as! [NSSortDescriptor]
                }
            }
            initializeForLibrary()
        }
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
