//
//  AddPlaylistButton.swift
//  minimalTunes
//
//  Created by John Moody on 1/5/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class AddPlaylistButton: NSSegmentedControl {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        self.setMenu(self.menu, forSegment: 0)

        // Drawing code here.
    }
    
}
