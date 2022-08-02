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
        self.arrangedObjectsChanged()
    }
    
    func initializeForPlaylist() {
        print("initializing for playlist")
        self.trackViewArrayController.content = self.item!.playlist!.tracks!.array as! [TrackView]
        for (index, trackView) in self.item!.playlist!.tracks!.array.enumerated() {
            (trackView as! TrackView).playlist_order = index + 1 as NSNumber
        }
        self.trackViewArrayController.rearrangeObjects()
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
        self.trackViewArrayController.content = self.item!.library!.tracks!.map({return ($0 as! Track).view}) as! [TrackView]
        self.trackViewArrayController.rearrangeObjects()
        //sets predicates to nil
        //self.artistListView.initializeForLibrary()
        //self.albumsView.initializeForLibrary()
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
        let currentIDArray = self.albumsView.tracks.map({return Int($0.track!.id!)})
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
        /*let volumes = Set(self.albumsView.tracks.compactMap({return $0.track?.volume}))
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
        let aggregatedTracks = self.albumsView.views.values.map({return $0.album?.tracks})
        let idArray = (self.trackViewArrayController.arrangedObjects as! [TrackView]).map({return Int($0.track!.id!)})
        //let idArray = self.albumsView.tracks.map({return Int($0.track!.id!)})
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
        }*/
        return self.albumsView.getUpcomingIDsForPlayEvent(shuffleState, id: id, row: row)
    }
    
    func reloadNowPlayingForTrack(_ track: Track) {
        self.albumsView.reloadNowPlayingForTrack(track)
    }
    
    func reloadDataForTrack(_ track: Track, orRow: Int) {
        self.albumsView.reloadNowPlayingForTrack(track)
    }
    
    func getTrackWithNoContext(_ shuffleState: Int) -> Track? {
        self.albumsView.getTrackWithNoContext(shuffleState)
    }
    
    func initializeSmartPlaylist() {
        if playlist != nil {
            globalInitializeSmartPlaylist(playlist: self.playlist!)
        }
    }
    
    func interpretSpacebarEvent() {
        self.mainWindowController?.interpretSpacebarEvent()
    }
    
    func interpretEnterEvent() {
        //should be in artistviewalbumviewcontroller
        self.item!.currentPlayOrderObject = self.item!.artistPlayOrderObject!
        var items = self.albumsView.tracks.map({return $0.track!})
        if self.mainWindowController!.playSong(items.removeFirst(), row: -1) {
            self.mainWindowController!.trackQueueViewController?.addTracksToQueue(nil, tracks: items)
        }
    }
    
    func playSong(_ track: Track, row: Int) -> Bool {
        return self.mainWindowController!.playSong(track, row: row)
    }
    
    func scrollToNewTrack() {
        self.albumsView.scrollToNewTrack()
    }
    
    func fixPlayOrderForChangedFilterPredicate(_ shuffleState: Int) {
        
    }
    
    /*func setFilterPredicate(_ predicate: NSPredicate?) {
        self.artistListView.setFilterPredicate(predicate)
        self.albumsView.setFilterPredicate(predicate)
    }*/
    
    func getArrangedObjects() -> [TrackView] {
        let trackArray = self.albumsView.tracks
        return trackArray
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
        self.arrangedObjectsChanged()
    }
    
    func getFilterPredicate() -> NSPredicate? {
        return nil
    }
    
    func setArrayControllerContent(_ content: Any?) {
        
    }
    
    func getSelectedObjects() -> [TrackView] {
        let selection = self.albumsView?.getSelectedTrackViews() ?? [TrackView]()
        return selection
    }
    
    func selectItems(_ selection: [TrackView]) {
        self.itemsToSelect = selection
    }
    
    func arrangedObjectsChanged() {
        //for some reason direct KVO on the NSArrayController in the album track list view delegates is not working, so call it manually
        self.initializePlayOrderObject()
        mainWindowController!.trackQueueViewController!.activePlayOrders.append(self.item!.artistPlayOrderObject!)
        self.item!.artistViewController = self
        print("initialized poo for new view")
        self.hasCreatedPlayOrder = true
        //self.trackViewArrayController.hasInitialized = true
        //(self.trackViewArrayController.arrangedObjects as! NSArray).map({return ($0 as! TrackView).track?.id}) //fire faults
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for view in self.splitView.subviews {
            self.splitView.removeArrangedSubview(view)
        }
        // Do view setup here.
        self.trackViewArrayController = NSArrayController()
        if playlist != nil {
            print("initializing for playlist")
            if playlist?.smart_criteria != nil {
                initializeSmartPlaylist()
            }
            initializeForPlaylist()
        } else if item?.library != nil {
            print("initializing for library")
            initializeForLibrary()
        }
        /*self.trackViewArrayController.managedObjectContext = managedContext
        self.trackViewArrayController.entityName = "TrackView"
        self.trackViewArrayController.automaticallyPreparesContent = true*/
        //self.trackViewArrayController.fetchPredicate = NSPredicate(format: "track.playlist.id == %@", arguments: self.playlist?.id)
        /*do {
           try self.trackViewArrayController.fetch(with: nil, merge: false)
        } catch {
            print (error)
        }*/
        self.artistListView = ArtistListViewController(nibName: "ArtistListViewController", bundle: nil, artistViewController: self)
        let artists = Array(Set(self.itemsToSelect.compactMap({return $0.track?.artist})))
        //self.artistListView.selectArtists(artists: artists)
        self.splitView.addArrangedSubview(self.artistListView!.view)
        self.artistListView.refreshArtistArrayContent()
    }
}
