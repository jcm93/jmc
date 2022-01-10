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

class LibraryTableViewController: NSViewController, LibraryViewController, NSMenuDelegate {
    
    
    func getFilterPredicate() -> NSPredicate? {
        return self.trackViewArrayController.filterPredicate
    }
    
    func getSelectedObjects() -> [TrackView] {
        return self.trackViewArrayController.selectedObjects as! [TrackView]
    }
    
    func setArrayControllerContent(_ content: Any?) {
        self.trackViewArrayController.content = content
    }
    
    func reloadData() {
        self.tableView.reloadData()
    }
    
    func selectItems(_ selection: [TrackView]) {
        self.trackViewArrayController.setSelectedObjects(selection)
    }
    
    func setFilterPredicate(_ searchFieldContent: String) {
        let searchTokens = searchFieldContent.components(separatedBy: " ").filter({return $0 != ""})
        var subPredicates = [NSPredicate]()
        for token in searchTokens {
            //not accepted by NSPredicateEditor
            //let newPredicate = NSPredicate(format: "ANY {track.name, track.artist.name, track.album.name, track.composer.name, track.comments, track.genre.name} contains[cd] %@", token)
            //accepted by NSPredicateEditor
            let newPredicate = NSPredicate(format: "track.name contains[cd] %@ OR track.artist.name contains[cd] %@ OR track.album.name contains[cd] %@ OR track.composer.name contains[cd] %@ OR track.comments contains[cd] %@ OR track.genre contains[cd] %@", token, token, token, token, token, token)
            subPredicates.append(newPredicate)
        }
        if subPredicates.count > 0 {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
            self.trackViewArrayController.filterPredicate = predicate
            //currentLibraryViewController?.trackViewArrayController.filterPredicate = predicate
            self.searchString = searchFieldContent
        } else {
            self.trackViewArrayController.filterPredicate = nil
            //currentLibraryViewController?.trackViewArrayController.filterPredicate = nil
            self.searchString = nil
        }
    }
    
    func getArrangedObjects() -> [TrackView] {
        return self.trackViewArrayController.arrangedObjects as! [TrackView]
    }
    
    func rearrangeObjects() {
        self.trackViewArrayController.rearrangeObjects()
    }
    
    func setFetchPredicate(_ predicate: NSPredicate?) {
        self.trackViewArrayController.fetchPredicate = predicate
    }
    
    
    @IBOutlet weak var libraryTableScrollView: NSScrollView!
    @IBOutlet var columnVisibilityMenu: NSMenu!
    @IBOutlet var trackViewArrayController: DragAndDropArrayController!
    @IBOutlet weak var tableView: TableViewYouCanPressSpacebarOn!
    
