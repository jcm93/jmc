//
//  MTTextFieldCell.swift
//  minimalTunes
//
//  Created by John Moody on 12/13/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class MTTextFieldCell: NSTextFieldCell {
    
    override var objectValue: Any? {
        set(newValue) {
            if let actualValue = newValue as? (Any?, Bool) {
                if let num = actualValue.0 as? Int {
                    super.objectValue = num
                } else {
                    super.objectValue = String(describing: actualValue.0 ?? "")
                }
                self.isEnabled = actualValue.1
            }
        }
        get {
            return super.objectValue
        }
    }
    
}
