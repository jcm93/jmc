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
        self.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: "SourceListItem"), NSPasteboard.PasteboardType(rawValue: "Track"), NSPasteboard.PasteboardType(rawValue: "NetworkTrack")])
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    override func keyDown(with theEvent: NSEvent) {
        if (theEvent.keyCode == 49) {
            mainWindowController?.interpretSpacebarEvent()
        }
        else {
            super.keyDown(with: theEvent)
        }
    }
    
}
