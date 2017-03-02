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
    
    var activeMonitoringURLs: [URL]?
    
    var eventStreamRef: FSEventStreamRef?
    
    let callback: @convention(c) (OpaquePointer, Optional<UnsafeMutableRawPointer>, Int, UnsafeMutableRawPointer, Optional<UnsafePointer<UInt32>>, Optional<UnsafePointer<UInt64>>) -> () = {
        (streamRef: ConstFSEventStreamRef, clientCallBackInfo: UnsafeMutableRawPointer?, numEvents: Int, eventPaths: UnsafeMutableRawPointer, eventFlags: UnsafePointer<FSEventStreamEventFlags>?, eventIds: UnsafePointer<FSEventStreamEventId>?) -> () in
        let currentLocationManagerInstance: LocationManager = Unmanaged<LocationManager>.fromOpaque(clientCallBackInfo!).takeUnretainedValue()
        currentLocationManagerInstance.updateLastEventID()
        let pathsArray = Unmanaged<NSArray>.fromOpaque(eventPaths).takeUnretainedValue()
        for i in 0..<numEvents {
            currentLocationManagerInstance.handleEvent(path: pathsArray[i] as! String, flags: eventFlags![i], id: eventIds![i])
            print("flag: \(eventFlags![i])")
            print("path: \(pathsArray[i])")
            print("eventID: \(eventIds![i])")
            print("")
        }
    }
    
    func handleEvent(path: String, flags: FSEventStreamEventFlags, id: UInt64) {
        if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagRootChanged)) > 0 {
            //relocate directory
        }
        if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagMustScanSubDirs)) > 0 {
            //verify the directory
        }
    }
    
    func updateLastEventID() {
        globalRootLibrary?.last_fs_event = FSEventStreamGetLatestEventId(self.eventStreamRef!) as NSNumber?
    }
    
    func initializeEventStreams(libraries: [Library]) {
        let lastEventID = globalRootLibrary!.last_fs_event as! FSEventStreamEventId
        let urls = libraries.flatMap({return URL(string: $0.library_location!)})
        self.activeMonitoringURLs?.append(contentsOf: urls)
        let urlPaths = urls.map({return $0.path})
        createEventStream(paths: urlPaths, lastID: lastEventID)
    }
    
    func createEventStream(paths: [String], lastID: FSEventStreamEventId?) {
        let flag = kFSEventStreamCreateFlagIgnoreSelf | kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagWatchRoot
        let pathsCFArrayWrapper = paths as CFArray
        var streamContext = FSEventStreamContext(version: 0, info: Unmanaged.passRetained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        if let newEventStream = FSEventStreamCreate(kCFAllocatorDefault, callback, &streamContext, pathsCFArrayWrapper, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 1, FSEventStreamCreateFlags(flag)) {
            let poop = CFRunLoopMode.defaultMode.rawValue
            FSEventStreamScheduleWithRunLoop(newEventStream, CFRunLoopGetCurrent(), poop)
            FSEventStreamStart(newEventStream)
            eventStreamRef = newEventStream
        }
    }
    
    func closeEventStream(eventStream: FSEventStreamRef) {
        globalRootLibrary?.last_fs_event = FSEventStreamGetLatestEventId(self.eventStreamRef!) as NSNumber?
        FSEventStreamStop(eventStream)
        FSEventStreamInvalidate(eventStream)
        FSEventStreamRelease(eventStream)
    }
}
