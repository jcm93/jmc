//
//  TransformerIntegerToTimestamp.swift
//  minimalTunes
//
//  Created by John Moody on 6/11/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class TransformerIntegerToTimestamp: NSValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        guard let type = value as? NSNumber else {
            return nil
        }
        let hr = type.integerValue / 3600000
        let min = (type.integerValue - (hr * 3600000)) / 60000
        let sec = (type.integerValue - (hr * 3600000) - (min * 60000)) / 1000
        var stamp = ""
        if (sec < 10) {
            stamp = "\(min):0\(sec)"
        }
        else {
            stamp = "\(min):\(sec)"
        }
        if hr != 0 {
            if (min < 10) {
                stamp = "\(hr):0\(stamp)"
            }
            else {
                stamp = "\(hr):\(stamp)"
            }
        }
        return stamp
    }
}
