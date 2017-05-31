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


    override func draw(_ dirtyRect: NSRect) {
        if self.shouldDrawFocusRing {
            NSSetFocusRingStyle(NSFocusRingPlacement.only)
            NSRectFill(self.bounds)
        }
        super.draw(dirtyRect)
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
    
    
    override func rightMouseDown(with theEvent: NSEvent) {
        let globalLocation = theEvent.locationInWindow
        let localLocation = self.convert(globalLocation, from: nil)
        let clickedRow = self.row(at: localLocation)
        if clickedRow != -1 {
            libraryTableViewController?.determineRightMouseDownTarget(clickedRow)
        }
        super.rightMouseDown(with: theEvent)
    }
    
    override func keyDown(with theEvent: NSEvent) {
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
            super.keyDown(with: theEvent)
        }
    }
}
