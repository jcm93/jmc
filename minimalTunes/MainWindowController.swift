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

import MultipeerConnectivity


class MainWindowController: NSWindowController, NSSearchFieldDelegate {
    
    
    //target views
    //@IBOutlet weak var libraryTableTargetView: NSView!
    @IBOutlet weak var trackQueueTargetView: NSView!
    @IBOutlet weak var librarySplitView: NSSplitView!
    @IBOutlet var noMusicView: NSView!
    @IBOutlet weak var artworkTargetView: NSView!
    @IBOutlet weak var sourceListTargetView: NSView!
    
    //interface elements
    @IBOutlet weak var advancedSearchToggle: NSButton!
    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var repeatButton: NSButton!
    @IBOutlet weak var parentSplitView: NSSplitView!
    @IBOutlet weak var sourceAreaSplitView: NSSplitView!
    @IBOutlet weak var bitRateFormatter: BitRateFormatter!
    @IBOutlet weak var queueButton: NSButton!
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var progressBarView: ProgressBarView!
    @IBOutlet weak var shuffleButton: NSButton!
    @IBOutlet weak var trackListTriangle: NSButton!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var songNameLabel: NSTextField!
    @IBOutlet weak var artistAlbumLabel: NSTextField!
    @IBOutlet weak var durationLabel: NSTextField!
    @IBOutlet weak var currentTimeLabel: NSTextField!
    @IBOutlet weak var theBox: NSBox!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet var artCollectionArrayController: NSArrayController!
    @IBOutlet weak var infoField: NSTextField!
    
    //subview controllers
    var sourceListViewController: SourceListViewController?
    var trackQueueViewController: TrackQueueViewController?
    var otherLocalTableViewControllers = NSMutableDictionary()
    var otherSharedTableViewControllers = NSMutableDictionary()
    var currentTableViewController: LibraryTableViewController?
    var libraryTableViewController: LibraryTableViewController?
    var albumArtViewController: AlbumArtViewController?
    var advancedFilterViewController: AdvancedFilterViewController?
    
    //subordinate window controllers
    var tagWindowController: TagEditorWindow?
    var equalizerWindowController: EqualizerWindowController?
    var importWindowController: ImportWindowController?
    
    //other variables
    var saved_search_bar_content: String?
    var networkedLibraries = NSMutableDictionary()
    var currentAudioSource: SourceListItem?
    var currentSourceListItem: SourceListItem?
    var networkSongWasPlayed = false
    var delegate: AppDelegate?
    var timer: NSTimer?
    var lastTimerDate: NSDate?
    var secsPlayed: NSTimeInterval = 0
    var cur_view_title = "Music"
    var cur_source_title = "Music"
    var duration: Double?
    var paused: Bool? = true
    var is_initialized = false
    var shuffle: Bool = NSUserDefaults.standardUserDefaults().boolForKey(DEFAULTS_SHUFFLE_STRING)
    var will_repeat: Bool = NSUserDefaults.standardUserDefaults().boolForKey(DEFAULTS_REPEAT_STRING)
    var currentTrack: Track?
    var currentTrackView: TrackView?
    var currentNetworkTrack: Track?
    var currentNetworkTrackView: TrackView?
    //var current_source_play_order: PlaylistOrderObject?
    var current_source_temp_shuffle: PlaylistOrderObject?
    //var current_source_unshuffled_play_order: PlaylistOrderObject?
    //var current_source_index: Int?
    var currentPlaylistOrderObject: PlaylistOrderObject?
    var current_source_index_temp: Int?
    var infoString: String?
    var auxArrayController: NSArrayController?
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
    var isDoneWithSkipOperation = true
    var isDoneWithSkipBackOperation = true
    var durationShowsTimeRemaining = false
    var viewHasLoaded = false
    
    lazy var cachedOrders: [CachedOrder]? = {
        let request = NSFetchRequest(entityName: "CachedOrder")
        do {
            let result = try managedContext.executeFetchRequest(request) as! [CachedOrder]
            return result
        } catch {
            print(error)
            return nil
        }
    }()
    
    //initialize managed object context
    
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
    
    func searchFieldDidStartSearching(sender: NSSearchField) {
        print("search started searching called")
        viewCoordinator?.search_bar_content = searchField.stringValue
    }
    

