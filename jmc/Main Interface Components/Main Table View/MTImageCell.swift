//
//  MTImageCell.swift
//  jmc
//
//  Created by John Moody on 3/26/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class MTImageCell: NSImageCell {
    
    override func imageRect(forBounds rect: NSRect) -> NSRect {
        let transform = CGAffineTransform(translationX: 6.0, y: 0.0)
        return rect.applying(transform)
    }
    
    override var objectValue: Any? {
        set(newValue) {
            if let actualValue = newValue as? (Any?, Bool) {
                super.objectValue = actualValue.0 as? NSImage
                self.isEnabled = actualValue.1
            }
        }
        get {
            return super.objectValue
        }
    }
}
