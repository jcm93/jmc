//
//  TableViewYouCanPressSpacebarOn.swift
//  minimalTunes
//
//  Created by John Moody on 6/20/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class TableViewYouCanPressSpacebarOn: NSTableView {
    
    var mainWindowController: MainWindowController?
    var windowIdentifier: String?

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    override func keyDown(theEvent: NSEvent) {
        if theEvent.keyCode == 49 {
            if mainWindowController?.paused == true {
                mainWindowController?.unpause()
            }
            else {
                mainWindowController?.pause()
            }
        }
        else {
            super.keyDown(theEvent)
        }
    }
    
}
