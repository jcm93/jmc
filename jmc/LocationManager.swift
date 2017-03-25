//
//  LocationManager.swift
//  jmc
//
//  Created by John Moody on 2/17/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreServices
import CoreData

struct TrackFirstRenameEvent {
    let track: Track?
    let initialPath: String
    let id: UInt64
    let flags: FSEventStreamEventFlags
    init(path: String, id: UInt64, flags: FSEventStreamEventFlags, track: Track?) {
        self.initialPath = path
        self.id = id
        self.flags = flags
        self.track = track
    }
}

class LocationManager: NSObject {
    
    var activeMonitoringURLs = Set<URL>()
    var activeMonitoringFileDescriptors = [String : Int32]()
    var libraryURLDictionary = [URL : Library]()
    var fileManager = FileManager.default
    var withinDirRenameEvents = [String : TrackFirstRenameEvent?]()
    var databaseManager = DatabaseManager()
    
    var eventStreamRef: FSEventStreamRef?
    
    let callback: @convention(c) (OpaquePointer, Optional<UnsafeMutableRawPointer>, Int, UnsafeMutableRawPointer, Optional<UnsafePointer<UInt32>>, Optional<UnsafePointer<UInt64>>) -> () = {
        (streamRef: ConstFSEventStreamRef, clientCallBackInfo: UnsafeMutableRawPointer?, numEvents: Int, eventPaths: UnsafeMutableRawPointer, eventFlags: UnsafePointer<FSEventStreamEventFlags>?, eventIds: UnsafePointer<FSEventStreamEventId>?) -> () in
        let currentLocationManagerInstance: LocationManager = Unmanaged<LocationManager>.fromOpaque(clientCallBackInfo!).takeUnretainedValue()
        let pathsArray = Unmanaged<NSArray>.fromOpaque(eventPaths).takeUnretainedValue()
        print("number of events: \(numEvents)")
        print("")
        for i in 0..<numEvents {
            currentLocationManagerInstance.handleEvent(path: pathsArray[i] as! String, flags: eventFlags![i], id: eventIds![i])
            print("flag: \(eventFlags![i])")
            print("path: \(pathsArray[i])")
            print("eventID: \(eventIds![i])")
            print("")
            currentLocationManagerInstance.updateLastEventID()
        }
    }
    
    func handleEvent(path: String, flags: FSEventStreamEventFlags, id: UInt64) {
        if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagRootChanged)) > 0 {
            print("root changed")
            //relocate directory
            
            let fileDescriptor = activeMonitoringFileDescriptors[path]!
            var newPath = [UInt8](repeating: 0, count: Int(PATH_MAX))
            fcntl(fileDescriptor, F_GETPATH, &newPath)
            let newPathString = String(cString: newPath)
            
            //change the library's library_location, update the activeMonitoringURLs and libraryURLDictionary, posix close open file descriptors, then re-initialize the stream
            
            let oldURL = URL(fileURLWithPath: "\(path)/")
            let library = libraryURLDictionary[oldURL]
            let newURL = URL(fileURLWithPath: newPathString)
            changeLibraryLocation(library: library!, newLocation: newURL)
            
            //libraryURLDictionary
            
            libraryURLDictionary.removeValue(forKey: oldURL)
            libraryURLDictionary[newURL] = library
            
            //activeMonitoringURLs
            
            activeMonitoringURLs.remove(oldURL)
            activeMonitoringURLs.update(with: newURL)
            
            //close file descriptors
            
            for fileDes in activeMonitoringFileDescriptors.values {
                close(fileDes)
            }
            activeMonitoringFileDescriptors.removeAll()
            
            //re-initialize stream
            
            reinitializeEventStream()
        }
        if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagMustScanSubDirs)) > 0 {
            //verify the directory
            do {
                let contentsOfDir = try fileManager.contentsOfDirectory(atPath: path)
                ///uhh
            } catch {
                
            }
            
        } else if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated)) > 0 {
            print("item created")
        } else if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed)) > 0 {
            print("item renamed")
            let rootDirectoryPaths = activeMonitoringFileDescriptors.map({return $0.key}).filter({return path.lowercased().hasPrefix($0.lowercased())})
            guard rootDirectoryPaths.count == 1 else {return}
            let rootDirectoryPath = rootDirectoryPaths.first!
            if withinDirRenameEvents[rootDirectoryPath]??.id == id - 1 {
                //this is definitely the second half of another rename event, which we may or may not care about
                let firstEvent = withinDirRenameEvents[rootDirectoryPath]!
                if firstEvent!.track != nil {
                    firstEvent!.track!.location = URL(fileURLWithPath: path).absoluteString
                }
                withinDirRenameEvents[rootDirectoryPath] = nil
            } else {
                //either this location is valid and a new file was added, or...
                if fileManager.fileExists(atPath: path) {
                    let library = self.libraryURLDictionary[URL(fileURLWithPath: rootDirectoryPath)]!
                    if library.monitors_directories_for_new as! Bool {
                        databaseManager.addTracksFromURLs([URL(fileURLWithPath: path)], to: library) //ignores errors :(
                    }
                } else {
                    //...or this is the first half of a rename event, which we may or may not care about
                    let track = {() -> Track? in
                        let fr = NSFetchRequest<Track>(entityName: "Track")
                        fr.predicate = NSPredicate(format: "location contains[c] %@", URL(fileURLWithPath: path).absoluteString)
                        do {
                            let track = try managedContext.fetch(fr)
                            if track.count == 1 {
                                return track[0]
                            } else {
                                return nil
                            }
                        } catch {
                            print(error)
                        }
                        return nil
                    }()
                    let newFirstHalfEvent = TrackFirstRenameEvent(path: path, id: id, flags: flags, track: track)
                    withinDirRenameEvents[rootDirectoryPath] = newFirstHalfEvent
                }
            }
        }
    }
    
    func reinitializeEventStream() {
        if eventStreamRef != nil {
            closeEventStream(eventStream: self.eventStreamRef!)
        }
        initializeEventStream(libraries: getAllLibraries()!)
    }
    
    func updateLastEventID() {
        globalRootLibrary?.last_fs_event = FSEventStreamGetLatestEventId(self.eventStreamRef!) as NSNumber?
    }
    
    func initializeEventStream(libraries: [Library]) {
        let lastEventID = globalRootLibrary!.last_fs_event as? FSEventStreamEventId
        let urls = libraries.flatMap({ (library: Library) -> URL? in
            if let url = URL(string: library.library_location!), library.watches_directories == true {
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
        let lastEventID = lastID ?? FSEventStreamEventId(kFSEventStreamEventIdSinceNow)
        if paths.count > 0 {
            if let newEventStream = FSEventStreamCreate(kCFAllocatorDefault, callback, &streamContext, pathsCFArrayWrapper, lastEventID, 1, FSEventStreamCreateFlags(flag)) {
                for path in paths {
                    let fileDescriptor = open(path, O_RDONLY, 0)
                    activeMonitoringFileDescriptors[path] = fileDescriptor
                }
                let poop = CFRunLoopMode.defaultMode.rawValue
                FSEventStreamScheduleWithRunLoop(newEventStream, CFRunLoopGetCurrent(), poop)
                FSEventStreamStart(newEventStream)
                self.eventStreamRef = newEventStream
                print("event stream created")
            } else {
                print("event stream creation failure")
            }
        }
    }
    
    func closeEventStream(eventStream: FSEventStreamRef) {
        FSEventStreamStop(eventStream)
        FSEventStreamInvalidate(eventStream)
        FSEventStreamRelease(eventStream)
    }
}
