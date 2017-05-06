//
//  StupidNumberFormatter.swift
//  minimalTunes
//
//  Created by John Moody on 11/7/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class StupidNumberFormatter: Formatter {
    
    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if Int(partialString) != nil {
            return true
        } else {
            return false
        }
    }

    override func string(for obj: Any?) -> String? {
        if obj != nil {
            if let thing = obj as? NSNumber {
                return (obj as! NSNumber).int32Value > 0 ? String(describing: thing) : ""
            } else {
                return ""
            }
        } else {
            return ""
        }
    }
    
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if let num = Int(string) {
            obj?.pointee = num as AnyObject
            return true
        } else {
            return false
        }
    }
    
}