    @IBAction func searchFieldAction(sender: AnyObject) {
        print("search field action called")
        let searchFieldContent = searchField.stringValue
        let searchTokens = searchFieldContent.componentsSeparatedByString(" ").filter({return $0 != ""})
        var subPredicates = [NSPredicate]()
        for token in searchTokens {
            //not accepted by NSPredicateEditor
            //let newPredicate = NSPredicate(format: "ANY {track.name, track.artist.name, track.album.name, track.composer.name, track.comments, track.genre.name} contains[cd] %@", token)
            //accepted by NSPredicateEditor
            let newPredicate = NSPredicate(format: "track.name contains[cd] %@ OR track.artist.name contains[cd] %@ OR track.album.name contains[cd] %@ OR track.composer.name contains[cd] %@ OR track.comments contains[cd] %@ OR track.genre.name contains[cd] %@", token, token, token, token, token, token)
            subPredicates.append(newPredicate)
        }
        if subPredicates.count > 0 {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
            currentTableViewController?.trackViewArrayController.filterPredicate = predicate
            currentTableViewController?.searchString = searchFieldContent
        } else {
            currentTableViewController?.trackViewArrayController.filterPredicate = nil
            currentTableViewController?.searchString = nil
        }
    }
    
    func searchFieldDidEndSearching(sender: NSSearchField) {
        print("search ended searching called")
        viewCoordinator?.search_bar_content = ""
    }
    
    func networkPlaylistCallback(id: Int, idList: [Int]) {
        print("made it to network playlist callback")
        guard self.otherSharedTableViewControllers.objectForKey(id) != nil else {return}
        let playlistViewController = otherSharedTableViewControllers.objectForKey(id) as! LibraryTableViewControllerCellBased
        playlistViewController.trackViewArrayController.fetchPredicate = NSPredicate(format: "track.id in %@ AND track.is_network == %@", idList, NSNumber(booleanLiteral: true))
        playlistViewController.initializeForPlaylist()
        playlistViewController.tableView.reloadData()
    }
    
    func createPlaylistViewController(item: SourceListItem) -> LibraryTableViewController {
        let newPlaylistViewController = LibraryTableViewControllerCellBased(nibName: "LibraryTableViewControllerCellBased", bundle: nil)
        newPlaylistViewController?.mainWindowController = self
        newPlaylistViewController?.playlist = item.playlist
        newPlaylistViewController?.item = item
        return newPlaylistViewController!
    }
    
    func addObserversAndInitializeNewTableView(table: LibraryTableViewController, item: SourceListItem) {
        table.trackViewArrayController.addObserver(self, forKeyPath: "arrangedObjects", options: .New, context: &my_context)
        table.trackViewArrayController.addObserver(self, forKeyPath: "filterPredicate", options: .New, context: &my_context)
        table.trackViewArrayController.addObserver(self, forKeyPath: "sortDescriptors", options: .New, context: &my_context)
        table.item = item
        table.mainWindowController = self
    }
    
    func switchToPlaylist(item: SourceListItem) {
        if item == currentSourceListItem {return}
        currentTableViewController?.hasInitialized = false
        trackQueueViewController?.currentSourceListItem = item
        currentSourceListItem = item
        let id = item.playlist?.id
        if id != nil {
            currentTableViewController?.view.removeFromSuperview()
        } else {
            switchToLibrary()
            return
        }
        if otherLocalTableViewControllers.objectForKey(id!) != nil && item.is_network != true {
            let playlistViewController = otherLocalTableViewControllers.objectForKey(id!) as! LibraryTableViewController
            librarySplitView.addArrangedSubview(playlistViewController.view)
            currentTableViewController = playlistViewController
            currentTableViewController?.initializeForPlaylist()
            updateInfo()
        }
        else if otherSharedTableViewControllers.objectForKey(id!) != nil && item.is_network == true {
            let playlistViewController = otherSharedTableViewControllers.objectForKey(id!) as! LibraryTableViewController
            librarySplitView.addArrangedSubview(playlistViewController.view)
            currentTableViewController = playlistViewController
            currentTableViewController?.initializeForPlaylist()
            updateInfo()
        }
        else {
            let newPlaylistViewController = createPlaylistViewController(item)
            if item.is_network == true {
                self.otherSharedTableViewControllers[id!] = newPlaylistViewController
            } else {
                self.otherLocalTableViewControllers[id!] = newPlaylistViewController
            }
            librarySplitView.addArrangedSubview(newPlaylistViewController.view)
            addObserversAndInitializeNewTableView(newPlaylistViewController, item: item)
            currentTableViewController = newPlaylistViewController
        }
        if currentTableViewController?.advancedFilterVisible == true {
            showAdvancedFilter()
        } else {
            hideAdvancedFilter()
        }
        populateSearchBar()
        currentTableViewController?.tableView.reloadData()
    }
    
