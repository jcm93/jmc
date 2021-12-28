//
//  LibraryViewer.swift
//  jmc
//
//  Created by John Moody on 12/26/21.
//  Copyright © 2021 John Moody. All rights reserved.
//

import Cocoa

class LibraryViewer: NSObject, NSMenuDelegate {
    /*this class will abstract the backend-specific functions of LibraryTableViewController
     away from LibraryTableViewController, and serve as a view-agnostic middleman between the
     current library view and the main window controller. This will allow for easier development
     of different library views (artist, album, something else, etc.)*/
    var rightMouseDownTarget: [TrackView]?
    var rightMouseDownRow: Int?
    var item: SourceListItem?
    var searchString: String?
    var playlist: SongCollection?
    var advancedFilterVisible: Bool = false
    var hasInitialized = false
    var hasCreatedPlayOrder = false
    var currentTrackRow = 0
    var statusStringNeedsUpdate = false
    
    let getInfoMenuItem = NSMenuItem(title: "Get Info", action: #selector(getInfoFromLibraryView), keyEquivalent: "")
    let addToQueueMenuItem = NSMenuItem(title: "Add to Queue", action: #selector(addToQueueFromLibraryView), keyEquivalent: "")
    let playMenuItem = NSMenuItem(title: "Play", action: #selector(playFromLibraryView), keyEquivalent: "")
    let separatorMenuItem = NSMenuItem.separator()
    let toggleEnabledMenuItem = NSMenuItem(title: "Toggle Enabled/Disabled", action: #selector(toggleEnabled), keyEquivalent: "")
    let showInFinderMenuItem = NSMenuItem(title: "Show in Finder", action: #selector(showInFinderAction), keyEquivalent: "")
    
    var normalMenuItemsArray: [NSMenuItem]!
    
    @objc func getInfoFromLibraryView() {
        
    }
    @objc func addToQueueFromLibraryView() {
        
    }
    @objc func playFromLibraryView() {
        
    }
    @objc func toggleEnabled() {
        
    }
    @objc func showInFinderAction() {
        
    }
    
}
