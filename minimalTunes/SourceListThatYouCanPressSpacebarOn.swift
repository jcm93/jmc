//
//  SourceListThatYouCanPressSpacebarOn.swift
//  minimalTunes
//
//  Created by John Moody on 6/20/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class SourceListThatYouCanPressSpacebarOn: NSOutlineView {
    
    var mainWindowController: MainWindowController?
    
    override func awakeFromNib() {
        self.registerForDraggedTypes(["SourceListItem", "Track"])
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    override func keyDown(theEvent: NSEvent) {
        if (theEvent.keyCode == 49) {
            mainWindowController?.interpretSpacebarEvent()
        }
        else {
            super.keyDown(theEvent)
        }
    }
    
}
