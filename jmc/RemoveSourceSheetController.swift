//
//  RemoveSourceSheetController.swift
//  jmc
//
//  Created by John Moody on 3/25/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class RemoveSourceSheetController: NSWindowController {
    
    var libraryManagerSourceSelector: LibraryManagerSourceSelector?
    
    @IBOutlet weak var cancelButton: NSButton!
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.window?.close()
    }
    @IBAction func okButtonPressed(_ sender: Any) {
        libraryManagerSourceSelector!.removeLibrary()
        self.window?.close()
        libraryManagerSourceSelector?.removeSourceModalComplete(response: 0)
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
