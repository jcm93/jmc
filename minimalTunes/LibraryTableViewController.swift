//
//  LibraryTableViewController.swift
//  minimalTunes
//
//  Created by John Moody on 12/1/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
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
    var managedContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var searchString: String?
    var playlist: SongCollection?
    var advancedFilterVisible: Bool = false
    var hasInitialized = false
    var needsPlaylistRefresh = false
    
    var isVisibleDict = NSMutableDictionary()
    func populateIsVisibleDict() {
        if self.trackViewArrayController != nil {
            for track in self.trackViewArrayController.arrangedObjects as! [TrackView] {
                isVisibleDict[(track).track!.id!] = true
            }
        }
    }
    
    func reloadNowPlayingForTrack(track: Track) {
        if let row = (trackViewArrayController.arrangedObjects as! [TrackView]).indexOf(track.view!) {
            let tableRowIndexSet = NSIndexSet(index: row)
            let tableColumnIndexSet = NSIndexSet(index: 0)
            tableView.reloadDataForRowIndexes(tableRowIndexSet, columnIndexes: tableColumnIndexSet)
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
        /*
        single
        let item = (trackViewArrayController?.arrangedObjects as! [TrackView])[tableView!.selectedRow].track
        mainWindowController!.playSong(item!, row: tableView!.selectedRow)
        */
        var items = (trackViewArrayController.selectedObjects as! [TrackView]).map({return $0.track!})
        mainWindowController?.playSong(items.removeFirst(), row: nil)
        mainWindowController?.trackQueueViewController?.addTracksToQueue(nil, tracks: items)
    }
    
    @IBAction func getInfoFromTableView(sender: AnyObject) {
        let selectedTracks = rightMouseDownTarget!.map({return $0.track!})
        self.mainWindowController?.launchGetInfo(selectedTracks)
    }
    
    @IBAction func addToQueueFromTableView(sender: AnyObject) {
        let selectedTracks = rightMouseDownTarget!.map({return $0.track!})
        self.mainWindowController?.trackQueueViewController?.addTracksToQueue(nil, tracks: selectedTracks)
    }
    
    @IBAction func playFromTableView(sender: AnyObject) {
        let tracksToPlay = rightMouseDownTarget!.map({return $0.track!})
        self.mainWindowController?.playSong(tracksToPlay[0], row: rightMouseDownRow)
        if tracksToPlay.count > 1 {
            let tracks = Array(tracksToPlay[1...tracksToPlay.count])
            self.mainWindowController!.trackQueueViewController?.addTracksToQueue(nil, tracks: tracks)
        }
    }
    
    func jumpToCurrentSong(track: Track?) {
        if track != nil {
            let index = (trackViewArrayController.arrangedObjects as! [TrackView]).indexOf(track!.view!)
            if index != nil {
                tableView.scrollRowToVisible(index!)
            }
        }
    }
    
    func interpretSpacebarEvent() {
        mainWindowController?.interpretSpacebarEvent()
    }
    
    func tableViewDoubleClick(sender: AnyObject) {
        guard tableView!.selectedRow >= 0 && tableView!.clickedRow >= 0 else {
            return
        }
        let item = (trackViewArrayController?.arrangedObjects as! [TrackView])[tableView!.selectedRow].track
        mainWindowController!.playSong(item!, row: tableView!.selectedRow)
    }
    
    override func keyDown(theEvent: NSEvent) {
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
            self.rightMouseDownRow = row
        }
    }
    
    func interpretDeleteEvent() {
        
    }
    
    func modifyPlayOrderForSortDescriptors(poo: PlaylistOrderObject, trackID: Int) -> Int {
        let idArray = (self.trackViewArrayController.arrangedObjects as! [TrackView]).map({return Int($0.track!.id!)})
        poo.current_play_order = idArray
        return idArray.indexOf(trackID)!
    }

    func getUpcomingIDsForPlayEvent(shuffleState: Int, id: Int, row: Int?) -> Int {
        var idArray = self.item!.playOrderObject!.current_play_order!
        if shuffleState == NSOnState {
            //secretly adjust the shuffled array such that it behaves mysteriously like a ring buffer. ssshhhh
            let indexToSwap = idArray.indexOf(id)!
            let beginningOfArray = idArray[0..<indexToSwap]
            let endOfArray = idArray[indexToSwap..<idArray.count]
            let newArraySliceConcatenation = endOfArray + beginningOfArray
            idArray = Array(newArraySliceConcatenation)
            self.item?.playOrderObject?.current_play_order = idArray
            return 0
        } else {
            if row != nil {
                return row!
            } else {
                return idArray.indexOf(id)!
            }
        }
        /*let idArray = (self.trackViewArrayController.arrangedObjects as! [TrackView]).map({return Int($0.track!.id!)})
        var shuffled_array: [Int]?
        var initialSourceIndex: Int
        if shuffleState == NSOnState {
            shuffled_array = idArray
            if row != nil {
                shuffled_array?.removeAtIndex(row!)
            }
            shuffle_array(&shuffled_array!)
            if row != nil {
                shuffled_array?.insert(id, atIndex: 0)
            } else {
                let indexOfPlayedTrack = shuffled_array!.indexOf(id)!
                if indexOfPlayedTrack != 0 {
                    swap(&shuffled_array![indexOfPlayedTrack], &shuffled_array![0])
                }
            }
        }
        initialSourceIndex = shuffleState == NSOnState ? 0 : row != nil ? row! : idArray.indexOf(id)!
        let newPoo = PlaylistOrderObject(inorder_play_order: idArray)
        newPoo.shuffled_play_order = shuffled_array
        return (newPoo, initialSourceIndex)*/
    }
    
    func fixPlayOrderForChangedFilterPredicate(current_source_play_order: PlaylistOrderObject, shuffleState: Int) {
        print("fixing play order for changed filter predicate")
        let trackIDSet = Set((trackViewArrayController?.arrangedObjects as! [TrackView]).map( {return $0.track!.id as! Int}))
        let baseOrder: [Int] = {
            if shuffleState == NSOnState {
                return current_source_play_order.shuffled_play_order!
            } else {
                return current_source_play_order.inorder_play_order
            }
        }()
        let newPlayOrder = baseOrder.filter({trackIDSet.contains($0)})
        current_source_play_order.current_play_order = newPlayOrder
    }
    
    func initializeSmartPlaylist() {
        let smart_criteria = playlist!.smart_criteria
        let smart_predicate = smart_criteria?.predicate as! NSPredicate
        let fetchRequest = NSFetchRequest(entityName: "TrackView")
        fetchRequest.predicate = smart_predicate
        do {
            var results = try managedContext.executeFetchRequest(fetchRequest) as? NSArray
            if results != nil {
                results = (results as! [TrackView]).map({return $0.track!})
                if smart_criteria?.ordering_criterion != nil {
                    switch smart_criteria!.ordering_criterion! {
                    case "random":
                        results = shuffleArray(results as! [Track])
                    case "name":
                        results = results?.sortedArrayUsingSelector(#selector(Track.compareName))
                    case "artist":
                        results = results?.sortedArrayUsingSelector(#selector(Track.compareArtist))
                    case "album":
                        results = results?.sortedArrayUsingSelector(#selector(Track.compareAlbum))
                    case "composer":
                        let sortDescriptor = NSSortDescriptor(key: "composer.name", ascending: true)
                        results = results?.sortedArrayUsingDescriptors([sortDescriptor])
                    case "genre":
                        results = results?.sortedArrayUsingSelector(#selector(Track.compareGenre))
                    case "most recently added":
                        results = results?.sortedArrayUsingSelector(#selector(Track.compareDateAdded))
                    case "least recently added":
                        results = results?.sortedArrayUsingSelector(#selector(Track.compareDateAdded)).reverse()
                    case "most played":
                        let sortDescriptor = NSSortDescriptor(key: "play_count", ascending: false)
                        results = results?.sortedArrayUsingDescriptors([sortDescriptor])
                    case "least played":
                        let sortDescriptor = NSSortDescriptor(key: "play_count", ascending: true)
                        results = results?.sortedArrayUsingDescriptors([sortDescriptor])
                    case "most skipped":
                        let sortDescriptor = NSSortDescriptor(key: "skip_count", ascending: false)
                        results = results?.sortedArrayUsingDescriptors([sortDescriptor])
                    case "least skipped":
                        let sortDescriptor = NSSortDescriptor(key: "skip_count", ascending: true)
                        results = results?.sortedArrayUsingDescriptors([sortDescriptor])
                    case "most recently played":
                        let sortDescriptor = NSSortDescriptor(key: "date_last_played", ascending: true)
                        results = results?.sortedArrayUsingDescriptors([sortDescriptor])
                    case "least recently played":
                        let sortDescriptor = NSSortDescriptor(key: "date_last_played", ascending: false)
                        results = results?.sortedArrayUsingDescriptors([sortDescriptor])
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
                playlist?.track_id_list = track_id_list
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

    
    func initializeColumnVisibilityMenu(tableView: NSTableView) {
        var savedColumns = NSUserDefaults.standardUserDefaults().dictionaryForKey(DEFAULTS_SAVED_COLUMNS_STRING)
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
    
    func initializePlayOrderObject() {
        let currentIDArray = (self.trackViewArrayController.arrangedObjects as! [TrackView]).map({return Int($0.track!.id!)})
        let newPoo = PlaylistOrderObject(inorder_play_order: currentIDArray)
        if mainWindowController?.shuffle == true {
            var shuffledArray = currentIDArray
            shuffle_array(&shuffledArray)
            newPoo.shuffled_play_order = shuffledArray
            newPoo.current_play_order = shuffledArray
        } else {
            newPoo.current_play_order = currentIDArray
        }
        self.item?.playOrderObject = newPoo
        newPoo.sourceListItem = self.item
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "arrangedObjects" {
            if self.hasInitialized == false && (self.trackViewArrayController.arrangedObjects as! [TrackView]).count > 0 {
                initializePlayOrderObject()
                print("initialized poo for new view")
                self.hasInitialized = true
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
            
            let fetchReq = NSFetchRequest(entityName: "TrackView")
            fetchReq.predicate = predicate
            do {
                let results = try managedContext.executeFetchRequest(fetchReq) as! [TrackView]
                let trackViewIDDictionary = NSMutableDictionary()
                for result in results {
                    trackViewIDDictionary[result.track!.id!] = result
                }
                var index = 1
                for id in track_id_list {
                    (trackViewIDDictionary[id] as! TrackView).playlist_order = index
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
    
    override func viewDidLoad() {
        trackViewArrayController.addObserver(self, forKeyPath: "arrangedObjects", options: .New, context: &my_context)
        trackViewArrayController.tableViewController = self
        tableView.doubleAction = #selector(tableViewDoubleClick)
        columnVisibilityMenu.delegate = self
        //self.initializeColumnVisibilityMenu(self.tableView)
        tableView.setDelegate(trackViewArrayController)
        tableView.setDataSource(trackViewArrayController)
        tableView.libraryTableViewController = self
        tableView.reloadData()
        tableView.registerForDraggedTypes([NSFilenamesPboardType])
        trackViewArrayController.mainWindow = self.mainWindowController
        if playlist != nil {
            tableView.registerForDraggedTypes(["Track"]) //to enable d&d reordering
            tableView.tableColumns[1].hidden = false
            tableView.sortDescriptors = [tableView.tableColumns[1].sortDescriptorPrototype!]
            if playlist?.smart_criteria != nil {
                initializeSmartPlaylist()
            } else if playlist?.track_id_list != nil && self.needsPlaylistRefresh == true {
                trackViewArrayController.fetchPredicate = NSPredicate(format: "track.id in %@", playlist?.track_id_list as! [Int])
            }
            initializeForPlaylist()
        } else {
            tableView.tableColumns[1].hidden = true
            if let sortData = NSUserDefaults.standardUserDefaults().objectForKey(DEFAULTS_LIBRARY_SORT_DESCRIPTOR_STRING) {
                if let sortDescriptors = NSKeyedUnarchiver.unarchiveObjectWithData(sortData as! NSData) {
                    tableView.sortDescriptors = sortDescriptors as! [NSSortDescriptor]
                }
            }
        }
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
