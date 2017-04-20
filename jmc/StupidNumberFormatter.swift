//
//  StupidNumberFormatter.swift
//  minimalTunes
//
//  Created by John Moody on 11/7/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class StupidNumberFormatter: Formatter {

    override func string(for obj: Any?) -> String? {
        if obj != nil {
            if let thing = obj as? NSNumber {
                return (obj as! NSNumber).int32Value > 0 ? String(describing: thing) : ""
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AutoreleasingUnsafeMutablePointer<AnyObject?>>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<AutoreleasingUnsafeMutablePointer<NSString?>>?) -> Bool {
        return false
    }
    
}
