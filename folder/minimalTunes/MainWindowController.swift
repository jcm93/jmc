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


class MainWindowController: NSWindowController, NSOutlineViewDelegate, NSSearchFieldDelegate, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var trackQueueTableView: NSTableView!
    @IBOutlet weak var progressBarView: dragAndDropView!
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
    @IBOutlet weak var libraryTableScrollView: NSScrollView!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet var sourceListTreeController: NSTreeController!
    @IBOutlet var tableViewArrayController: NSArrayController!
    @IBOutlet weak var sourceListView: SourceListThatYouCanPressSpacebarOn!
    @IBOutlet weak var libraryTableView: TableViewYouCanPressSpacebarOn!
    
    var timer: NSTimer?
    var queue: AudioQueue = AudioQueue()
    var cur_view_title = "Music"
    var cur_source_title = "Music"
    var duration: Double?
    var paused = true
    var is_initialized = false
    let trackQueueTableDelegate = TrackQueueTableViewDelegate()
    var shuffle = NSOnState
    var currentTrack: Track?
    var current_source_play_order: [Int]?
    var current_source_temp_shuffle: [Int]?
    var current_source_index: Int?
    var current_source_index_temp: Int?
    
    /*override var acceptsFirstResponder: Bool {return true}
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        return true
    }*/
    
    //initialize managed object context
    lazy var managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    
    lazy var idArray: [Int] = {
        let fetch_request = NSFetchRequest(entityName: "MasterIDArray")
        var result = [Int]()
        do {
            let thing = try self.managedContext.executeFetchRequest(fetch_request) as! [MasterIDArray]
            result = thing[0].array as! [Int]
        }
        catch {
            print("err")
        }
        return result
    }()
    
    //sort descriptors for source list
    var sourceListSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_order", ascending: true), NSSortDescriptor(key: "name", ascending: true)]
    
    var librarySortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "artist_sort_order", ascending: true)]
    
    //the view coordinator
    var viewCoordinator: ViewCoordinator?
    var currentSourceListItem: SourceListItem?
    
    func searchFieldDidStartSearching(sender: NSSearchField) {
        viewCoordinator?.search_bar_content = searchField.stringValue
    }
    func searchFieldDidEndSearching(sender: NSSearchField) {
        viewCoordinator?.search_bar_content = ""
    }
    
    //outline view stuff
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        if (item.representedObject!! as! SourceListItem).is_header == true {
            return outlineView.makeViewWithIdentifier("HeaderCell", owner: self)
        }
        else if (item.representedObject!! as! SourceListItem).playlist != nil {
            return outlineView.makeViewWithIdentifier("PlaylistCell", owner: self)
        }
        else if (item.representedObject!! as! SourceListItem).network_library != nil {
            return outlineView.makeViewWithIdentifier("NetworkLibraryCell", owner: self)
        }
        else if (item.representedObject!! as! SourceListItem).playlist_folder != nil {
            return outlineView.makeViewWithIdentifier("SongCollectionFolder", owner: self)
        }
        else if (item.representedObject!! as! SourceListItem).master_playlist != nil {
            return outlineView.makeViewWithIdentifier("MasterPlaylistCell", owner: self)
        }
        else {
            return outlineView.makeViewWithIdentifier("PlaylistCell", owner: self)
        }
    }
    
    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        //controls the library view; remembers details of views previously visited
        viewCoordinator?.filter_predicate = tableViewArrayController.filterPredicate
        viewCoordinator?.search_bar_content = searchField.stringValue
        viewCoordinator?.sort_descriptors = tableViewArrayController.sortDescriptors
        viewCoordinator?.scroll_location = libraryTableScrollView.contentView.bounds.origin.y
        viewCoordinator?.selected_rows = libraryTableView.selectedRowIndexes
        print(libraryTableView.selectedRowIndexes)
        let view_coordinator_request = NSFetchRequest(entityName: "ViewCoordinator")
        let selection = (sourceListTreeController.selectedNodes[0].representedObject! as! SourceListItem)
        let selection_name = selection.name!
        cur_view_title = selection_name
        view_coordinator_request.predicate = NSPredicate(format: "source_list_item_name == '\(selection_name)'")
        let results: [ViewCoordinator]?
        do {
            results = try managedContext.executeFetchRequest(view_coordinator_request) as! [ViewCoordinator]
            if results!.count != 0 {
                let result = results![0]
                print(result)
                if (result.fetch_predicate != nil) {
                    tableViewArrayController.fetchPredicate = result.fetch_predicate as! NSPredicate
                }
                else {
                    tableViewArrayController.fetchPredicate = nil
                }
                if result.search_bar_content != nil {
                    searchField.stringValue = result.search_bar_content!
                }
                if result.filter_predicate != nil {
                    tableViewArrayController.filterPredicate = result.filter_predicate as! NSPredicate
                }
                else {
                    searchField.stringValue = ""
                    tableViewArrayController.filterPredicate = nil
                }
                if (result.sort_descriptors != nil) {
                    tableViewArrayController.sortDescriptors = result.sort_descriptors as! [NSSortDescriptor]
                }
                if (result.scroll_location != nil) {
                    print("scrollin to \(result.scroll_location as! CGFloat)")
                    libraryTableScrollView.contentView.scrollToPoint(CGPoint(x: CGFloat(0.0), y: result.scroll_location as! CGFloat))
                }
                if result.selected_rows != nil {
                    libraryTableView.selectRowIndexes(result.selected_rows as! NSIndexSet, byExtendingSelection: false)
                }
                viewCoordinator = result
            }
            else {
                searchField.stringValue = ""
                tableViewArrayController.filterPredicate = nil
                let newCoordinator = NSEntityDescription.insertNewObjectForEntityForName("ViewCoordinator", inManagedObjectContext: managedContext) as! ViewCoordinator
                newCoordinator.source_list_item_name = selection_name
                if selection.playlist != nil {
                    let id_array = selection.playlist!.track_id_list
                    if id_array != nil {
                        newCoordinator.fetch_predicate = NSPredicate.init(format: "id in %@", id_array!)
                        tableViewArrayController.fetchPredicate = newCoordinator.fetch_predicate as! NSPredicate
                        current_source_play_order = id_array as! [Int]
                    }
                }
                else {
                    newCoordinator.fetch_predicate = nil
                    tableViewArrayController.fetchPredicate = nil
                }
                viewCoordinator = newCoordinator
            }
        }
        catch {
            print("unhelpful error message")
        }
    }

    //track queue, source logic
    func checkQueueList(track_played: Track) {
        if (is_initialized == true) {
            initializeArray(track_played)
        }
        else {
            cur_source_title = cur_view_title
            initializeArray(track_played)
        }
    }
    
    func initializeArray(track_played: Track) {
        print("initialize array called")
        if (shuffleButton.state == NSOnState) {
            print("shuffling")
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
        if (shuffleButton.state == NSOnState) {
            id = current_source_temp_shuffle![current_source_index!]
        }
        else {
            id = current_source_play_order![current_source_index!]
        }
        let next_track = getTrackWithID(id!)
        currentTrack = next_track
        current_source_index! += 1
        trackQueueTableDelegate.changeCurrentTrack(next_track!, context: cur_source_title)
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
        initializeArray(currentTrack!)
    }
    
    
    //player stuff
    func tableViewDoubleClick(sender: AnyObject) {
        guard libraryTableView.selectedRow >= 0 , let item = (tableViewArrayController.selectedObjects) else {
            return
        }
        playSong(item[0] as! Track)
    }
    
    @IBAction func addToQueueFromTableView(sender: AnyObject) {
        print(libraryTableView.selectedRow)
        let track_to_add = tableViewArrayController.arrangedObjects.objectAtIndex(libraryTableView.selectedRow) as! Track
        trackQueueTableDelegate.addTrackToQueue(track_to_add, context: cur_view_title)
        queue.addTrackToQueue(track_to_add, index: nil)
        checkQueueList(track_to_add)
    }
    @IBAction func playFromTableView(sender: AnyObject) {
        print(libraryTableView.selectedRow)
        let track_to_play = tableViewArrayController.arrangedObjects.objectAtIndex(libraryTableView.selectedRow) as! Track
        playSong(track_to_play)
        checkQueueList(track_to_play)
    }
    func playSong(track: Track) {
        if (paused == true && queue.is_initialized == true) {
            unpause()
        }
        trackQueueTableDelegate.changeCurrentTrack(track, context: cur_source_title)
        checkQueueList(track)
        queue.playImmediately(track)
        initializePlayerBarForNewTrack()
        currentTrack = track
    }
    
    func shuffle_array(inout array: [Int]) {
        for i in 0..<array.count - 1 {
            let j = Int(arc4random_uniform(UInt32(array.count - i))) + i
            guard i != j else {continue}
            swap(&array[i], &array[j])
        }
    }
    
    func pause() {
        timer?.invalidate()
        paused = true
        queue.pause()
    }
    
    func unpause() {
        paused = false
        queue.play()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(updateValues), userInfo: nil, repeats: true)
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
            guard libraryTableView.selectedRow >= 0 , let item = (tableViewArrayController.selectedObjects) else {
                return
            }
            playSong(item[0] as! Track)
            initializePlayerBarForNewTrack()
        }
        else if theEvent.keyCode == 124 {
            skip()
        }
        else if theEvent.keyCode == 123 {
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
    
    func updateValues() {
        let nodeTime = queue.curNode.lastRenderTime
        let playerTime = queue.curNode.playerTimeForNodeTime(nodeTime!)
        var offset_thing: Double?
        if queue.track_frame_offset == nil {
            offset_thing = 0
        }
        else {
            offset_thing  = queue.track_frame_offset!
        }
        let seconds = ((Double((playerTime?.sampleTime)!) + offset_thing!) / (playerTime?.sampleRate)!) - Double(queue.total_offset_seconds)
        let seconds_string = queue.getTimeAsString(seconds)
        if (timer?.valid == true) {
            currentTimeLabel.stringValue = seconds_string
            progressBar.doubleValue = (seconds * 100) / duration!
        }
        else {
            currentTimeLabel.stringValue = ""
            progressBar.doubleValue = 0
        }
    }
    
    func initializePlayerBarForNewTrack() {
        timer?.invalidate()
        theBox.contentView!.hidden = false
        if (paused == true) {
            paused = false
        }
        let the_track = queue.currentTrack!
        if the_track.name != nil {
            songNameLabel.stringValue = the_track.name!
        }
        var aa_string = ""
        if the_track.artist != nil {
            aa_string += (the_track.artist! as Artist).name!
            if the_track.album != nil {
                aa_string += (" - " + (the_track.album! as Album).name!)
            }
        }
        artistAlbumLabel.stringValue = aa_string
        duration = queue.duration_seconds
        durationLabel.stringValue = queue.getTimeAsString(duration!)
        currentTimeLabel.stringValue = queue.getTimeAsString(0)
        progressBar.hidden = false
        progressBar.doubleValue = 0
        startTimer()
    }
    
    func startTimer() {
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(updateValues), userInfo: nil, repeats: true)
    }
    
    func cleanUpBar() {
        theBox.contentView!.hidden = true
        if (paused == true) {
            paused = false
        }
        songNameLabel.stringValue = ""
        artistAlbumLabel.stringValue = ""
        duration = 0
        durationLabel.stringValue = ""
        currentTimeLabel.stringValue = ""
        progressBar.doubleValue = 100
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &my_context {
            if keyPath! == "track_changed" {
                print("controller detects track change")
                timer?.invalidate()
                initializePlayerBarForNewTrack()
            }
            else if keyPath! == "done_playing" {
                print("controller detects finished playing")
                cleanUpBar()
            }
            else if keyPath! == "sortDescriptors" {
                current_source_play_order = (tableViewArrayController.arrangedObjects as! [Track]).map( {return $0.id as! Int} )
                if (is_initialized == true) {
                    current_source_index = (tableViewArrayController.arrangedObjects as! [Track]).indexOf(currentTrack!)
                    print("current source index set to \(current_source_index)")
                }
            }
        }
    }

    @IBAction func trackListTriangleClicked(sender: AnyObject) {
        if trackListBox.hidden == true {
            trackListBox.hidden = false
        }
        else if trackListBox.hidden == false {
            trackListBox.hidden = true
        }
        
    }
    
    
    override func windowDidLoad() {
        queue.mainWindowController = self
        shuffle = shuffleButton.state
        progressBar.displayedWhenStopped = true
        progressBarView.progressBar = progressBar
        progressBarView.mainWindowController = self
        sourceListView.setDelegate(self)
        sourceListScrollView.drawsBackground = false
        theBox.contentView?.hidden = true
        theBox.boxType = .Custom
        theBox.borderType = .BezelBorder
        theBox.borderWidth = 1.1
        theBox.cornerRadius = 3
        theBox.fillColor = NSColor(patternImage: NSImage(named: "Gradient")!)
        libraryTableView.doubleAction = "tableViewDoubleClick:"
        sourceListView.mainWindowController = self
        libraryTableView.mainWindowController = self
        searchField.delegate = self
        libraryTableView.tableColumns[3].sortDescriptorPrototype = NSSortDescriptor(key: "artist_sort_order", ascending: true)
        libraryTableView.tableColumns[4].sortDescriptorPrototype = NSSortDescriptor(key: "album_sort_order", ascending: true)
        libraryTableView.setDelegate(self)
        //queue.addObserver(self, forKeyPath: "is_initialized", options: .New, context: &my_context)
        queue.addObserver(self, forKeyPath: "track_changed", options: .New, context: &my_context)
        queue.addObserver(self, forKeyPath: "done_playing", options: .New, context: &my_context)
        tableViewArrayController.addObserver(self, forKeyPath: "sortDescriptors", options: .New, context: &my_context)
        super.windowDidLoad()
        dispatch_async(dispatch_get_main_queue()) {
            self.sourceListView.expandItem(nil, expandChildren: true)
        }
        trackQueueTableView.setDataSource(trackQueueTableDelegate)
        trackQueueTableView.setDelegate(trackQueueTableDelegate)
        trackQueueTableDelegate.tableView = trackQueueTableView
        current_source_play_order = idArray
    }
    
}
