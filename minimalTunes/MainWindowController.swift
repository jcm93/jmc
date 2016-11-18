//
//  MainWindowController.swift
//  minimalTunes
//
//  Created by John Moody on 5/30/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
import CoreData
 

private var my_context = 0


class MainWindowController: NSWindowController, NSOutlineViewDelegate, NSOutlineViewDataSource, NSSearchFieldDelegate, NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate {
    
    @IBOutlet weak var librarySplitView: NSSplitView!
    @IBOutlet var noMusicView: NSView!
    
    
    @IBOutlet weak var auxTableView: TableViewYouCanPressSpacebarOn!
    @IBOutlet var auxTableScrollView: NSScrollView!
    @IBOutlet var auxTrackViewArrayController: DragAndDropArrayController!
    @IBOutlet weak var bitRateFormatter: BitRateFormatter!
    @IBOutlet var trackViewArrayController: DragAndDropArrayController!
    @IBOutlet weak var libraryTableView: TableViewYouCanPressSpacebarOn!
    @IBOutlet weak var auxPlaylistTableView: TableViewYouCanPressSpacebarOn!
    @IBOutlet weak var libraryTableScrollView: NSScrollView!
    @IBOutlet var columnVisibilityMenu: NSMenu!
    @IBOutlet weak var albumArtBox: NSBox!
    @IBOutlet weak var artworkToggle: NSButton!
    @IBOutlet weak var artCollectionView: NSCollectionView!
    @IBOutlet weak var queueScrollView: NSScrollView!
    @IBOutlet weak var queueButton: NSButton!
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var advancedFilterScrollView: NSScrollView!
    @IBOutlet weak var trackQueueTableView: TableViewYouCanPressSpacebarOn!
    @IBOutlet weak var progressBarView: ProgressBarView!
    @IBOutlet weak var shuffleButton: NSButton!
    @IBOutlet weak var trackListBox: NSBox!
    @IBOutlet weak var trackListTriangle: NSButton!
    @IBOutlet weak var headerCellView: NSTableCellView!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var songNameLabel: NSTextField!
    @IBOutlet weak var artistAlbumLabel: NSTextField!
    @IBOutlet weak var durationLabel: NSTextField!
    @IBOutlet weak var currentTimeLabel: NSTextField!
    @IBOutlet weak var theBox: NSBox!
    @IBOutlet weak var sourceListScrollView: NSScrollView!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet var sourceListTreeController: DragAndDropTreeController!
    @IBOutlet weak var sourceListView: SourceListThatYouCanPressSpacebarOn!
    @IBOutlet weak var albumArtView: DragAndDropImageView!
    @IBOutlet var artCollectionArrayController: NSArrayController!
    @IBOutlet weak var infoField: NSTextField!
    
    
    enum windowFocus {
        case playlist
        case library
    }
    
    var currentScrollView: NSScrollView?
    var currentTableView: TableViewYouCanPressSpacebarOn?
    var currentArrayController: DragAndDropArrayController?
    var currentAudioSource: SourceListItem?
    var sourceListDataSource: SourceListDataSource?
    var trackQueue = [Track]()
    var saved_search_bar_content: String?
    
    var tagWindowController: TagEditorWindow?
    var equalizerWindowController: EqualizerWindowController?
    var customFieldController: CustomFieldWindowController?
    var importWindowController: ImportWindowController?
    var delegate: AppDelegate?
    var timer: NSTimer?
    var lastTimerDate: NSDate?
    var secsPlayed: NSTimeInterval = 0
    var queue: AudioQueue = AudioQueue()
    var cur_view_title = "Music"
    var cur_source_title = "Music"
    var duration: Double?
    var paused: Bool? = true
    var is_initialized = false
    let trackQueueTableDelegate = TrackQueueTableViewDelegate()
    var shuffle = NSOnState
    var currentTrack: Track?
    var currentTrackView: TrackView?
    var currentNetworkTrack: NetworkTrack?
    var current_source_play_order: [Int]?
    var current_source_temp_shuffle: [Int]?
    var current_source_index: Int?
    var current_source_index_temp: Int?
    var infoString: String?
    var auxArrayController: NSArrayController?
    var focus: windowFocus = windowFocus.library
    var hasMusic: Bool = false
    var focusedColumn: NSTableColumn?
    var currentOrder: CachedOrder?
    var newCurrentOrder: NewCachedOrder?
    var asc: Bool?
    var is_streaming = false
    var currentLibrary: Library?
    
    let numberFormatter = NSNumberFormatter()
    let dateFormatter = NSDateComponentsFormatter()
    let sizeFormatter = NSByteCountFormatter()
    let fileManager = NSFileManager.defaultManager()
    var currentFilterPredicate: NSPredicate?
    
    lazy var cachedOrders: [CachedOrder]? = {
        let request = NSFetchRequest(entityName: "CachedOrder")
        do {
            let result = try self.managedContext.executeFetchRequest(request) as! [CachedOrder]
            return result
        } catch {
            print(error)
            return nil
        }
    }()
    
    lazy var rootSourceListItem: SourceListItem? = {
        let request = NSFetchRequest(entityName: "SourceListItem")
        do {
            let predicate = NSPredicate(format: "name == 'root'")
            request.predicate = predicate
            let result = try self.managedContext.executeFetchRequest(request) as! [SourceListItem]
            if result.count > 0 {
                return result[0]
            } else {
                return nil
            }
        } catch {
            print("error getting library: \(error)")
            return nil
        }
    }()
    
