//
//  MTTextFieldCell.swift
//  minimalTunes
//
//  Created by John Moody on 12/13/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class MTTextFieldCell: NSTextFieldCell {
    
    override func titleRect(forBounds rect: NSRect) -> NSRect {
        let newRect = NSRect(x: rect.origin.x, y: rect.origin.y + 1.0, width: rect.width - 4.0, height: rect.height)
        return newRect
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        let titleRect = self.titleRect(forBounds: cellFrame)
        self.attributedStringValue.draw(in: titleRect)
    }
    
    override init(textCell string: String) {
        super.init(textCell: string)
        self.font = NSFont.systemFont(ofSize: 12.0)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.font = NSFont.systemFont(ofSize: 12.0)
    }
    
    override var objectValue: Any? {
        set(newValue) {
            if let actualValue = newValue as? (Any?, Bool) {
                self.isEnabled = actualValue.1
                super.objectValue = actualValue.0
            } else {
                super.objectValue = newValue
            }
        }
        get {
            return super.objectValue
        }
    }
}
