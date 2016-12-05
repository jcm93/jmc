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
    var libraryTableViewController: LibraryTableViewController?
    var windowIdentifier: String?
    
    let types = ["Track"]

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    override func awakeFromNib() {
        Swift.print("im a fukn table view")
        //self.registerForDraggedTypes(types)
    }
    
    
    override func rightMouseDown(theEvent: NSEvent) {
        let globalLocation = theEvent.locationInWindow
        let localLocation = self.convertPoint(globalLocation, fromView: nil)
        let clickedRow = self.rowAtPoint(localLocation)
        if clickedRow != -1 {
            libraryTableViewController?.determineRightMouseDownTarget(clickedRow)
        }
        super.rightMouseDown(theEvent)
    }
    
    override func keyDown(theEvent: NSEvent) {
        if theEvent.keyCode == 49 {
            mainWindowController?.interpretSpacebarEvent()
        }
        else {
            super.keyDown(theEvent)
        }
    }
}
