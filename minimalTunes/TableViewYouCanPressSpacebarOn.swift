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
    
    let types = ["Track"]

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    override func awakeFromNib() {
        Swift.print("im a fukn table view")
        //self.registerForDraggedTypes(types)
    }
    
    
    override func keyDown(theEvent: NSEvent) {
        if theEvent.keyCode == 49 {
            mainWindowController?.interpretSpacebarEvent()
        }
        else {
            super.keyDown(theEvent)
        }
    }
    
    
    override func menuForEvent(event: NSEvent) -> NSMenu? {
        //try to draw a fuckign highlight for this row. impossible
        /*let row = self.rowAtPoint(self.convertPoint(event.locationInWindow, fromView: nil))
        let rect = rectOfRow(row)
        let view = rowViewAtRow(row, makeIfNecessary: false)
        view?.setNeedsDisplayInRect(rect)
        let path = NSBezierPath(rect: rect)
        
        NSColor(calibratedRed: 100, green: 200, blue: 100, alpha: 0).set()
        path.stroke()*/
        return self.menu
    }
    
}
