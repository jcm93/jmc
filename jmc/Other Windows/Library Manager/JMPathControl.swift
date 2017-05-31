//
//  JMPathControl.swift
//  jmc
//
//  Created by John Moody on 4/17/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class JMPathControl: NSPathControl {
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
