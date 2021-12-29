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
    
    @IBOutlet weak var splitView: NSSplitView!
    
    var artistListView: ArtistListViewController!
    var albumsView: ArtistViewAlbumViewController!
    var hasInitialized: Bool = false
    var advancedFilterVisible: Bool = false
    var databaseManager = DatabaseManager()
    
    var cachedViewControllers = [[Artist] : ArtistViewAlbumViewController]()
    
    func newArtistsSelected(artists: [Artist]) {
        albumsView?.view.removeFromSuperview()
        let newAlbumsView = ArtistViewAlbumViewController(nibName: "ArtistViewAlbumViewController", bundle: nil, artists: artists, artistViewController: self)
        newAlbumsView?.artistViewController = self
        splitView.addArrangedSubview(newAlbumsView!.view)
        self.albumsView = newAlbumsView
        self.cachedViewControllers[artists] = newAlbumsView
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
    
    func getUpcomingIDsForPlayEvent(_ state: Int, id: Int, row: Int) -> Int {
        return -1
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
        return [TrackView]()
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
        self.splitView.addArrangedSubview(artistListView!.view)
        
    }
}