    var mainWindowController: MainWindowController?
    var rightMouseDownTarget: [TrackView]?
    var rightMouseDownRow: Int = 0
    var item: SourceListItem?
    @objc var managedContext = (NSApplication.shared.delegate as! AppDelegate).managedObjectContext
    var searchString: String?
    var playlist: SongCollection?
    var advancedFilterVisible: Bool = false
    var hasInitialized = false
    var hasCreatedPlayOrder = false
    var needsPlaylistRefresh = false
    var currentTrackRow = 0
    var statusStringNeedsUpdate = false
    
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
        guard tableView.clickedRow > -1 else { return }
        guard let track = ((self.trackViewArrayController.arrangedObjects as? NSArray)?[tableView.clickedRow] as? TrackView)?.track else { return }
        if track.is_available == false {
            print("clicked unavailable \(track.name)")
            locateTrack(track: track)
        }
    }
    
    func locateTrack(track: Track) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = ["public.audio"]
        let panelResponse = openPanel.runModal()
        if panelResponse == NSApplication.ModalResponse.OK {
            guard let url = openPanel.url else { return }
            track.location = url.absoluteString
            track.is_available = true
            //todo rescan metadata
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
        if let row = (trackViewArrayController.arrangedObjects as! [TrackView]).firstIndex(of: track.view!) {
            self.currentTrackRow = row
            let tableRowIndexSet = IndexSet(integer: row)
            let indexOfPlaysColumn = self.tableView.column(withIdentifier: NSUserInterfaceItemIdentifier.init("play_count"))
            let indexOfSkipsColumn = self.tableView.column(withIdentifier: NSUserInterfaceItemIdentifier.init("skip_count"))
            let tableColumnIndexSet = IndexSet([0, indexOfPlaysColumn, indexOfSkipsColumn])
            tableView.reloadData(forRowIndexes: tableRowIndexSet, columnIndexes: tableColumnIndexSet)
        }
    }
    
    func reloadDataForTrack(_ track: Track, orRow row: Int) {
        if row > -1 {
            tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(0..<tableView.tableColumns.count))
        } else {
            let row = (trackViewArrayController.arrangedObjects as! [TrackView]).firstIndex(of: track.view!)!
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
        if mainWindowController!.playSong(items.removeFirst(), row: -1) {
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
            let index = (trackViewArrayController.arrangedObjects as! [TrackView]).firstIndex(of: track!.view!)
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
        if self.item?.playlist?.tracks?.count ?? 0 > 0 {
            if UserDefaults.standard.bool(forKey: DEFAULTS_DOESNT_ASKS_DELETE_PLAYLIST) != true {
                let alert = NSAlert()
                alert.addButton(withTitle: "OK")
                alert.addButton(withTitle: "Cancel")
                alert.messageText = "Are you sure you want to remove the selected tracks from this playlist?"
                alert.showsSuppressionButton = true
                let response = alert.runModal()
                if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                    print("deleting tracks")
                    self.remove(tracks: selectedObjects, from: self.item!.playlist!)
                }
                if alert.suppressionButton?.state == .on {
                    UserDefaults.standard.set(true, forKey: DEFAULTS_DOESNT_ASKS_DELETE_PLAYLIST)
                }
            } else {
                self.remove(tracks: selectedObjects, from: self.item!.playlist!)
            }
        } else {
            mainWindowController!.interpretDeleteEvent(selectedObjects)
        }
    }
    
    func remove(tracks: [TrackView], from playlist: SongCollection) {
        playlist.removeFromTracks(NSOrderedSet(array: tracks))
        self.initializeForPlaylist()
        //self.tableView.reloadData()
    }
    
    func modifyPlayOrderForSortDescriptors(_ poo: PlayOrderObject, trackID: Int) -> Int {
        var idArray = (self.trackViewArrayController.arrangedObjects as! [TrackView]).map({return Int($0.track!.id!)})
        poo.currentPlayOrder = idArray
        let queuedTrackIDs = Set(mainWindowController!.trackQueueViewController!.trackQueue.filter({$0.viewType == .futureTrack})).map({return Int($0.track!.id!)})
        poo.currentPlayOrder = poo.currentPlayOrder!.filter({!queuedTrackIDs.contains($0)})
        return idArray.firstIndex(of: trackID)!
    }

    func getUpcomingIDsForPlayEvent(_ shuffleState: Int, id: Int, row: Int) -> Int {
        let volumes = Set((trackViewArrayController.arrangedObjects as! [TrackView]).compactMap({return $0.track?.volume}))
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
            let currentShuffleArray = self.item!.songsPlayOrderObject!.shuffledPlayOrder!
            let indexToSwap = currentShuffleArray.firstIndex(of: id)!
            let beginningOfArray = currentShuffleArray[0..<indexToSwap]
            let endOfArray = currentShuffleArray[indexToSwap..<currentShuffleArray.count]
            let newArraySliceConcatenation = endOfArray + beginningOfArray
            self.item?.songsPlayOrderObject?.shuffledPlayOrder = Array(newArraySliceConcatenation)
            if self.item!.songsPlayOrderObject!.currentPlayOrder! != self.item!.songsPlayOrderObject!.shuffledPlayOrder! {
                let idSet = Set(idArray)
                self.item?.songsPlayOrderObject?.currentPlayOrder = self.item!.songsPlayOrderObject!.shuffledPlayOrder!.filter({idSet.contains($0)})
            } else {
                self.item?.songsPlayOrderObject?.currentPlayOrder = self.item!.songsPlayOrderObject!.shuffledPlayOrder!
            }
            return 0
        } else {
            self.item?.songsPlayOrderObject?.currentPlayOrder = idArray
            if row > -1 {
                return row
            } else {
                return idArray.firstIndex(of: id)!
            }
        }
    }
    
    func fixPlayOrderForChangedFilterPredicate(_ shuffleState: Int) {
        print("fixing play order for changed filter predicate")
        if shuffleState == NSControl.StateValue.on.rawValue {
            let idSet = Set((trackViewArrayController?.arrangedObjects as! [TrackView]).map( {return $0.track!.id as! Int}))
            let newPlayOrder = self.item!.songsPlayOrderObject!.shuffledPlayOrder!.filter({idSet.contains($0)})
            self.item!.songsPlayOrderObject!.currentPlayOrder = newPlayOrder
        } else {
            self.item?.songsPlayOrderObject?.currentPlayOrder = (trackViewArrayController?.arrangedObjects as! [TrackView]).map( {return $0.track!.id as! Int})
            if mainWindowController?.trackQueueViewController?.currentAudioSource == self.item {
                if let index = self.item?.songsPlayOrderObject?.currentPlayOrder?.firstIndex(of: Int(mainWindowController!.currentTrack!.id!)) {
                    mainWindowController?.trackQueueViewController?.currentSourceIndex = index
                } else {
                    mainWindowController?.trackQueueViewController?.currentSourceIndex = -1
                }
                let queuedTrackIDs = Set(mainWindowController!.trackQueueViewController!.trackQueue.filter({$0.viewType == .futureTrack})).map({return Int($0.track!.id!)})
                self.item!.songsPlayOrderObject!.currentPlayOrder = self.item!.songsPlayOrderObject!.currentPlayOrder!.filter({!queuedTrackIDs.contains($0)})
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
        guard let item = self.item else { return }
        if item.songsPlayOrderObject == nil {
            let newObject = NSEntityDescription.insertNewObject(forEntityName: "PlayOrderObject", into: managedContext) as! PlayOrderObject
            item.songsPlayOrderObject = newObject
        }
        let playOrderObject = item.songsPlayOrderObject!
        print((self.trackViewArrayController.arrangedObjects as! NSArray).count)
        let currentIDArray = (self.trackViewArrayController.arrangedObjects as! [TrackView]).map({return Int($0.track!.id!)})
        var shuffledArray = currentIDArray
        shuffle_array(&shuffledArray)
        playOrderObject.shuffledPlayOrder = shuffledArray
        if mainWindowController?.shuffle == true {
            playOrderObject.currentPlayOrder = shuffledArray
        } else {
            playOrderObject.currentPlayOrder = currentIDArray
        }
        self.statusStringNeedsUpdate = true
    }
    @IBAction func getInfoAction(_ sender: Any) {
        self.getInfoFromTableView(sender as AnyObject)
        
    }
    @IBAction func deleteMenuItemAction(_ sender: Any) {
        self.interpretDeleteEvent()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "arrangedObjects" {
            if self.hasCreatedPlayOrder == false && (self.trackViewArrayController.arrangedObjects as! NSArray).count > 0 {
                if self.item?.songsPlayOrderObject == nil {
                    initializePlayOrderObject()
                }
                mainWindowController!.trackQueueViewController!.activePlayOrders.append(self.item!.songsPlayOrderObject!)
                self.item!.libraryTableViewController = self
                print("initialized poo for new view")
                self.hasCreatedPlayOrder = true
                self.trackViewArrayController.hasInitialized = true
                (self.trackViewArrayController.arrangedObjects as! NSArray).map({return ($0 as! TrackView).track?.id}) //fire faults
            } else {
                if (self.trackViewArrayController.arrangedObjects as! NSArray).count != self.item?.songsPlayOrderObject?.shuffledPlayOrder?.count ?? 0 {
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
        self.trackViewArrayController.addObserver(self.mainWindowController!, forKeyPath: "arrangedObjects", options: .new, context: &self.mainWindowController!.my_context)
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
