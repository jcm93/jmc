//
//  SpecialScrollView.swift
//  minimalTunes
//
//  Created by John Moody on 12/14/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class SpecialScrollView: NSScrollView {
    
    static override func isCompatibleWithResponsiveScrolling() -> Bool {
        return false
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
