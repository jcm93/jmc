//
//  JMDateFormatter.swift
//  jmc
//
//  Created by John Moody on 6/20/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class JMDateFormatter: DateFormatter {
    
    var components = Set([Calendar.Component.month, Calendar.Component.weekday, Calendar.Component.day, Calendar.Component.year])
    
    override func string(for obj: Any?) -> String? {
        //could probably be written better
        guard let date = obj as? JMDate else {
            return nil
        }
        let components = Calendar.current.dateComponents(self.components, from: date.date as Date)
        var month, weekday: String?
        var day: Int?
        if date.hasMonth {
            month = self.monthSymbols[components.month! - 1]
            if date.hasDay {
                weekday = self.weekdaySymbols[components.weekday! - 1]
                day = components.day!
            }
        }
        if date.hasDay {
            print("dongles")
        }
        return "\(weekday != nil ? "\(weekday!), " : "")\(month != nil ? "\(month!) \(day != nil ? "\(day!), " : "")" : "")\(components.year!)".trimmingCharacters(in: CharacterSet.whitespaces)
        
    }
    
    func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AutoreleasingUnsafeMutablePointer<AnyObject?>>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<AutoreleasingUnsafeMutablePointer<NSString?>>?) -> Bool {
        return false
    }
    

}