    //initialize managed object context
    lazy var managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    
    lazy var sourceListHeaderNodes: [SourceListItem]? = {()-> [SourceListItem]? in
        let fetchRequest = NSFetchRequest(entityName: "SourceListItem")
        let fetchPredicate = NSPredicate(format: "parent == nil")
        fetchRequest.predicate = fetchPredicate
        do {
            let results = try self.managedContext.executeFetchRequest(fetchRequest) as! [SourceListItem]
            for headerNode in results {
                if (headerNode as! SourceListItem).name == "Playlists" {
                    self.sourceListTreeController.playlistHeaderNode = headerNode
                } else if (headerNode as! SourceListItem).name == "Shared Libraries" {
                    self.sourceListTreeController.sharedHeaderNode = headerNode
                }
            }
            return results
        } catch {
            print("error getting header nodes: \(error)")
            return nil
        }
    }()
    
    var isVisibleDict = NSMutableDictionary()
    func populateIsVisibleDict() {
        if self.currentArrayController != nil {
            for track in self.currentArrayController?.arrangedObjects as! [TrackView] {
                isVisibleDict[(track).track!.id!] = true
            }
        }
    }

    
    
    
    //sort descriptors for source list
    var sourceListSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_order", ascending: true), NSSortDescriptor(key: "name", ascending: true)]
    
