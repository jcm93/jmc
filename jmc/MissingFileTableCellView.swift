//
//  MissingFileTableCellView.swift
//  jmc
//
//  Created by John Moody on 6/16/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class MissingFileTableCellView: NSTableCellView {
    
    var representedNode: MissingTrackPathNode!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}

class MissingFileCellViewWithLocateButton: MissingFileTableCellView {
    
    @IBOutlet var locateButton: NSButton!
    
}
