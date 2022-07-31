//
//  ArtistListTableView.swift
//  jmc
//
//  Created by John Moody on 7/18/22.
//  Copyright © 2022 John Moody. All rights reserved.
//

import Cocoa

class ArtistListTableView: NSTableView {
    
    var mainWindowController: MainWindowController?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func keyDown(with theEvent: NSEvent) {
        Swift.print("\(theEvent.keyCode) was pressed")
        if theEvent.keyCode == 49 {
            self.mainWindowController?.interpretSpacebarEvent()
        } else if theEvent.keyCode == 36 {
            //self.mainWindowController.interpretEnterEvent()
        } else if theEvent.keyCode == 51 {
            //libraryTableViewController?.interpretDeleteEvent()
            //trackQueueViewController?.interpretDeleteEvent()
        }
        else {
            super.keyDown(with: theEvent)
        }
    }
    
}