    func populateSearchBar() {
        if currentTableViewController?.searchString != nil {
            searchField.stringValue = currentTableViewController!.searchString!
        } else {
            searchField.stringValue = ""
        }
    }
    
    func jumpToCurrentSong() {
        currentTableViewController?.jumpToCurrentSong(currentTrack)
    }
    
    func switchToLibrary() {
        libraryTableViewController!.item = currentSourceListItem!
        if !librarySplitView.arrangedSubviews.contains(libraryTableViewController!.view) {
            print("adding library view to split view")
            currentTableViewController?.view.removeFromSuperview()
            librarySplitView.addArrangedSubview(libraryTableViewController!.view)
            currentTableViewController = libraryTableViewController
            if currentTableViewController?.advancedFilterVisible == true {
                showAdvancedFilter()
            } else {
                hideAdvancedFilter()
            }
            populateSearchBar()
            currentTableViewController?.tableView.reloadData()
            updateInfo()
        }
    }
    
    @IBAction func volumeDidChange(sender: AnyObject) {
        print("volume did change called")
        let newVolume = (sender as! NSSlider).floatValue
        delegate?.audioModule.changeVolume(newVolume)
    }
    //track queue, source logic
    @IBAction func toggleExpandQueue(sender: AnyObject) {
        trackQueueViewController!.toggleHidden(queueButton.state)
        switch queueButton.state {
        case NSOnState:
            trackQueueTargetView.hidden = false
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "queueHidden")
        default:
            trackQueueTargetView.hidden = true
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "queueHidden")
        }
    }
    
    func launchGetInfo(tracks: [Track]) {
        self.tagWindowController = TagEditorWindow(windowNibName: "TagEditorWindow")
        self.tagWindowController?.mainWindowController = self
        self.tagWindowController?.selectedTracks = tracks
        tagWindowController?.showWindow(self)
    }
    
    func createPlayOrderForTrackID(id: Int, row: Int?) -> Int {
        return currentTableViewController!.getUpcomingIDsForPlayEvent(self.shuffleButton.state, id: id, row: row)
    }
    
    func getNextTrack() -> Track? {
        let track: Track?
        if repeatButton.state == NSOnState {
            return currentTrack
        } else {
            track = trackQueueViewController?.getNextTrack()
            if trackQueueViewController?.currentAudioSource?.is_network == true {
                delegate?.serviceBrowser?.askPeerForSong(trackQueueViewController!.currentAudioSource!.library!.peer as! MCPeerID, id: Int(track!.id!))
                dispatch_async(dispatch_get_main_queue()) {
                    self.initializeInterfaceForNetworkTrack()
                    self.timer?.invalidate()
                }
                delegate?.audioModule.networkFlag = true
            }
            return track
        }
    }
    
    @IBAction func repeatButtonPressed(sender: AnyObject) {
        if repeatButton.state == NSOnState {
            self.will_repeat = true
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: DEFAULTS_REPEAT_STRING)
        } else {
            self.will_repeat = true
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: DEFAULTS_REPEAT_STRING)
        }
        delegate?.repeatMenuItem.state = repeatButton.state
    }
    
    @IBAction func shuffleButtonPressed(sender: AnyObject) {
        trackQueueViewController?.shufflePressed(shuffleButton.state)
        delegate?.shuffleMenuItem.state = shuffleButton.state
    }
    
    @IBAction func tempBreak(sender: AnyObject) {
        print("dongels")
    }
    @IBAction func addPlaylistButton(sender: AnyObject) {
        sourceListViewController!.createPlaylist(nil, smart_criteria: nil)
    }
    @IBAction func addPlaylistFolderButton(sender: AnyObject) {
        sourceListViewController!.createPlaylistFolder(nil)
    }
    @IBAction func addSmartPlaylistButton(sender: AnyObject) {
        sourceListViewController!.selectLibrary()
        showAdvancedFilter()
    }
    
    func createPlaylistFromTracks(idList: [Int]) {
        sourceListViewController?.createPlaylist(idList, smart_criteria: nil)
    }
    func createPlaylistFromSmartCriteria(c: SmartCriteria) {
        sourceListViewController?.createPlaylist(nil, smart_criteria: c)
    }
    
    //player stuff
    
    var artworkToggle: NSButton?
    @IBAction func toggleArtwork(sender: AnyObject) {
        albumArtViewController!.toggleHidden(artworkToggle!.state)
    }

    func playNetworkSongCallback() {
        guard self.is_streaming == true else {return}
        if trackQueueViewController?.trackQueue.count < 1 || networkSongWasPlayed == true {
            //trackQueueViewController?.changeCurrentTrack(self.currentTrack!)
            if networkSongWasPlayed == true {
                networkSongWasPlayed = false
            }
        }
        delegate?.audioModule.playNetworkImmediately(self.currentTrack!)
        //initializeInterfaceForNewTrack()
        paused = false
    }
    
    func playSong(track: Track, row: Int?) {
        if track.is_network == true {
            self.is_streaming = true
            initializeInterfaceForNetworkTrack()
            let peer = sourceListViewController!.getCurrentSelectionSharedLibraryPeer()
            delegate?.audioModule.stopForNetworkTrack()
            delegate?.serviceBrowser?.getTrack(Int(track.id!), peer: peer)
            if self.currentTrack != nil {
                currentTrack?.is_playing = false
                currentTableViewController?.reloadNowPlayingForTrack(self.currentTrack!)
            }
            currentTrack = track
            networkSongWasPlayed = true
            trackQueueViewController?.createPlayOrderArray(track, row: row)
            trackQueueViewController?.changeCurrentTrack(self.currentTrack!)
            return
        } else {
            self.is_streaming = false
        }
        if (paused == true && delegate?.audioModule.is_initialized == true) {
            unpause()
        }
        trackQueueViewController?.createPlayOrderArray(track, row: row)
        //trackQueueViewController?.addTrackToQueue(track, context: currentSourceListItem!.name!, tense: 2)
        delegate?.audioModule.playImmediately(track.location!)
        trackQueueViewController?.changeCurrentTrack(track)
        paused = false
        //currentTrack = track
    }
    
    func shuffle_array(inout array: [Int]) {
        guard array.count > 0 else {return}
        for i in 0..<array.count - 1 {
            let j = Int(arc4random_uniform(UInt32(array.count - i))) + i
            guard i != j else {continue}
            swap(&array[i], &array[j])
        }
    }
    
    func playAnything() {
        if trackQueueViewController?.trackQueue.count == 0 {
            let trackToPlay = currentTableViewController!.getTrackWithNoContext(shuffleButton.state)
            if trackToPlay != nil {
                playSong(trackToPlay!, row: nil)
            }
        } else {
            delegate?.audioModule.skip()
        }
    }
    
    func interpretSpacebarEvent() {
        if currentTrack != nil {
            if paused == true {
                unpause()
            } else if paused == false {
                pause()
            }
        } else {
            playAnything()
        }
    }
    
    func pause() {
        paused = true
        print("pause called")
        updateValuesUnsafe()
        delegate?.audioModule.pause()
        timer!.invalidate()
        playButton.image = NSImage(named: "NSPlayTemplate")
    }
    
    func unpause() {
        print("unpause called")
        paused = false
        lastTimerDate = NSDate()
        delegate?.audioModule.play()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(updateValuesSafe), userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
        playButton.image = NSImage(named: "NSPauseTemplate")
    }
    
    func seek(frac: Double) {
        delegate?.audioModule.seek(frac)
    }
    
    func skip() {
        guard trackQueueViewController!.currentTrack != nil else {return}
        guard self.isDoneWithSkipOperation else {return}
        self.isDoneWithSkipOperation = false
        self.currentTrack?.is_playing = false
        timer?.invalidate()
        delegate?.audioModule.skip()
    }
    
    func skipBackward() {
        guard trackQueueViewController!.currentTrack != nil else {return}
        guard self.isDoneWithSkipBackOperation else {return}
        self.isDoneWithSkipBackOperation = false
        self.currentTrack?.is_playing = false
        timer?.invalidate()
        let nodeTime = delegate?.audioModule.curNode.lastRenderTime
        let playerTime = delegate?.audioModule.curNode.playerTimeForNodeTime(nodeTime!)
        var offset_thing: Double?
        if delegate?.audioModule.track_frame_offset == nil {
            offset_thing = 0
        }
        else {
            offset_thing  = delegate?.audioModule.track_frame_offset!
            print(offset_thing)
        }
        let seconds = ((Double((playerTime?.sampleTime)!) + offset_thing!) / (playerTime?.sampleRate)!) - Double(delegate!.audioModule.total_offset_seconds)
        if seconds > 3 {
            delegate?.audioModule.skip_backward()
        } else {
            trackQueueViewController?.skipToPreviousTrack()
        }
    }
    
    
    @IBAction func playPressed(sender: AnyObject) {
        print("called")
        if (paused == true) {
            //if not initialized, play selected track/shuffle
            if is_initialized == false {
                playAnything()
            }
            unpause()
            paused = false
        }
        else {
            pause()
            paused = true
        }
    }
    @IBAction func advancedFilterButtonPressed(sender: AnyObject) {
        if advancedSearchToggle.state == NSOnState {
            showAdvancedFilter()
        } else {
            hideAdvancedFilter()
        }
    }
    
    @IBAction func toggleFilterVisibility(sender: AnyObject) {
        if advancedFilterViewController?.view != nil {
            advancedSearchToggle.state = NSOffState
            advancedFilterViewController!.view.removeFromSuperview()
            currentTableViewController?.trackViewArrayController.filterPredicate = nil
            //librarySplitView.removeArrangedSubview(advancedFilterViewController!.view)
            advancedFilterViewController = nil
            currentTableViewController?.advancedFilterVisible = false
        } else {
            advancedSearchToggle.state = NSOnState
            self.advancedFilterViewController = AdvancedFilterViewController(nibName: "AdvancedFilterViewController", bundle: nil)
            advancedFilterViewController!.mainWindowController = self
            librarySplitView.insertArrangedSubview(advancedFilterViewController!.view, atIndex: 0)
            advancedFilterViewController?.predicateEditor!.bind("value", toObject: currentTableViewController!.trackViewArrayController, withKeyPath: "filterPredicate", options: nil)
            currentTableViewController?.advancedFilterVisible = true
            advancedFilterViewController?.initializePredicateEditor()
        }
    }
    
    func showAdvancedFilter() {
        if advancedFilterViewController?.view == nil {
            self.advancedFilterViewController = AdvancedFilterViewController(nibName: "AdvancedFilterViewController", bundle: nil)
            advancedFilterViewController!.mainWindowController = self
            librarySplitView.insertArrangedSubview(advancedFilterViewController!.view, atIndex: 0)
            advancedFilterViewController?.predicateEditor!.bind("value", toObject: currentTableViewController!.trackViewArrayController, withKeyPath: "filterPredicate", options: nil)
            currentTableViewController?.advancedFilterVisible = true
            advancedFilterViewController?.initializePredicateEditor()
            advancedSearchToggle.state = NSOnState
        }
    }
    
    func hideAdvancedFilter() {
        if advancedFilterViewController != nil {
            advancedFilterViewController!.view.removeFromSuperview()
            currentTableViewController?.trackViewArrayController.filterPredicate = nil
            //librarySplitView.removeArrangedSubview(advancedFilterViewController!.view)
            advancedFilterViewController = nil
            currentTableViewController?.advancedFilterVisible = false
            advancedSearchToggle.state = NSOffState
        }
    }
    
    func initializeInterfaceForNetworkTrack() {
        theBox.contentView?.hidden = false
        print("initializing interface for network track")
        self.timer?.invalidate()
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
        let the_track = self.currentTrack!
        albumArtViewController?.initAlbumArt(the_track)
        name_string = the_track.name!
        if the_track.artist != nil {
            aa_string += (the_track.artist! as Artist).name!
            if the_track.album != nil {
                aa_string += (" - " + (the_track.album! as Album).name!)
            }
        }
        timer?.invalidate()
        theBox.contentView!.hidden = false
        songNameLabel.stringValue = name_string
        artistAlbumLabel.stringValue = aa_string
        duration = delegate?.audioModule.duration_seconds
        if self.durationShowsTimeRemaining {
            durationLabel.stringValue = "-\(getTimeAsString(duration!)!)"
        } else {
            durationLabel.stringValue = getTimeAsString(duration!)!
        }
        currentTimeLabel.stringValue = getTimeAsString(0)!
        lastTimerDate = NSDate()
        secsPlayed = 0
        progressBar.hidden = false
        progressBar.doubleValue = 0
        if paused != true {
            startTimer()
        }
    }

    func startTimer() {
        //timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(updateValuesUnsafe), userInfo: nil, repeats: true)
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(updateValuesSafe), userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
        playButton.image = NSImage(named: "NSPauseTemplate")
    }
    
    func updateValuesUnsafe() {
        print("unsafe called")
        let nodeTime = delegate?.audioModule.curNode.lastRenderTime
        let playerTime = delegate?.audioModule.curNode.playerTimeForNodeTime(nodeTime!)
        print("unsafe update times")
        print(nodeTime)
        print(playerTime)
        var offset_thing: Double?
        if delegate?.audioModule.track_frame_offset == nil {
            offset_thing = 0
        }
        else {
            offset_thing  = delegate?.audioModule.track_frame_offset!
            print(offset_thing)
        }
        print(delegate?.audioModule.total_offset_seconds)
        print(delegate?.audioModule.total_offset_frames)
        let seconds = ((Double((playerTime?.sampleTime)!) + offset_thing!) / (playerTime?.sampleRate)!) - Double(delegate!.audioModule.total_offset_seconds)
        let seconds_string = getTimeAsString(seconds)
        if (timer?.valid == true) {
            print("within valid clause")
            currentTimeLabel.stringValue = seconds_string!
            print(seconds_string)
            progressBar.doubleValue = (seconds * 100) / duration!
            if self.durationShowsTimeRemaining {
                durationLabel.stringValue = "-\(getTimeAsString(duration! - secsPlayed)!)"
            }
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
            if self.durationShowsTimeRemaining {
                durationLabel.stringValue = "-\(getTimeAsString(duration! - secsPlayed)!)"
            }
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
    
    
    @IBAction func durationLabelOnClick(sender: AnyObject) {
        durationShowsTimeRemaining = !durationShowsTimeRemaining
        if durationShowsTimeRemaining == false {
            durationLabel.stringValue = getTimeAsString(self.duration!)!
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
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &my_context {
            if keyPath! == "track_changed" {
                let before = NSDate()
                print("controller detects track change")
                currentTrack?.is_playing = false
                if currentTrack != nil {
                    currentTableViewController?.reloadNowPlayingForTrack(currentTrack!)
                }
                trackQueueViewController!.nextTrack()
                currentTrack = trackQueueViewController?.trackQueue[trackQueueViewController!.currentTrackIndex!].track
                if is_initialized == false {
                    //trackQueueViewController!.createPlayOrderArray(self.currentTrack!, row: nil)
                    paused = false
                    is_initialized = true
                }
                timer?.invalidate()
                initializeInterfaceForNewTrack()
                currentTrack?.is_playing = true
                currentTableViewController?.reloadNowPlayingForTrack(currentTrack!)
                let after = NSDate()
                let since = after.timeIntervalSinceDate(before)
                print(since)
                self.isDoneWithSkipOperation = true
                self.isDoneWithSkipBackOperation = true
            }
            else if keyPath! == "done_playing" {
                print("controller detects finished playing")
                cleanUpBar()
            }
            else if keyPath! == "sortDescriptors" {
                self.trackQueueViewController!.modifyPlayOrderForSortDescriptorChange()
            }
            else if keyPath! == "filterPredicate" {
                print("filter predicate changed")
                if (trackQueueViewController!.currentSourceListItem == trackQueueViewController!.currentAudioSource) && trackQueueViewController?.currentAudioSource!.playOrderObject != nil {
                    currentTableViewController!.fixPlayOrderForChangedFilterPredicate(trackQueueViewController!.currentAudioSource!.playOrderObject!, shuffleState: shuffleButton.state)
                }
            } else if keyPath! == "arrangedObjects" {
                updateInfo()
            } else if keyPath! == "albumArtworkAdded" {
                self.trackQueueViewController?.reloadData()
                print("reloaded data")
            }
        }
    }
    
    func updateInfo() {
        print("updateinfo called")
        if self.currentTableViewController == nil {
            return
        }
        dispatch_async(dispatch_get_main_queue()) {
            let trackArray = (self.currentTableViewController?.trackViewArrayController?.arrangedObjects as! [TrackView])
            let numItems = trackArray.count
            let totalSize = trackArray.map({return (($0.track)!.size?.longLongValue)}).reduce(0, combine: {$0 + ($1 != nil ? $1! : 0)})
            let totalTime = trackArray.map({return (($0.track)!.time?.doubleValue)}).reduce(0, combine: {$0 + ($1 != nil ? $1! : 0)})
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
        print("break")
    }
    
    //mark album art
    
    override func windowDidLoad() {
        self.sourceListViewController = SourceListViewController(nibName: "SourceListViewController", bundle: nil)
        sourceListTargetView.addSubview(sourceListViewController!.view)
        self.sourceListViewController!.view.frame = sourceListTargetView.bounds
        let sourceListLayoutConstraints = [NSLayoutConstraint(item: sourceListViewController!.view, attribute: .Left, relatedBy: .Equal, toItem: sourceListTargetView, attribute: .Left, multiplier: 1, constant: 0), NSLayoutConstraint(item: sourceListViewController!.view, attribute: .Right, relatedBy: .Equal, toItem: sourceListTargetView, attribute: .Right, multiplier: 1, constant: 0), NSLayoutConstraint(item: sourceListViewController!.view, attribute: .Top, relatedBy: .Equal, toItem: sourceListTargetView, attribute: .Top, multiplier: 1, constant: 0), NSLayoutConstraint(item: sourceListViewController!.view, attribute: .Bottom, relatedBy: .Equal, toItem: sourceListTargetView, attribute: .Bottom, multiplier: 1, constant: 0)]
        NSLayoutConstraint.activateConstraints(sourceListLayoutConstraints)
        self.sourceListViewController?.mainWindowController = self
        self.albumArtViewController = AlbumArtViewController(nibName: "AlbumArtViewController", bundle: nil)
        artworkTargetView.addSubview(albumArtViewController!.view)
        let artworkLayoutConstraints = [NSLayoutConstraint(item: albumArtViewController!.view, attribute: .Left, relatedBy: .Equal, toItem: artworkTargetView, attribute: .Left, multiplier: 1, constant: 0), NSLayoutConstraint(item: albumArtViewController!.view, attribute: .Right, relatedBy: .Equal, toItem: artworkTargetView, attribute: .Right, multiplier: 1, constant: 0), NSLayoutConstraint(item: albumArtViewController!.view, attribute: .Top, relatedBy: .Equal, toItem: artworkTargetView, attribute: .Top, multiplier: 1, constant: 0), NSLayoutConstraint(item: albumArtViewController!.view, attribute: .Bottom, relatedBy: .Equal, toItem: artworkTargetView, attribute: .Bottom, multiplier: 1, constant: 0)]
        NSLayoutConstraint.activateConstraints(artworkLayoutConstraints)
        self.albumArtViewController!.view.frame = artworkTargetView.bounds
        self.trackQueueViewController = TrackQueueViewController(nibName: "TrackQueueViewController", bundle: nil)
        trackQueueTargetView.addSubview(trackQueueViewController!.view)
        self.trackQueueViewController!.view.frame = trackQueueTargetView.bounds
        let trackQueueLayoutConstraints = [NSLayoutConstraint(item: trackQueueViewController!.view, attribute: .Left, relatedBy: .Equal, toItem: trackQueueTargetView, attribute: .Left, multiplier: 1, constant: 0), NSLayoutConstraint(item: trackQueueViewController!.view, attribute: .Right, relatedBy: .Equal, toItem: trackQueueTargetView, attribute: .Right, multiplier: 1, constant: 0), NSLayoutConstraint(item: trackQueueViewController!.view, attribute: .Top, relatedBy: .Equal, toItem: trackQueueTargetView, attribute: .Top, multiplier: 1, constant: 0), NSLayoutConstraint(item: trackQueueViewController!.view, attribute: .Bottom, relatedBy: .Equal, toItem: trackQueueTargetView, attribute: .Bottom, multiplier: 1, constant: 0)]
        NSLayoutConstraint.activateConstraints(trackQueueLayoutConstraints)
        self.trackQueueViewController?.mainWindowController = self
        //self.libraryTableViewController = LibraryTableViewController(nibName: "LibraryTableViewController", bundle: nil)
        self.libraryTableViewController = LibraryTableViewControllerCellBased(nibName: "LibraryTableViewControllerCellBased", bundle: nil)
        self.libraryTableViewController?.mainWindowController = self
        self.librarySplitView.addArrangedSubview(libraryTableViewController!.view)
        //self.libraryTableTargetView.addSubview(self.libraryTableViewController!.view)
        //self.libraryTableViewController!.view.frame = self.libraryTableTargetView.bounds
        //let libraryTableLayoutConstraints = [NSLayoutConstraint(item: libraryTableViewController!.view, attribute: .Left, relatedBy: .Equal, toItem: libraryTableTargetView, attribute: .Left, multiplier: 1, constant: 0), NSLayoutConstraint(item: libraryTableViewController!.view, attribute: .Right, relatedBy: .Equal, toItem: libraryTableTargetView, attribute: .Right, multiplier: 1, constant: 0), NSLayoutConstraint(item: libraryTableViewController!.view, attribute: .Top, relatedBy: .Equal, toItem: libraryTableTargetView, attribute: .Top, multiplier: 1, constant: 0), NSLayoutConstraint(item: libraryTableViewController!.view, attribute: .Bottom, relatedBy: .Equal, toItem: libraryTableTargetView, attribute: .Bottom, multiplier: 1, constant: 0)]
        //NSLayoutConstraint.activateConstraints(libraryTableLayoutConstraints)
        numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        dateFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Full
        print(hasMusic)
        self.delegate!.audioModule.mainWindowController = self
        progressBar.displayedWhenStopped = true
        progressBarView.progressBar = progressBar
        progressBarView.mainWindowController = self
        theBox.contentView?.hidden = true
        searchField.delegate = self
        self.currentTableViewController = libraryTableViewController
        self.delegate?.audioModule.addObserver(self, forKeyPath: "track_changed", options: .New, context: &my_context)
        self.delegate?.audioModule.addObserver(self, forKeyPath: "done_playing", options: .New, context: &my_context)
        self.libraryTableViewController?.trackViewArrayController.addObserver(self, forKeyPath: "arrangedObjects", options: .New, context: &my_context)
        self.libraryTableViewController?.trackViewArrayController.addObserver(self, forKeyPath: "filterPredicate", options: .New, context: &my_context)
        self.libraryTableViewController?.trackViewArrayController.addObserver(self, forKeyPath: "sortDescriptors", options: .New, context: &my_context)
        self.libraryTableViewController?.trackViewArrayController.fetchPredicate = NSPredicate(format: "is_network == nil or is_network == false")
        self.albumArtViewController?.addObserver(self, forKeyPath: "albumArtworkAdded", options: .New, context: &my_context)
        trackQueueViewController?.mainWindowController = self
        volumeSlider.continuous = true
        self.window!.titleVisibility = NSWindowTitleVisibility.Hidden
        self.window!.titlebarAppearsTransparent = true
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "checkEmbeddedArtwork")
        //current_source_play_order = (libraryTableViewController!.trackViewArrayController.arrangedObjects as! [TrackView]).map( {return $0.track!.id as! Int})
        let userScreenSize = NSScreen.mainScreen()?.frame.width
        let songBarMinimumWidthConstraint = NSLayoutConstraint(item: theBox, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: MIN_SONG_BAR_WIDTH_FRACTION, constant: userScreenSize! * MIN_SONG_BAR_WIDTH_FRACTION)
        let volumeBarMinimumWidthConstraint = NSLayoutConstraint(item: volumeSlider, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: userScreenSize! * MIN_VOLUME_BAR_WIDTH_FRACTION)
        let searchBarMinimumWidthConstraint = NSLayoutConstraint(item: searchField, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: userScreenSize! * MIN_SEARCH_BAR_WIDTH_FRACTION)
        let volumeSliderMaxWidthConstraint = NSLayoutConstraint(item: volumeSlider, attribute: .Width, relatedBy: .LessThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: userScreenSize! * MAX_VOLUME_BAR_WIDTH_FRACTION)
        //let volumeSongBarDistanceConstraint = NSLayoutConstraint(item: volumeSlider, attribute: .Trailing, relatedBy: .GreaterThanOrEqual, toItem: theBox, attribute: .Leading, multiplier: 1.0, constant: userScreenSize! * MIN_DISTANCE_BETWEEN_VOLUME_AND_SONG_BAR_FRACTION)
        NSLayoutConstraint.activateConstraints([songBarMinimumWidthConstraint, volumeBarMinimumWidthConstraint, searchBarMinimumWidthConstraint, volumeSliderMaxWidthConstraint])
        let volume = NSUserDefaults.standardUserDefaults().floatForKey(DEFAULTS_VOLUME_STRING)
        volumeSlider.floatValue = volume
        volumeDidChange(volumeSlider)
        super.windowDidLoad()
        sourceListViewController?.selectStuff()
        let clickRecognizer = NSClickGestureRecognizer()
        clickRecognizer.buttonMask = 0x1
        clickRecognizer.numberOfClicksRequired = 1
        clickRecognizer.action = #selector(durationLabelOnClick)
        durationLabel.addGestureRecognizer(clickRecognizer)
        delegate?.shuffleMenuItem.state = shuffleButton.state
        delegate?.repeatMenuItem.state = repeatButton.state
    }
}
