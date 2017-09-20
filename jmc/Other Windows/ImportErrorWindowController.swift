//
//  ImportErrorWindowController.swift
//  minimalTunes
//
//  Created by John Moody on 1/17/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class ImportErrorWindowController: NSWindowController {
    
    @IBOutlet weak var errorTableView: NSTableView!
    @IBOutlet var errorArrayController: NSArrayController!
    @IBOutlet weak var errorStringTextField: NSTextField!
    var errors: [FileAddToDatabaseError]?

    override func windowDidLoad() {
        if errors!.count > 1 {
            errorStringTextField.stringValue = "\(errors!.count) items were not imported:"
        } else {
            errorStringTextField.stringValue = "1 item was not imported:"
        }
        super.windowDidLoad()
        self.window!.titleVisibility = NSWindow.TitleVisibility.hidden
        self.window!.titlebarAppearsTransparent = true
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
