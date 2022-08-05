//
//  LibrarySplitView.swift
//  jmc
//
//  Created by John Moody on 8/4/22.
//  Copyright © 2022 John Moody. All rights reserved.
//

import Cocoa

class LibrarySplitView: NSSplitView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override var allowsVibrancy: Bool {
        return true
    }
    
}
