//
//  PreferencesWindowController.swift
//  minimalTunes
//
//  Created by John Moody on 7/8/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController {
    
    @IBOutlet weak var identifierTextField: NSTextField!
    @IBOutlet weak var tabView: NSTabView!

    @IBAction func generalPressed(sender: AnyObject) {
        tabView.selectTabViewItemAtIndex(0)
    }
    
    @IBAction func playbackPressed(sender: AnyObject) {
        tabView.selectTabViewItemAtIndex(1)
    }
    
    @IBAction func sharingPressed(sender: AnyObject) {
        tabView.selectTabViewItemAtIndex(2)
    }
    
    @IBAction func libraryPressed(sender: AnyObject) {
        tabView.selectTabViewItemAtIndex(3)
    }
    
    @IBAction func advancedPressed(sender: AnyObject) {
        tabView.selectTabViewItemAtIndex(4)
    }
    
    @IBAction func identifierChanged(sender: AnyObject) {
        print("identifier changed called")
        if identifierTextField.stringValue != "" {
            NSUserDefaults.standardUserDefaults().setObject(identifierTextField.stringValue, forKey: DEFAULTS_LIBRARY_NAME_STRING)
        }
    }
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
