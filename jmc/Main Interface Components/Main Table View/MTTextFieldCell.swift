//
//  MTTextFieldCell.swift
//  minimalTunes
//
//  Created by John Moody on 12/13/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class MTTextFieldCell: NSTextFieldCell {
    
    var defaultColor: NSColor!
    
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        let newRect = NSRect(x: rect.origin.x, y: rect.origin.y + 1.0, width: rect.width, height: rect.height - 1)
        return newRect
    }
    
    override var objectValue: Any? {
        set(newValue) {
            if let actualValue = newValue as? (Any?, Bool) {
                self.isEnabled = actualValue.1
                if actualValue.1 == false {
                    self.isEditable = false
                    self.textColor = NSColor.disabledControlTextColor
                } else {
                    self.isEditable = true
                    self.textColor = self.defaultColor
                }
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