    var librarySortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "artist_sort_order", ascending: true)]
    
    @IBAction func importButtonPressed(sender: AnyObject) {
        importWindowController = ImportWindowController(windowNibName: "ImportWindowController")
        importWindowController?.mainWindowController = self
        importWindowController?.showWindow(self)
    }
    //the view coordinator
    var viewCoordinator: ViewCoordinator?
    var currentSourceListItem: SourceListItem?
    
    func searchFieldDidStartSearching(sender: NSSearchField) {
        print("search started searching called")
        print((currentArrayController?.arrangedObjects as! [TrackView]).count)
        viewCoordinator?.search_bar_content = searchField.stringValue
    }
    
    func searchFieldDidEndSearching(sender: NSSearchField) {
        print("search ended searching called")
        print((currentArrayController?.arrangedObjects as! [TrackView]).count)
        viewCoordinator?.search_bar_content = ""
    }
    
    
    var rootNode: SourceListNode?
    
    func createTree() {
        rootNode = SourceListNode(item: rootSourceListItem!)
        var nodesNotVisited = [SourceListItem]()
        var nodesAlreadyVisited = [SourceListNode]()
        var currentNode = rootNode
        for item in rootNode!.item.children! {
            nodesNotVisited.append(item as! SourceListItem)
        }
        while nodesNotVisited.isEmpty == false {
            let item = nodesNotVisited.removeFirst()
            let newNode = SourceListNode(item: item)
            if item.children != nil {
                for item in item.children! {
                    nodesNotVisited.append(item as! SourceListItem)
                }
            }
            nodesAlreadyVisited.append(newNode)
            if newNode.item.parent == currentNode?.item {
                currentNode?.children.append(newNode)
            } else {
                currentNode = nodesAlreadyVisited.removeFirst()
                if newNode.item.parent == currentNode!.item {
                    currentNode?.children.append(newNode)
                }
            }
        }
    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil {
            var count = 0
            for item in rootNode!.children {
                if item.children.count > 0 {
                    count += 1
                }
            }
            return count
        }
        let source = item as! SourceListNode
        return source.children.count
    }
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        let source = item as! SourceListNode
        if source.children.count > 0 {
            return true
        } else {
            return false
        }
    }
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil {
            if rootNode!.children[index].children.count > 0 {
                return rootNode!.children[index]
            } else {
                return rootNode!.children[index+1]
            }
        }
        let source = item as! SourceListNode
        let child = source.children[index]
        return child
    }
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        let source = item as! SourceListNode
        if (source.item.is_header == true) {
            let view = outlineView.makeViewWithIdentifier("HeaderCell", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            return view
        } else if source.item.playlist != nil {
            let view = outlineView.makeViewWithIdentifier("PlaylistCell", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            return view
        } else if source.item.is_network == true {
            let view = outlineView.makeViewWithIdentifier("NetworkLibraryCell", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            return view
        } else if source.item.playlist_folder != nil {
            let view = outlineView.makeViewWithIdentifier("SongCollectionFolder", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            return view
        } else if source.item.master_playlist != nil {
            let view = outlineView.makeViewWithIdentifier("MasterPlaylistCell", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            return view
        } else {
            let view = outlineView.makeViewWithIdentifier("PlaylistCell", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            return view
        }
    }
    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        print("fuck")
        let selection = (sourceListView.itemAtRow(sourceListView.selectedRow) as! SourceListNode).item
        self.currentSourceListItem = selection
        if selection.is_network == true {
            currentArrayController = auxTrackViewArrayController
            let server = self.delegate?.server
            server?.getDataForPlaylist(selection)
            librarySplitView.removeArrangedSubview(libraryTableScrollView)
            currentTableView = auxTableView
            librarySplitView.addArrangedSubview(auxTableScrollView)
            currentArrayController!.content = selection.playlist?.tracks
            
        } else if selection.playlist != nil {
            currentArrayController = auxTrackViewArrayController
            var id_array: [Int]?
            if (selection.playlist?.track_id_list != nil) {
                id_array = selection.playlist?.track_id_list as! [Int]
                auxTrackViewArrayController.fetchPredicate = NSPredicate(format: "track.id in %@", id_array!)
                updateCachedSortsForPlaylist(id_array!)
            }
            else {
                auxTrackViewArrayController.fetchPredicate = NSPredicate(format: "track.id in {}")
            }
            if librarySplitView.arrangedSubviews.contains(libraryTableScrollView) {
                librarySplitView.removeArrangedSubview(libraryTableScrollView)
            }
            currentTableView = auxTableView
            librarySplitView.addArrangedSubview(auxTableScrollView)
        } else {
            currentArrayController = trackViewArrayController
            if librarySplitView.subviews.contains(auxTableScrollView) {
                librarySplitView.removeArrangedSubview(auxTableScrollView)
            }
            currentTableView = libraryTableView
            librarySplitView.addArrangedSubview(libraryTableScrollView)
            updateCachedSorts()
            updateInfo()
        }
        if currentArrayController?.filterPredicate == nil {
            saved_search_bar_content = searchField.stringValue
            searchField.stringValue = ""
        } else {
            searchField.stringValue = saved_search_bar_content!
        }
    }

    //track queue, source logic
    @IBAction func toggleExpandQueue(sender: AnyObject) {
        if queueButton.state == NSOnState {
            queueScrollView.hidden = false
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "queueHidden")
        }
        else if queueButton.state == NSOffState {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "queueHidden")
            queueScrollView.hidden = true
        }

    }
    
    func checkQueueList(track_played: Track) {
        initializeArray(track_played)
        cur_source_title = cur_view_title
    }
    
    func initializeArray(track_played: Track) {
        print("initialize array called")
        /*if current_source_play_order!.count == 0 {
            current_source_play_order = (currentArrayController!.arrangedObjects as! [TrackView]).map( { return $0.track!.id as! Int} )
        }*/
        //trackQueueTableDelegate.updateContext(cur_view_title)
        let selectionItem = (sourceListView.itemAtRow(sourceListView.selectedRow) as! SourceListNode).item
        if selectionItem != currentAudioSource {
            current_source_play_order = (currentArrayController!.arrangedObjects as! [TrackView]).map( { return $0.track!.id as! Int} )
            currentAudioSource = selectionItem
        }
        if (shuffleButton.state == NSOnState) {
            print("shuffling")
            print(current_source_play_order!.count)
            current_source_temp_shuffle = current_source_play_order
            shuffle_array(&current_source_temp_shuffle!)
            current_source_temp_shuffle = current_source_temp_shuffle!.filter( {
                $0 != track_played.id
            })
            current_source_index = 0
        }
        else {
            current_source_index = (current_source_play_order?.indexOf(Int(track_played.id!)))! + 1
            print("current source index:" + String(current_source_index))
        }
        is_initialized = true
    }
    
    func getNextTrack() -> Track? {
        var id: Int?
        if current_source_play_order!.count == current_source_index {
            return nil
        }
        if (shuffleButton.state == NSOnState) {
            if current_source_index < current_source_temp_shuffle?.count {
                id = current_source_temp_shuffle![current_source_index!]
            } else {
                currentTrack = nil
                currentTrackView = nil
                return nil
            }
        }
        else {
            id = current_source_play_order![current_source_index!]
        }
        let next_track = getTrackWithID(id!)
        dispatch_async(dispatch_get_main_queue()) {
            self.currentTrack?.is_playing = false
            self.currentTrack = next_track
            self.self.currentTrackView = next_track?.view
            self.self.current_source_index! += 1
        }
        return next_track
    }
    
    func getTrackWithID(id: Int) -> Track? {
        let fetch_req = NSFetchRequest(entityName: "Track")
        let pred = NSPredicate(format: "id == \(id)")
        fetch_req.predicate = pred
        let result: Track? = {() -> Track? in
            do {
                return try (managedContext.executeFetchRequest(fetch_req) as! [Track])[0]
            }
            catch {
                return nil
            }
        }()
        return result
    }
    
    @IBAction func shuffleButtonPressed(sender: AnyObject) {
        if (shuffleButton.state == NSOnState) {
            NSUserDefaults.standardUserDefaults().setInteger(NSOnState, forKey: "shuffle")
            print("shuffling")
            current_source_temp_shuffle = current_source_play_order
            shuffle_array(&current_source_temp_shuffle!)
            if (currentTrack != nil) {
                current_source_temp_shuffle = current_source_temp_shuffle!.filter( {
                    $0 != currentTrack!.id
                })
            }
            current_source_index = 0
        }
        else {
            if currentTrack != nil {
                current_source_index = (current_source_play_order?.indexOf(Int(currentTrack!.id!)))! + 1
            } else {
            }
            print("current source index:" + String(current_source_index))
            NSUserDefaults.standardUserDefaults().setInteger(NSOffState, forKey: "shuffle")
        }
    }
    
    
    func jumpToSelection() {
        libraryTableView.scrollRowToVisible(libraryTableView.selectedRow)
    }
    
    @IBAction func addPlaylistButton(sender: AnyObject) {
        let playlist = NSEntityDescription.insertNewObjectForEntityForName("SongCollection", inManagedObjectContext: managedContext) as! SongCollection
        let playlistItem = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
        playlistItem.playlist = playlist
        playlistItem.name = "New Playlist"
        playlistItem.parent = sourceListTreeController.playlistHeaderNode
        sourceListView.reloadData()
        sourceListTreeController.setSelectionIndexPath(sourceListTreeController.indexPathOfObject(playlistItem))
        sourceListView.editColumn(0, row: sourceListView.selectedRow, withEvent: nil, select: true)
    }
    
    //player stuff
    @IBAction func makePlaylistFromTrackQueueSelection(sender: AnyObject) {
        trackQueueTableDelegate.makePlaylistFromSelection()
    }
    
    func tableViewDoubleClick(sender: AnyObject) {
        guard currentTableView!.selectedRow >= 0 else {
            return
        }
        let item = (currentArrayController?.arrangedObjects as! [TrackView])[currentTableView!.selectedRow].track
        playSong(item!)
    }
    
    @IBAction func toggleArtwork(sender: AnyObject) {
        if artworkToggle.state == NSOnState {
            albumArtBox.hidden = false
        }
        else {
            albumArtBox.hidden = true
        }
    }
    
    
    
    @IBAction func togglePastTracks(sender: AnyObject) {
        trackQueueTableDelegate.togglePastTracks()
    }
    
    @IBAction func createCustomField(sender: AnyObject) {
        self.customFieldController = CustomFieldWindowController(windowNibName: "CustomFieldWindowController")
        self.customFieldController?.mainWindow = self
        self.customFieldController?.showWindow(self)
    }
    
    func customFieldCreated(column: NSTableColumn) {
        let key = "arrangedObjects.user_defined_properties."
    }
    
    func showEqualizer() {
        print("show equalizer called")
        self.equalizerWindowController = EqualizerWindowController(windowNibName: "EqualizerWindowController")
        self.equalizerWindowController?.mainWindowController = self
        self.equalizerWindowController?.showWindow(self)
    }
    
    @IBAction func getInfoFromTableView(sender: AnyObject) {
        tagWindowController = TagEditorWindow(windowNibName: "TagEditorWindow")
        tagWindowController?.mainWindowController = self
        tagWindowController?.selectedTracks = (currentArrayController?.selectedObjects as! [TrackView]).map({return $0.track!})
        if tagWindowController?.selectedTracks?.count == 1 {
            tagWindowController?.currentTrack = tagWindowController!.selectedTracks![0]
        }
        tagWindowController?.showWindow(self)
    }
    
    @IBAction func addToQueueFromTableView(sender: AnyObject) {
        print(currentTableView!.selectedRow)
        let track_to_add = (currentArrayController?.arrangedObjects as! [TrackView])[currentTableView!.selectedRow].track!
        trackQueueTableDelegate.addTrackToQueue(track_to_add, context: cur_view_title, tense: 1)
        queue.addTrackToQueue(track_to_add, index: nil)
        trackQueue.append(track_to_add)
        checkQueueList(track_to_add)
    }
    
    @IBAction func playFromTableView(sender: AnyObject) {
        print(currentTableView!.selectedRow)
        let track_to_play = (currentArrayController?.arrangedObjects as! [TrackView])[currentTableView!.selectedRow].track!
        playSong(track_to_play)
        checkQueueList(track_to_play)
    }
    
    func playNetworkSong() {
        guard self.is_streaming == true else {return}
        queue.playNetworkImmediately(self.currentNetworkTrack!)
        initializeInterfaceForNewTrack()
        paused = false
    }
    
    func playSong(track: Track) {
        self.is_streaming = false
        if (paused == true && queue.is_initialized == true) {
            unpause()
        }
        //trackQueueTableDelegate.changeCurrentTrack(track, context: cur_source_title)
        checkQueueList(track)
        queue.playImmediately(track.location!)
        self.currentTrack?.is_playing = false
        self.currentTrack = track
        self.currentTrack?.is_playing = true
        self.currentTrackView = track.view
        paused = false
        currentTrack = track
    }
    
    func shuffle_array(inout array: [Int]) {
        guard array.count > 0 else {return}
        for i in 0..<array.count - 1 {
            let j = Int(arc4random_uniform(UInt32(array.count - i))) + i
            guard i != j else {continue}
            swap(&array[i], &array[j])
        }
    }
    
    func refreshTableView() {
        let column = focusedColumn
        focusedColumn = nil
    }
    
    func interpretSpacebarEvent() {
        if currentTrack != nil || currentNetworkTrack != nil {
            if paused == true {
                unpause()
            } else if paused == false {
                pause()
            }
        } else {
            if currentTableView?.selectedRow >= 0 {
                playSong((currentArrayController?.arrangedObjects as! [TrackView])[currentTableView!.selectedRow].track!)
            }
            else {
                var item: Track?
                if shuffleButton.state == NSOffState {
                    item = (currentArrayController?.arrangedObjects as! [TrackView])[0].track!
                } else if shuffleButton.state == NSOnState {
                    let random_index = Int(arc4random_uniform(UInt32(((currentArrayController?.arrangedObjects as! [TrackView]).count))))
                    item = (currentArrayController?.arrangedObjects as! [TrackView])[random_index].track!
                }
                playSong(item!)
            }
        }
    }
    
    func pause() {
        paused = true
        print("pause called")
        updateValuesUnsafe()
        queue.pause()
        timer!.invalidate()
    }
    
    func unpause() {
        print("unpause called")
        paused = false
        lastTimerDate = NSDate()
        queue.play()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(updateValuesSafe), userInfo: nil, repeats: true)
    }
    
    func seek(frac: Double) {
        queue.seek(frac)
    }
    
    func skip() {
        timer?.invalidate()
        queue.skip()
    }
    
    func skipBackward() {
        timer?.invalidate()
        queue.skip_backward()
    }
    
    override func keyDown(theEvent: NSEvent) {
        print(theEvent.keyCode)
        if (theEvent.keyCode == 36) {
            guard currentTableView!.selectedRow >= 0 else {
                return
            }
            let item = (currentArrayController?.arrangedObjects as! [TrackView])[currentTableView!.selectedRow].track
            playSong(item!)
        }
        else if theEvent.keyCode == 124 {
            self.currentTrack?.is_playing = false
            skip()
        }
        else if theEvent.keyCode == 123 {
            self.currentTrack?.is_playing = false
            skipBackward()
        }
    }
    
    
    @IBAction func playPressed(sender: AnyObject) {
        print("called")
        if (paused == true) {
            //if not initialized, play selected track/shuffle
            unpause()
            paused = false
        }
        else {
            pause()
            paused = true
        }
    }
    
    @IBAction func toggleFilterVisibility(sender: AnyObject) {
        if librarySplitView.arrangedSubviews.contains(advancedFilterScrollView) {
            print("library split view does indeed contain advanced filter")
            librarySplitView.removeArrangedSubview(advancedFilterScrollView)
        } else {
            librarySplitView.insertArrangedSubview(advancedFilterScrollView, atIndex: 0)
        }
    }
    
    @IBAction func testyThing(sender: AnyObject) {
        advancedFilterScrollView.hidden = false
    }
    
    func initializeInterfaceForNetworkTrack() {
        theBox.contentView?.hidden = false
        print("initializing interface for network track")
        self.progressBar.indeterminate = true
        self.progressBar.startAnimation(nil)
        self.songNameLabel.stringValue = "Initializing playback..."
        self.artistAlbumLabel.stringValue = ""
        self.durationLabel.stringValue = ""
        self.currentTimeLabel.stringValue = ""
    }
    
    func initializeInterfaceForNewTrack() {
        print("paused value in mwc is \(paused)")
        if self.progressBar.indeterminate == true {
            self.progressBar.stopAnimation(nil)
            self.progressBar.indeterminate = false
        }
        var aa_string = ""
        var name_string = ""
        switch self.is_streaming {
        case true:
            let the_track = self.currentNetworkTrack!
            name_string = the_track.name!
            if the_track.artist_name != nil {
                aa_string += self.currentNetworkTrack!.artist_name!
                if the_track.album_name != nil {
                    aa_string += " - " + the_track.album_name!
                }
            }
        case false:
            let the_track = self.currentTrack!
            initAlbumArt(the_track)
            name_string = the_track.name!
            if the_track.artist != nil {
                aa_string += (the_track.artist! as Artist).name!
                if the_track.album != nil {
                    aa_string += (" - " + (the_track.album! as Album).name!)
                }
            }
        }
        timer?.invalidate()
        theBox.contentView!.hidden = false
        songNameLabel.stringValue = name_string
        artistAlbumLabel.stringValue = aa_string
        duration = queue.duration_seconds
        durationLabel.stringValue = getTimeAsString(duration!)!
        currentTimeLabel.stringValue = getTimeAsString(0)!
        lastTimerDate = NSDate()
        secsPlayed = 0
        progressBar.hidden = false
        progressBar.doubleValue = 0
        startTimer()
    }
    
    func initializeColumnVisibilityMenu(tableView: NSTableView) {
        let savedColumns = NSUserDefaults.standardUserDefaults().dictionaryForKey(DEFAULTS_SAVED_COLUMNS_STRING)
        
        let menu = tableView.headerView?.menu
        for column in tableView.tableColumns {
            if column.identifier == "name" {
                continue
            }
            let menuItem = NSMenuItem(title: column.headerCell.title, action: #selector(toggleColumn), keyEquivalent: "")
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
        for column in self.currentTableView!.tableColumns {
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

    func startTimer() {
        //timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(updateValuesUnsafe), userInfo: nil, repeats: true)
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(updateValuesSafe), userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
    }
    
    func updateValuesUnsafe() {
        print("unsafe called")
        let nodeTime = queue.curNode.lastRenderTime
        let playerTime = queue.curNode.playerTimeForNodeTime(nodeTime!)
        print("unsafe update times")
        print(nodeTime)
        print(playerTime)
        var offset_thing: Double?
        if queue.track_frame_offset == nil {
            offset_thing = 0
        }
        else {
            offset_thing  = queue.track_frame_offset!
            print(offset_thing)
        }
        print(queue.total_offset_seconds)
        print(queue.total_offset_frames)
        let seconds = ((Double((playerTime?.sampleTime)!) + offset_thing!) / (playerTime?.sampleRate)!) - Double(queue.total_offset_seconds)
        let seconds_string = getTimeAsString(seconds)
        if (timer?.valid == true) {
            print("within valid clause")
            currentTimeLabel.stringValue = seconds_string!
            print(seconds_string)
            progressBar.doubleValue = (seconds * 100) / duration!
        }
        else {
            currentTimeLabel.stringValue = ""
            progressBar.doubleValue = 0
        }
        secsPlayed = seconds
        lastTimerDate = NSDate()
    }
    
    func updateValuesSafe() {
        let lastUpdateTime = lastTimerDate
        let currentTime = NSDate()
        let updateQuantity = currentTime.timeIntervalSinceDate(lastUpdateTime!)
        secsPlayed += updateQuantity
        let seconds_string = getTimeAsString(secsPlayed)
        if timer?.valid == true {
            currentTimeLabel.stringValue = seconds_string!
            progressBar.doubleValue = (secsPlayed * 100) / duration!
            progressBar.displayIfNeeded()
            lastTimerDate = currentTime
        } else {
            timer?.invalidate()
            //print("doingle")
            //currentTimeLabel.stringValue = ""
            //progressBar.doubleValue = 0
        }
    }
    
    func cleanUpBar() {
        print("other doingle")
        theBox.contentView!.hidden = true
        songNameLabel.stringValue = ""
        artistAlbumLabel.stringValue = ""
        duration = 0
        durationLabel.stringValue = ""
        currentTimeLabel.stringValue = ""
        progressBar.doubleValue = 100
    }
    
    func expandSourceView() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
            self.sourceListView.expandItem(nil, expandChildren: true)
            self.sourceListView.selectRowIndexes(NSIndexSet.init(index: 1),byExtendingSelection: false)
            print("executed this block")
            }
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &my_context {
            if keyPath! == "track_changed" {
                let before = NSDate()
                print("controller detects track change")
                currentTrack?.is_playing = false
                if trackQueue.count > 0 {
                    self.currentTrack = trackQueue.removeFirst()
                }
                timer?.invalidate()
                initializeInterfaceForNewTrack()
                currentTrack?.is_playing = true
                trackQueueTableDelegate.nextTrack()
                let after = NSDate()
                let since = after.timeIntervalSinceDate(before)
                print(since)
            }
            else if keyPath! == "done_playing" {
                print("controller detects finished playing")
                cleanUpBar()
            }
            else if keyPath! == "sortDescriptors" {
                if (currentSourceListItem == currentAudioSource) {
                    current_source_play_order = (currentArrayController?.arrangedObjects as! [TrackView]).map( {return $0.track!.id as! Int} )
                    if (is_initialized == true) {
                        current_source_index = (currentArrayController?.arrangedObjects as! [TrackView]).indexOf(currentTrackView!)
                        print("current source index set to \(current_source_index)")
                    }
                }
            }
            else if keyPath! == "filterPredicate" {
                print("filter predicate changed")
                if (currentSourceListItem == currentAudioSource) {
                    current_source_play_order = (currentArrayController?.arrangedObjects as! [TrackView]).map( {return $0.track!.id as! Int} )
                    if shuffleButton.state == NSOnState {
                        if currentArrayController?.filterPredicate != nil {
                            for track_id in current_source_play_order! {
                                self.isVisibleDict[track_id] = true
                            }
                            current_source_temp_shuffle = current_source_temp_shuffle?.filter({return (isVisibleDict[$0] as? Bool) == true})
                            isVisibleDict = [:]
                        } else {
                            current_source_temp_shuffle = current_source_play_order
                            shuffle_array(&current_source_temp_shuffle!)
                        }
                    } else {
                        if (is_initialized == true) {
                            current_source_index = (currentArrayController?.arrangedObjects as! [TrackView]).indexOf(currentTrackView!)
                            if current_source_index == nil {
                                current_source_index = 0
                            }
                            print("current source index set to \(current_source_index)")
                        }
                    }
                }
                print(current_source_play_order?.count)
                print(current_source_temp_shuffle?.count)
                //updateCachedSorts()
                //updateNewCachedSorts()
            } else if keyPath! == "arrangedObjects" {
                print("fuck everyting")
                updateInfo()
            }
        }
    }
    
    func updateCachedSortsForPlaylist(id_array: [Int]) {
        /*if self.librarySplitView.doesContain(self.auxPlaylistScrollView) {
            self.isVisibleDict = NSMutableDictionary()
            print(id_array.count)
            for track in id_array {
                self.isVisibleDict[track] = true
            }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                for sort in self.cachedOrders! {
                    sort.filtered_tracks = NSOrderedSet(array: sort.tracks!.filter( {return ((self.isVisibleDict[($0 as! Track).id!] as? Bool) == true)}) as! [Track])
                }
            }
        } else {
            print("nil fetch predicate")
            self.isVisibleDict = NSMutableDictionary()
            for sort in cachedOrders! {
                sort.filtered_tracks = nil
            }
            currentArray = currentOrder?.tracks
            print("done with stuff in nil filter predicate clause")
        }*/
    }
    
    func updateCachedSorts() {
        print("update cached sorts called")
        /*if self.currentFilterPredicate != nil || self.librarySplitView.doesContain(self.auxPlaylistScrollView) {
            print("there are \((currentArrayController?.arrangedObjects as! [Track]).count) objects to update")
            self.isVisibleDict = NSMutableDictionary()
            
            for track in (currentArrayController?.arrangedObjects as! [Track]) {
                self.isVisibleDict[track.id!] = true
            }
            for sort in cachedOrders! {
                sort.filtered_tracks = NSOrderedSet(array: sort.tracks!.filter( {return ((self.isVisibleDict[($0 as! Track).id!] as? Bool) == true)}) as! [Track])
            }
        } else {
            print("nil filter predicate")
            self.isVisibleDict = NSMutableDictionary()
            for sort in cachedOrders! {
                sort.filtered_tracks = nil
            }
            if currentOrder != nil {
                self.currentArray = self.currentOrder?.tracks
            }
            print(currentArray!.count)
            print("done with stuff in nil filter predicate clause")
        }*/
    }
    
    func updateInfo() {
        print("updateinfo called")
        if self.currentArrayController == nil {
            return
        }
        dispatch_async(dispatch_get_main_queue()) {
            let trackArray = (self.currentArrayController?.arrangedObjects as! [TrackView])
            let numItems = trackArray.count
            let totalSize = trackArray.map({return (($0.track)!.size!.longLongValue)}).reduce(0, combine: {$0 + $1})
            let totalTime = trackArray.map({return ($0.track)!.time!.doubleValue}).reduce(0, combine: {$0 + $1})
            let numString = self.numberFormatter.stringFromNumber(numItems)
            let sizeString = self.sizeFormatter.stringFromByteCount(totalSize)
            let timeString = self.dateFormatter.stringFromTimeInterval(totalTime/1000)
            dispatch_async(dispatch_get_main_queue()) {
                self.infoString = "\(numString!) items; \(timeString!); \(sizeString)"
                self.infoField.stringValue = self.self.infoString!
            }
        }
    }
    
    @IBAction func trackListTriangleClicked(sender: AnyObject) {
        /*let test = MediaServer()
        let dataTest = test.getSourceList()
        var jsonResult: [NSMutableDictionary]?
        do {
            jsonResult = try NSJSONSerialization.JSONObjectWithData(dataTest!, options: NSJSONReadingOptions.MutableContainers) as? [NSMutableDictionary]
        } catch {
            print("error: \(error)")
        }
        print(jsonResult)
        let playlistTest = test.getPlaylist(139755)
        do {
            jsonResult = try NSJSONSerialization.JSONObjectWithData(playlistTest!, options: NSJSONReadingOptions.MutableContainers) as? [NSMutableDictionary]
        } catch {
            print("error: \(error)")
        }
        print(jsonResult)*/
        //self.sourceListTreeController.checkNetworkedLibrary()
        sourceListView.reloadData()
    }
    
    //mark album art
    
    func initAlbumArt(track: Track) {
        if track.album != nil && track.album!.primary_art != nil {
            print("gonna get sum album art")
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let art = track.album!.primary_art
            let path = art?.artwork_location!
            let url = NSURL(string: path!)
            let image = NSImage(contentsOfURL: url!)
            dispatch_async(dispatch_get_main_queue()) {
                self.albumArtView.image = image
            }
            }
        }
        else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let fileHandler = self.delegate!.yeOldeFileHandler
                var artworkFound = false
                if NSUserDefaults.standardUserDefaults().boolForKey("checkEmbeddedArtwork") == true {
                    print("checking mp3 for embedded art")
                    let artwork = fileHandler!.getArtworkFromFile(track.location!)
                    if artwork != nil {
                        let albumDirectoryURL = NSURL(string: track.location!)!.URLByDeletingLastPathComponent!
                        if addPrimaryArtForTrack(track, art: artwork!, albumDirectoryURL: albumDirectoryURL) != nil {
                            dispatch_async(dispatch_get_main_queue()) {
                                do {try self.managedContext.save()}catch {print(error)}
                                self.initAlbumArt(track)
                            }
                            artworkFound = true
                        }
                    }
                }
                if NSUserDefaults.standardUserDefaults().boolForKey(DEFAULTS_CHECK_ALBUM_DIRECTORY_FOR_ART_STRING) == true {
                    let imageURL = fileHandler!.searchAlbumDirectoryForArt(track)
                    if imageURL != nil {
                        let artwork = NSData(contentsOfURL: imageURL!)
                        if artwork != nil {
                            let albumDirectoryURL = NSURL(string: track.location!)!.URLByDeletingLastPathComponent!
                            if addPrimaryArtForTrack(track, art: artwork!, albumDirectoryURL: albumDirectoryURL) != nil {
                                dispatch_async(dispatch_get_main_queue()) {
                                    do {try self.managedContext.save()}catch {print(error)}
                                    self.initAlbumArt(track)
                                }
                                artworkFound = true
                            }
                        }
                    }
                }
                if artworkFound == false {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.albumArtView.image = nil
                    }
                }
            }
        }
        /*if track.album?.other_art != nil {
            artCollectionView.hidden = false
            artCollectionView.dataSource = artCollectionArrayController
            artCollectionArrayController.content = track.album!.other_art!.art!.mutableCopy().array
            
        }*/
    }
    
    override func awakeFromNib() {
        /*sourceListView.expandItem(nil, expandChildren: true)
        sourceListView.selectRowIndexes(NSIndexSet.init(index: 1), byExtendingSelection: false)
        dispatch_async(dispatch_get_main_queue()) {
            self.sourceListView.expandItem(nil, expandChildren: exptrue)
            self.sourceListView.selectRowIndexes(NSIndexSet.init(index: 1), byExtendingSelection: false)
            print("executed this block")
        }*/
    }
    
    
    override func windowDidLoad() {
        numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        dateFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Full
        print(hasMusic)
        //hasMusic = true
        if (hasMusic == false) {
            librarySplitView.addArrangedSubview(noMusicView)
            noMusicView.hidden = false
            libraryTableScrollView.hidden = true
            sourceListView.hidden = true
        } else {
            self.createTree()
            sourceListView.setDelegate(self)
            sourceListView.setDataSource(self)
        }
        queue.mainWindowController = self
        //shuffle = shuffleButton.state
        progressBar.displayedWhenStopped = true
        progressBarView.progressBar = progressBar
        progressBarView.mainWindowController = self
        sourceListScrollView.drawsBackground = false
        theBox.contentView?.hidden = true
        /*theBox.boxType = .Custom
        theBox.borderType = .BezelBorder
        theBox.borderWidth = 1.1
        theBox.cornerRadius = 3*/
        //theBox.fillColor = NSColor(patternImage: NSImage(named: "Gradient")!)
        libraryTableView.doubleAction = "tableViewDoubleClick:"
        
        //mark mtvds
        /*if hasMusic == true {
            currentOrder = cachedOrders?[0]
            currentArray = currentOrder?.tracks
            libraryTableView.setDataSource(self)
            libraryTableView.setDelegate(self)
        }*/
        //auxPlaylistTableView.doubleAction = "tableViewDoubleClick:"
        print(libraryTableView.registeredDraggedTypes)
        sourceListView.mainWindowController = self
        libraryTableView.mainWindowController = self
        //auxPlaylistTableView.mainWindowController = self
        searchField.delegate = self
        //libraryTableView.tableColumns[4].sortDescriptorPrototype = NSSortDescriptor(key: "artist_sort_order", ascending: true)
        //libraryTableView.tableColumns[5].sortDescriptorPrototype = NSSortDescriptor(key: "album_sort_order", ascending: true)
        queue.addObserver(self, forKeyPath: "track_changed", options: .New, context: &my_context)
        queue.addObserver(self, forKeyPath: "done_playing", options: .New, context: &my_context)
        trackViewArrayController.addObserver(self, forKeyPath: "arrangedObjects", options: .New, context: &my_context)
        auxTrackViewArrayController.addObserver(self, forKeyPath: "arrangedObjects", options: .New, context: &my_context)
        trackViewArrayController.addObserver(self, forKeyPath: "filterPredicate", options: .New, context: &my_context)
        auxTrackViewArrayController.addObserver(self, forKeyPath: "filterPredicate", options: .New, context: &my_context)
        super.windowDidLoad()
        if (hasMusic == true) {
            //print(cachedOrders![0])
        }
        albumArtView.mainWindowController = self
        trackQueueTableView.setDataSource(trackQueueTableDelegate)
        trackQueueTableView.setDelegate(trackQueueTableDelegate)
        trackQueueTableDelegate.tableView = trackQueueTableView
        let currentColumn = NSUserDefaults.standardUserDefaults().objectForKey("lastColumn")
        let currentAsc = NSUserDefaults.standardUserDefaults().boolForKey("currentAsc")
        print("retrieving \(currentColumn) from cache")
        trackQueueTableView.registerForDraggedTypes(["Track", "public.TrackQueueView"])
        trackQueueTableDelegate.mainWindowController = self
        //queueScrollView.hidden = true
        currentTableView = libraryTableView
        volumeSlider.continuous = true
        artCollectionView.hidden = true
        //predicateEditor.rowTemplates = rowTemplates
        //predicateEditor.addRow(nil)
        self.window!.titleVisibility = NSWindowTitleVisibility.Hidden
        self.window!.titlebarAppearsTransparent = true
        print("count: \(current_source_play_order?.count)")
        //currentArrayController?.rearrangeObjects()
        /*dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                self.sourceListView.expandItem(nil, expandChildren: true)
            }
        }*/
        currentTableView = libraryTableView
        libraryTableView.setDelegate(trackViewArrayController)
        libraryTableView.setDataSource(trackViewArrayController)
        columnVisibilityMenu.delegate = self
        self.initializeColumnVisibilityMenu(self.libraryTableView)
        let mainLibraryIndexes = [0, 0]
        let mainLibraryIndexPath = NSIndexPath(indexes: mainLibraryIndexes, length: 2)
        //sourceListTreeController.content = sourceListHeaderNodes
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "findAlbumArtwork")
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "checkEmbeddedArtwork")
        NSUserDefaults.standardUserDefaults().setObject("http://localhost:20012/doingles", forKey: "testIP")
        NSUserDefaults.standardUserDefaults().setObject("http://localhost:20012/list", forKey: "testIPList")
        //self.sourceListTreeController.checkNetworkedLibrary()
        self.populateIsVisibleDict()
        self.initializeColumnVisibilityMenu(self.currentTableView!)
        /*libraryTableView.setDelegate(trackViewArrayController)
        libraryTableView.setDataSource(trackViewArrayController)*/
        auxTableView.mainWindowController = self
        auxTrackViewArrayController.mainWindow = self
        libraryTableView.reloadData()
        self.currentArrayController = trackViewArrayController
        current_source_play_order = (currentArrayController!.arrangedObjects as! [TrackView]).map( {return $0.track!.id as! Int})
        sourceListView.expandItem(nil, expandChildren: true)
        let indexSet = NSIndexSet(index: 1)
        sourceListView.selectRowIndexes(indexSet, byExtendingSelection: false)
        print("fuck")
    }
}
