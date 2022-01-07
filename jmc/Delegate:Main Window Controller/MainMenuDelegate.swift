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
    @IBOutlet weak var songsViewMenuItem: NSMenuItem!
    @IBOutlet weak var artistViewMenuItem: NSMenuItem!
    
    @IBAction func getInfoAction(_ sender: Any) {
        
    }
    
    @IBAction func deleteFromLibraryAction(_ sender: Any) {
        
    }
    @IBAction func songsViewMenuItemAction(_ sender: Any) {
        self.artistViewMenuItem.state = .off
        self.songsViewMenuItem.state = .on
        self.mainWindowController.songsViewSelected()
    }
    @IBAction func artistViewMenuItemAction(_ sender: Any) {
        self.songsViewMenuItem.state = .off
        self.artistViewMenuItem.state = .on
        self.mainWindowController.artistViewSelected()
    }
    
    func initializeViewState() {
        let viewTypeDefault = UserDefaults.standard.string(forKey: DEFAULTS_VIEW_TYPE_STRING)
        if viewTypeDefault == "songs" {
            songsViewMenuItem.state = .on
            artistViewMenuItem.state = .off
        } else if viewTypeDefault == "artists" {
            songsViewMenuItem.state = .off
            artistViewMenuItem.state = .on
        } else {
            songsViewMenuItem.state = .on
            artistViewMenuItem.state = .off
        }
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
        self.mainWindowController.createPlaylistFromTracks(self.mainWindowController.currentLibraryViewController!.getSelectedObjects().map({return $0.track!}))
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
