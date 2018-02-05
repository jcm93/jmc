//
//  StupidPredicateEditor.swift
//  jmc
//
//  Created by John Moody on 6/16/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class StupidPredicateEditor: NSPredicateEditor {
    
    override func mouseDown(with event: NSEvent) {
        Swift.print("called")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
