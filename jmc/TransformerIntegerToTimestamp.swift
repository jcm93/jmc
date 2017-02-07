//
//  TransformerIntegerToTimestamp.swift
//  minimalTunes
//
//  Created by John Moody on 6/11/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class TransformerIntegerToTimestamp: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    override func transformedValue(_ value: Any?) -> Any? {
        guard let type = value as? NSNumber else {
            return nil
        }
        let hr = type.intValue / 3600000
        let min = (type.intValue - (hr * 3600000)) / 60000
        let sec = (type.intValue - (hr * 3600000) - (min * 60000)) / 1000
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
