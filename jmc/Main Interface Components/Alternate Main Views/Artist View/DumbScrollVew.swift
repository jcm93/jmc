//
//  DumbScrollVew.swift
//  jmc
//
//  Created by John Moody on 12/25/21.
//  Copyright © 2021 John Moody. All rights reserved.
//

import Cocoa

class DumbScrollVew: NSScrollView {
    
    override func scrollWheel(with event: NSEvent) {
        self.nextResponder?.scrollWheel(with: event)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
