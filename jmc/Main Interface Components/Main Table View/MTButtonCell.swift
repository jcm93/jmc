//
//  MTButtonCell.swift
//  jmc
//
//  Created by John Moody on 3/26/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class MTButtonCell: NSButtonCell {
    override var objectValue: Any? {
        set(newValue) {
            if let actualValue = newValue as? (Any?, Bool) {
                super.objectValue = actualValue.0 as? Int
                self.isEnabled = actualValue.1
            }
        }
        get {
            return super.objectValue
        }
    }
}
