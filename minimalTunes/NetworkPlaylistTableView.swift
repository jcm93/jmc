//
//  NetworkPlaylistTableView.swift
//  
//
//  Created by John Moody on 10/3/16.
//
//

import Cocoa

class NetworkPlaylistTableView: NSTableView {

    var mainWindowController: MainWindowController?
    var windowIdentifier: String?
    
    let types = ["Track"]
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        // Drawing code here.
    }
    
    override func awakeFromNib() {
        //Swift.print("im a fukn table view")
        //self.registerForDraggedTypes(types)
    }
    
    
    override func keyDown(theEvent: NSEvent) {
        if theEvent.keyCode == 49 {
            mainWindowController?.interpretSpacebarEvent()
        }
        else if theEvent.keyCode == 36 {
            let fuck = (NSApplication.sharedApplication().delegate as! AppDelegate)
            let selectedNetworkTrack = fuck.mainWindowController?.networkPlaylistArrayController.selectedObjects[0] as! NetworkTrack
            fuck.server?.getTrack(Int(selectedNetworkTrack.id!), libraryName: "test library")
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
