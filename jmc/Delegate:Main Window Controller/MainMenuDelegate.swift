//
//  MainMenuDelegate.swift
//  jmc
//
//  Created by John Moody on 11/26/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class MainMenuDelegate: NSObject, NSMenuDelegate {
    
    var mainWindowController: MainWindowController!
    var delegate: AppDelegate!
    @IBOutlet weak var shuffleMenuItem: NSMenuItem!
    @IBOutlet weak var repeatMenuItem: NSMenuItem!
    
    @IBAction func getInfoAction(_ sender: Any) {
        
    }
    
    @IBAction func deleteFromLibraryAction(_ sender: Any) {
        
    }
    
    @IBAction func openFiles(_ sender: Any) {
        self.delegate.openFiles()
    }
    
    @IBAction func jumpToCurrentSong(_ sender: AnyObject) {
        self.mainWindowController.jumpToCurrentSong()
    }
    
    @IBAction func jumpToSelection(_ sender: Any) {
        self.mainWindowController.jumpToSelection()
    }
    
    @IBAction func toggleAlbumArt(_ sender: Any) {
        self.mainWindowController.toggleArtwork(self)
    }
    
    @IBAction func newPlaylist(_ sender: AnyObject) {
        self.mainWindowController.createPlaylistFromTracks([Track]())
    }
    
    @IBAction func newPlaylistFromSelection(_ sender: AnyObject) {
        self.mainWindowController.createPlaylistFromTracks((self.mainWindowController.currentTableViewController?.trackViewArrayController.selectedObjects as! [TrackView]).map({return $0.track!}))
    }
    
    @IBAction func newSmartPlaylist(_ sender: Any) {
        self.mainWindowController.showAdvancedFilter()
    }
    
    @IBAction func previousMenuItemAction(_ sender: AnyObject) {
        self.mainWindowController.skipBackward()
    }
    
    @IBAction func nextMenuItemAction(_ sender: AnyObject) {
        self.mainWindowController.skip()
    }
    
    @IBAction func pauseMenuItemAction(_ sender: AnyObject) {
        if self.mainWindowController.paused != true {
            self.mainWindowController.pause()
        }
    }
    
    @IBAction func playMenuItemAction(_ sender: AnyObject) {
        if self.mainWindowController.paused != false {
            self.mainWindowController.playPressed(self)
        }
    }
    
    @IBAction func shuffleMenuItemAction(_ sender: AnyObject) {
        shuffleMenuItem.state = shuffleMenuItem.state == NSControl.StateValue.on ? NSControl.StateValue.off : NSControl.StateValue.on
        self.mainWindowController.shuffleButton.state = shuffleMenuItem.state
        self.mainWindowController.shuffleButtonPressed(self)
    }
    
    @IBAction func repeatMenuItemAction(_ sender: AnyObject) {
        repeatMenuItem.state = repeatMenuItem.state == NSControl.StateValue.on ? NSControl.StateValue.off : NSControl.StateValue.on
        self.mainWindowController.repeatButton.state = repeatMenuItem.state
        self.mainWindowController.repeatButtonPressed(self)
    }
    
    @IBAction func openLibraryManager(_ sender: Any) {
        guard self.delegate.preferencesWindowController?.window == nil else { return }
        self.delegate.openPreferences(self)
        self.delegate.preferencesWindowController!.toolbar.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: "library")
        self.delegate.preferencesWindowController!.selectLibrary(self)
    }
    
    @IBAction func openImportWindow(_ sender: AnyObject) {
        guard self.delegate.importWindowController?.window == nil else { return }
        self.delegate.importWindowController = ImportWindowController(windowNibName: "ImportWindowController")
        self.delegate.importWindowController!.mainWindowController = mainWindowController
        self.delegate.importWindowController!.showWindow(self)
    }
}
