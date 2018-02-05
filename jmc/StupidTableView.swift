//
//  StupidTableView.swift
//  jmc
//
//  Created by John Moody on 6/16/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class StupidTableView: NSTableView {
    
    override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
        return responder is NSControl || responder is NSTokenField || responder is NSTextView
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
