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
    var trackQueueViewController: TrackQueueViewController?
    var windowIdentifier: String?
    
    var shouldDrawFocusRing = false
    
    let types = ["Track"]


    override func drawRect(dirtyRect: NSRect) {
        if self.shouldDrawFocusRing {
            NSSetFocusRingStyle(NSFocusRingPlacement.Only)
            NSRectFill(self.bounds)
        }
        super.drawRect(dirtyRect)
        // Drawing code here.
    }
    
    override func awakeFromNib() {
        //self.registerForDraggedTypes(types)
    }
    
    /*override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        if sender.draggingPasteboard().types!.contains(NSFilenamesPboardType) {
            self.shouldDrawFocusRing = true
            self.setKeyboardFocusRingNeedsDisplayInRect(self.bounds)
        }
        let operation = super.draggingEntered(sender)
        self.drawRect(self.bounds)
        return operation
    }
    
    override func draggingExited(sender: NSDraggingInfo?) {
        self.shouldDrawFocusRing = false
        self.setKeyboardFocusRingNeedsDisplayInRect(self.bounds)
        super.draggingExited(sender)
    }
    
    override func concludeDragOperation(sender: NSDraggingInfo?) {
        self.shouldDrawFocusRing = false
        self.setKeyboardFocusRingNeedsDisplayInRect(self.bounds)
        super.concludeDragOperation(sender)
    }*/
    
    
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
        Swift.print("\(theEvent.keyCode) was pressed")
        if theEvent.keyCode == 49 {
            libraryTableViewController?.interpretSpacebarEvent()
        } else if theEvent.keyCode == 36 {
            libraryTableViewController?.interpretEnterEvent()
        } else if theEvent.keyCode == 51 {
            libraryTableViewController?.interpretDeleteEvent()
            trackQueueViewController?.interpretDeleteEvent()
        }
        else {
            super.keyDown(theEvent)
        }
    }
}
