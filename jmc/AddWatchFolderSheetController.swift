//
//  AddWatchFolderSheetController.swift
//  jmc
//
//  Created by John Moody on 4/17/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class AddWatchFolderSheetController: NSWindowController {
    
    @IBOutlet weak var okButton: NSButton!
    var libraryManager: LibraryManagerViewController?
    
    @IBOutlet weak var pathControl: NSPathControl!

    @IBAction func browsePressed(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        let modalResult = panel.runModal()
        if modalResult == NSFileHandlingPanelOKButton {
            self.pathControl.url = panel.urls[0]
        }
    }
    @IBAction func okPressed(_ sender: Any) {
        self.libraryManager?.addWatchFolder(pathControl.url!)
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
