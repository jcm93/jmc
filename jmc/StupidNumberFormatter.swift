//
//  StupidNumberFormatter.swift
//  minimalTunes
//
//  Created by John Moody on 11/7/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class StupidNumberFormatter: NSFormatter {

    override func stringForObjectValue(obj: AnyObject) -> String? {
        return (obj as! NSNumber).intValue > 0 ? obj.description : ""
    }
    
    override func getObjectValue(obj: AutoreleasingUnsafeMutablePointer<AnyObject?>, forString string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
        return false
    }
    
}
