//
//  BitRateFormatter.swift
//  minimalTunes
//
//  Created by John Moody on 11/7/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class BitRateFormatter: NSNumberFormatter {
    
    override func stringForObjectValue(obj: AnyObject) -> String? {
        return (obj as! NSNumber).descriptionWithLocale(NSLocale.currentLocale()) + " kbps"
    }
    
    override func getObjectValue(obj: AutoreleasingUnsafeMutablePointer<AnyObject?>, forString string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
        return false
    }

}
