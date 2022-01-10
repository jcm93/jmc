//
//  ArtistViewController.swift
//  jmc
//
//  Created by John Moody on 5/21/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class ArtistViewController: NSViewController, LibraryViewController {
    
    
    var rightMouseDownTarget: [TrackView]?
    var rightMouseDownRow: Int = 0
    var item: SourceListItem?
    var searchString: String?
    var playlist: SongCollection?
    var hasCreatedPlayOrder: Bool = false
    var currentTrackRow: Int = -1
    var statusStringNeedsUpdate: Bool = false
    var normalMenuItemsArray: [NSMenuItem]!
    var mainWindowController: MainWindowController?
    var trackViewArrayController: NSArrayController!
    var itemsToSelect: [TrackView]! = [TrackView]()
    var avc_context = 0
    
    @IBOutlet weak var splitView: NSSplitView!
    
    var artistListView: ArtistListViewController!
    var albumsView: ArtistViewAlbumViewController!
    var hasInitialized: Bool = false
    var advancedFilterVisible: Bool = false
    var databaseManager = DatabaseManager()
    
    func newArtistsSelected(artists: [Artist]) {
        albumsView?.view.removeFromSuperview()
        let newAlbumsView = ArtistViewAlbumViewController(nibName: "ArtistViewAlbumViewController", bundle: nil, artists: artists, artistViewController: self)
        newAlbumsView?.artistViewController = self
        self.albumsView = newAlbumsView
        self.albumsView.selectTrackViews(self.itemsToSelect)
        DispatchQueue.main.async {
            self.splitView.addArrangedSubview(newAlbumsView!.view)
        }
    }
    
    func initializeForPlaylist() {
        print("initializing for playlist")
        
    }
    
    func jumpToCurrentSong(_ track: Track?) {
        guard let track = track else { return }
        let artist = track.artist!
        self.artistListView.jumpToArtist(artist)
    }
    
    func jumpToSelection() {
        self.artistListView.jumpToSelection()
        self.albumsView.jumpToSelection()
    }
    
    func reloadData() {
        self.artistListView.reloadData()
        self.albumsView.reloadData()
    }
    
    func initializeForLibrary() {
        //sets predicates to nil
        self.artistListView.initializeForLibrary()
        self.albumsView.initializeForLibrary()
    }
    
    func initializePlayOrderObject() {
        print("creating play order object")
        guard let item = self.item else { return }
        if item.artistPlayOrderObject == nil {
            let newObject = NSEntityDescription.insertNewObject(forEntityName: "PlayOrderObject", into: managedContext) as! PlayOrderObject
            item.artistPlayOrderObject = newObject
        }
        let playOrderObject = item.artistPlayOrderObject!
        print((self.trackViewArrayController.arrangedObjects as! NSArray).count)
        let currentIDArray = self.albumsView.getCurrentShownTrackViews().map({return Int($0.track!.id!)})
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
    
    func getUpcomingIDsForPlayEvent(_ shuffleState: Int, id: Int, row: Int) -> Int {
        let volumes = Set(self.albumsView.getCurrentShownTrackViews().compactMap({return $0.track?.volume}))
        var count = 0
        for volume in volumes {
            if !volumeIsAvailable(volume: volume) {
                count += 1
            }
        }
        if count > 0 {
            print("library status has changed, reloading data")
            self.mainWindowController?.sourceListViewController?.reloadData()
        }
        let idArray = self.albumsView.getCurrentShownTrackViews().map({return Int($0.track!.id!)})
        if shuffleState == NSControl.StateValue.on.rawValue {
            //secretly adjust the shuffled array such that it behaves mysteriously like a ring buffer. ssshhhh
            let currentShuffleArray = self.item!.artistPlayOrderObject!.shuffledPlayOrder!
            let indexToSwap = currentShuffleArray.firstIndex(of: id)!
            let beginningOfArray = currentShuffleArray[0..<indexToSwap]
            let endOfArray = currentShuffleArray[indexToSwap..<currentShuffleArray.count]
            let newArraySliceConcatenation = endOfArray + beginningOfArray
            self.item?.artistPlayOrderObject?.shuffledPlayOrder = Array(newArraySliceConcatenation)
            if self.item!.artistPlayOrderObject!.currentPlayOrder! != self.item!.artistPlayOrderObject!.shuffledPlayOrder! {
                let idSet = Set(idArray)
                self.item?.artistPlayOrderObject?.currentPlayOrder = self.item!.artistPlayOrderObject!.shuffledPlayOrder!.filter({idSet.contains($0)})
            } else {
                self.item?.artistPlayOrderObject?.currentPlayOrder = self.item!.artistPlayOrderObject!.shuffledPlayOrder!
            }
            return 0
        } else {
            self.item?.artistPlayOrderObject?.currentPlayOrder = idArray
            if row > -1 {
                return row
            } else {
                return idArray.firstIndex(of: id)!
            }
        }
    }
    
    func reloadNowPlayingForTrack(_ track: Track) {
        
    }
    
    func reloadDataForTrack(_ track: Track, orRow: Int) {
        
    }
    
    func getTrackWithNoContext(_ shuffleState: Int) -> Track? {
        return nil
    }
    
    func initializeSmartPlaylist() {
        
    }
    
    func interpretSpacebarEvent() {
        self.mainWindowController?.interpretSpacebarEvent()
    }
    
    func interpretEnterEvent() {
        //should be in artistviewalbumviewcontroller
        var items = [Track]()
        for album in self.albumsView.views {
            let albumViewController = album.value
            if albumViewController.tracksTableView.selectedRowIndexes.count > 0 && albumViewController.trackListTableViewDelegate.tracksArrayController.selectedObjects.count > 0 {
                items.append(contentsOf: (albumViewController.trackListTableViewDelegate.tracksArrayController.selectedObjects as! [TrackView]).map({return $0.track!}))
            }
        }
        if self.mainWindowController!.playSong(items.removeFirst(), row: -1) {
            self.mainWindowController!.trackQueueViewController?.addTracksToQueue(nil, tracks: items)
        }
    }
    
    func playSong(_ track: Track, row: Int) -> Bool {
        return self.mainWindowController!.playSong(track, row: row)
    }
    
    func scrollToNewTrack() {
        
    }
    
    func fixPlayOrderForChangedFilterPredicate(_ shuffleState: Int) {
        
    }
    
    /*func setFilterPredicate(_ predicate: NSPredicate?) {
        self.artistListView.setFilterPredicate(predicate)
        self.albumsView.setFilterPredicate(predicate)
    }*/
    
    func getArrangedObjects() -> [TrackView] {
        return [TrackView]()
    }
    
    func rearrangeObjects() {
        
    }
    
    func setFetchPredicate(_ predicate: NSPredicate?) {
        
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
        self.artistListView.refreshArtistArrayContent()
    }
    
    func getFilterPredicate() -> NSPredicate? {
        return nil
    }
    
    func setArrayControllerContent(_ content: Any?) {
        
    }
    
    func getSelectedObjects() -> [TrackView] {
        let selection = self.albumsView.getSelectedTrackViews()
        return selection
    }
    
    func selectItems(_ selection: [TrackView]) {
        self.itemsToSelect = selection
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "arrangedObjects" {
            if self.hasCreatedPlayOrder == false && self.albumsView.getCurrentShownTrackViews().count > 0 {
                if self.item?.artistPlayOrderObject == nil {
                    self.initializePlayOrderObject()
                }
                mainWindowController!.trackQueueViewController!.activePlayOrders.append(self.item!.artistPlayOrderObject!)
                self.item!.artistViewController = self
                print("initialized poo for new view")
                self.hasCreatedPlayOrder = true
                //self.trackViewArrayController.hasInitialized = true
                //(self.trackViewArrayController.arrangedObjects as! NSArray).map({return ($0 as! TrackView).track?.id}) //fire faults
            } else {
                if self.albumsView.getCurrentShownTrackViews().count != self.item?.artistPlayOrderObject?.shuffledPlayOrder?.count ?? 0 {
                    self.initializePlayOrderObject()
                    print("reinitializing poo")
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for view in self.splitView.subviews {
            self.splitView.removeArrangedSubview(view)
        }
        // Do view setup here.
        self.trackViewArrayController = NSArrayController()
        self.trackViewArrayController.managedObjectContext = managedContext
        self.trackViewArrayController.entityName = "TrackView"
        self.trackViewArrayController.automaticallyPreparesContent = true
        do {
           try self.trackViewArrayController.fetch(with: nil, merge: false)
        } catch {
            print (error)
        }
        self.artistListView = ArtistListViewController(nibName: "ArtistListViewController", bundle: nil, artistViewController: self)
        let artists = Array(Set(self.itemsToSelect.compactMap({return $0.track?.artist})))
        self.artistListView.selectArtists(artists: artists)
        self.splitView.addArrangedSubview(self.artistListView!.view)
    }
}
