//
//  ChangePrimaryFolderSheetController.swift
//  jmc
//
//  Created by John Moody on 4/22/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class ChangePrimaryFolderSheetController: NSWindowController {
    
    @IBOutlet weak var okButton: NSButton!
    var libraryManager: LibraryManagerViewController?
    
    @IBOutlet weak var errorText: NSTextField!
    @IBOutlet weak var pathControl: NSPathControl!
    
    @IBAction func browsePressed(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        let modalResult = panel.runModal()
        if modalResult.rawValue == NSFileHandlingPanelOKButton {
            self.pathControl.url = panel.urls[0]
        }
    }
    
    @IBAction func okPressed(_ sender: Any) {
        changeLibraryCentralMediaFolder(library: libraryManager!.library!, newLocation: pathControl.url!)
        if libraryManager?.library?.keeps_track_of_files == true || libraryManager?.library?.monitors_directories_for_new == true {
            libraryManager?.locationManager.reinitializeEventStream()
        }
        libraryManager!.initializeForLibrary(library: libraryManager!.library!)
        self.window?.close()
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.window?.close()
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
