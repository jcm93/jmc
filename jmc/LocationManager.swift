//
//  LocationManager.swift
//  jmc
//
//  Created by John Moody on 2/17/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreServices

class LocationManager: NSObject {
    
    var activeMonitoringURLs = Set<URL>()
    var activeMonitoringFileDescriptors = [String : Int32]()
    var libraryURLDictionary = [URL: Library]()
    var fileManager = FileManager.default
    
    var eventStreamRef: FSEventStreamRef?
    
    let callback: @convention(c) (OpaquePointer, Optional<UnsafeMutableRawPointer>, Int, UnsafeMutableRawPointer, Optional<UnsafePointer<UInt32>>, Optional<UnsafePointer<UInt64>>) -> () = {
        (streamRef: ConstFSEventStreamRef, clientCallBackInfo: UnsafeMutableRawPointer?, numEvents: Int, eventPaths: UnsafeMutableRawPointer, eventFlags: UnsafePointer<FSEventStreamEventFlags>?, eventIds: UnsafePointer<FSEventStreamEventId>?) -> () in
        let currentLocationManagerInstance: LocationManager = Unmanaged<LocationManager>.fromOpaque(clientCallBackInfo!).takeUnretainedValue()
        currentLocationManagerInstance.updateLastEventID()
        let pathsArray = Unmanaged<NSArray>.fromOpaque(eventPaths).takeUnretainedValue()
        print("number of events: \(numEvents)")
        print("")
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
            
            let fileDescriptor = activeMonitoringFileDescriptors[path]!
            var newPath = [UInt8](repeating: 0, count: Int(PATH_MAX))
            fcntl(fileDescriptor, F_GETPATH, &newPath)
            let newPathString = String(cString: newPath)
            
            //change the library's library_location, update the activeMonitoringURLs and libraryURLDictionary, then re-initialize the stream
            
            let oldURL = URL(fileURLWithPath: path)
            let library = libraryURLDictionary[oldURL]
            let newURL = URL(fileURLWithPath: newPathString)
            library?.library_location = newURL.absoluteString
            
            //libraryURLDictionary
            
            libraryURLDictionary.removeValue(forKey: oldURL)
            libraryURLDictionary[newURL] = library
            
            //activeMonitoringURLs
            
            activeMonitoringURLs.remove(oldURL)
            activeMonitoringURLs.update(with: newURL)
            
            //re-initialize stream
            
            closeEventStream(eventStream: self.eventStreamRef!)
            let libraries = getAllLibraries()!
            initializeEventStream(libraries: libraries)
        }
        if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagMustScanSubDirs)) > 0 {
            //verify the directory
            do {
                let contentsOfDir = try fileManager.contentsOfDirectory(atPath: path)
            } catch {
                
            }
            //hmm
            
        }
    }
    
    func updateLastEventID() {
        globalRootLibrary?.last_fs_event = FSEventStreamGetLatestEventId(self.eventStreamRef!) as NSNumber?
    }
    
    func initializeEventStream(libraries: [Library]) {
        let lastEventID = globalRootLibrary!.last_fs_event as! FSEventStreamEventId
        let urls = libraries.flatMap({ (library: Library) -> URL? in
            if let url = URL(string: library.library_location!) {
                self.libraryURLDictionary[url] = library
                return url
            } else {
                return nil
            }
        })
        self.activeMonitoringURLs = Set(urls)
        let urlPaths = urls.map({return $0.path})
        createEventStream(paths: urlPaths, lastID: lastEventID)
    }
    
    func createEventStream(paths: [String], lastID: FSEventStreamEventId?) {
        let flag = kFSEventStreamCreateFlagIgnoreSelf | kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagWatchRoot
        let pathsCFArrayWrapper = paths as CFArray
        var streamContext = FSEventStreamContext(version: 0, info: Unmanaged.passRetained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        if let newEventStream = FSEventStreamCreate(kCFAllocatorDefault, callback, &streamContext, pathsCFArrayWrapper, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 1, FSEventStreamCreateFlags(flag)) {
            for path in paths {
                let fileDescriptor = open(path, O_RDONLY, 0)
                activeMonitoringFileDescriptors[path] = fileDescriptor
            }
            let poop = CFRunLoopMode.defaultMode.rawValue
            FSEventStreamScheduleWithRunLoop(newEventStream, CFRunLoopGetCurrent(), poop)
            FSEventStreamStart(newEventStream)
            self.eventStreamRef = newEventStream
        }
    }
    
    func closeEventStream(eventStream: FSEventStreamRef) {
        FSEventStreamStop(eventStream)
        FSEventStreamInvalidate(eventStream)
        FSEventStreamRelease(eventStream)
    }
}
