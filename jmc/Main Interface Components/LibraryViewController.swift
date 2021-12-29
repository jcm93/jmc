//
//  LibraryViewController.swift
//  jmc
//
//  Created by John Moody on 12/26/21.
//  Copyright © 2021 John Moody. All rights reserved.
//

import Cocoa

protocol LibraryViewController: NSMenuDelegate {
    /*this protocol will abstract the backend-specific functions of LibraryTableViewController
     away from LibraryTableViewController, and serve as a view-agnostic middleman between the
     current library view and the main window controller. This will allow for easier development
     of different library views (artist, album, something else, etc.)*/
    var rightMouseDownTarget: [TrackView]? { get set }
    var rightMouseDownRow: Int { get set }
    var item: SourceListItem? { get set }
    var searchString: String? { get set }
    var playlist: SongCollection? { get set }
    var advancedFilterVisible: Bool { get set }
    var hasInitialized: Bool { get set }
    var hasCreatedPlayOrder: Bool { get set }
    var currentTrackRow: Int { get set }
    var statusStringNeedsUpdate: Bool { get set }
    
    var normalMenuItemsArray: [NSMenuItem]! { get set }
    var view: NSView { get set }
    var mainWindowController: MainWindowController? { get set }
    
    func initializeForPlaylist()
    func jumpToCurrentSong(_ track: Track?)
    func jumpToSelection()
    func reloadData()
    func initializeForLibrary()
    func getUpcomingIDsForPlayEvent(_ state: Int, id: Int, row: Int) -> Int
    func reloadNowPlayingForTrack(_ track: Track)
    func reloadDataForTrack(_ track: Track, orRow: Int)
    func getTrackWithNoContext(_ shuffleState: Int) -> Track?
    func initializeSmartPlaylist()
    func scrollToNewTrack()
    func fixPlayOrderForChangedFilterPredicate(_ shuffleState: Int)
    func setFilterPredicate(_ searchFieldContent: String)
    func getArrangedObjects() -> [TrackView]
    func rearrangeObjects()
    func setFetchPredicate(_ predicate: NSPredicate?)
    func getFilterPredicate() -> NSPredicate?
    func setArrayControllerContent(_ content: Any?)
    func getSelectedObjects() -> [TrackView]
}
