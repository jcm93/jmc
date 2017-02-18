//
//  LocationManager.swift
//  jmc
//
//  Created by John Moody on 2/17/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa
import CoreServices

class LocationManager: NSObject {
    
    var eventStreamRef: FSEventStreamRef?
    
    let callback: @convention(c) (OpaquePointer, Optional<UnsafeMutableRawPointer>, Int, UnsafeMutableRawPointer, Optional<UnsafePointer<UInt32>>, Optional<UnsafePointer<UInt64>>) -> () = {
        (streamRef: ConstFSEventStreamRef, clientCallBackInfo: UnsafeMutableRawPointer?, numEvents: Int, eventPaths: UnsafeMutableRawPointer, eventFlags: UnsafePointer<FSEventStreamEventFlags>?, eventIds: UnsafePointer<FSEventStreamEventId>?) -> () in
        print("doingus")
        
    }
    
    func createEventStream(paths: CFArray, lastID: FSEventStreamEventId?) {
        let flag = kFSEventStreamCreateFlagIgnoreSelf & kFSEventStreamCreateFlagFileEvents
        let newEventStream = FSEventStreamCreate(kCFAllocatorDefault, callback, nil, paths, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 1, FSEventStreamCreateFlags(flag))
        let poop = CFRunLoopMode.defaultMode.rawValue
        FSEventStreamScheduleWithRunLoop(newEventStream!, CFRunLoopGetCurrent(), poop)
        FSEventStreamStart(newEventStream!)
        eventStreamRef = newEventStream
        print("dongs")
    }

}
