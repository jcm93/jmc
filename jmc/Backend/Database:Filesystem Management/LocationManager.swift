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
import Cocoa

struct TrackFirstRenameEvent {
    let tracks: [Track]?
    let initialPathAbsoluteURLString: String
    let flags: FSEventStreamEventFlags
    init(path: String, flags: FSEventStreamEventFlags, tracks: [Track]) {
        self.initialPathAbsoluteURLString = URL(fileURLWithPath: path).absoluteString
        self.flags = flags
        self.tracks = tracks
    }
}

class LocationManager: NSObject {
    
    var activeMonitoringURLs = Set<URL>()
    var activeMonitoringFileDescriptors = [String : Int32]()
    var fileManager = FileManager.default
    var firstHalfRenameEvents = [FSEventStreamEventId : TrackFirstRenameEvent]()
    var databaseManager = DatabaseManager()
    var pendingCreatePaths = [String]()
    var urlsToAddToDatabase = [URL]()
    var unpopulatedMetadataURLs = [URL]()
    var currentlyAddingFiles = false
    var delegate: AppDelegate
    
    var eventStreamRef: FSEventStreamRef?
    
    let callback: @convention(c) (OpaquePointer, Optional<UnsafeMutableRawPointer>, Int, UnsafeMutableRawPointer, UnsafePointer<UInt32>, UnsafePointer<UInt64>) -> () = {
        (streamRef: ConstFSEventStreamRef, clientCallBackInfo: UnsafeMutableRawPointer?, numEvents: Int, eventPaths: UnsafeMutableRawPointer, eventFlags: UnsafePointer<FSEventStreamEventFlags>, eventIds: UnsafePointer<FSEventStreamEventId>) -> () in
        let currentLocationManagerInstance: LocationManager = Unmanaged<LocationManager>.fromOpaque(clientCallBackInfo!).takeUnretainedValue()
        let pathsArray = Unmanaged<NSArray>.fromOpaque(eventPaths).takeUnretainedValue()
        print("number of events: \(numEvents)")
        print("")
        for i in 0..<numEvents {
            currentLocationManagerInstance.handleEvent(path: pathsArray[i] as! String, flags: eventFlags[i], id: eventIds[i])
            print("flag: \(eventFlags[i])")
            print("path: \(pathsArray[i])")
            print("eventID: \(eventIds[i])")
            print("")
            currentLocationManagerInstance.updateLastEventID()
        }
        DispatchQueue.global(qos: .default).async {
            currentLocationManagerInstance.tryAddNewFilesToDatabase()
        }
    }
    
    init(delegate: AppDelegate) {
        self.delegate = delegate
    }
    
    func tryAddNewFilesToDatabase() {
        if !self.urlsToAddToDatabase.isEmpty {
            print("adding chunks to queue")
            delegate.addFilesQueueLoop?.addChunksToQueue(urls: self.urlsToAddToDatabase)
            self.urlsToAddToDatabase = [URL]()
            if delegate.addFilesQueueLoop?.isRunning == false {
                print("starting queue loop")
                delegate.addFilesQueueLoop!.start()
            }
        }
    }
    
    func getFSEventFlags(flags: UInt32) -> [String]? {
        var stringArray = [String]()
        if UInt32(kFSEventStreamEventFlagNone) & flags > 0 {
            let d = String(kFSEventStreamEventFlagNone, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagNone, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagMustScanSubDirs) & flags > 0 {
            let d = String(kFSEventStreamEventFlagMustScanSubDirs, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagMustScanSubDirs, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagUserDropped) & flags > 0 {
            let d = String(kFSEventStreamEventFlagUserDropped, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagUserDropped, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagKernelDropped) & flags > 0 {
            let d = String(kFSEventStreamEventFlagKernelDropped, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagKernelDropped, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagEventIdsWrapped) & flags > 0 {
            let d = String(kFSEventStreamEventFlagEventIdsWrapped, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagEventIdsWrapped, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagHistoryDone) & flags > 0 {
            let d = String(kFSEventStreamEventFlagHistoryDone, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagHistoryDone, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagRootChanged) & flags > 0 {
            let d = String(kFSEventStreamEventFlagRootChanged, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagRootChanged, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagMount) & flags > 0 {
            let d = String(kFSEventStreamEventFlagMount, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagMount, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagUnmount) & flags > 0 {
            let d = String(kFSEventStreamEventFlagUnmount, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagUnmount, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagItemChangeOwner) & flags > 0 {
            let d = String(kFSEventStreamEventFlagItemChangeOwner, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagItemChangeOwner, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagItemCreated) & flags > 0 {
            let d = String(kFSEventStreamEventFlagItemCreated, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagItemCreated, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagItemFinderInfoMod) & flags > 0 {
            let d = String(kFSEventStreamEventFlagItemFinderInfoMod, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagItemFinderInfoMod, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagItemInodeMetaMod) & flags > 0 {
            let d = String(kFSEventStreamEventFlagItemInodeMetaMod, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagItemInodeMetaMod, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagItemIsDir) & flags > 0 {
            let d = String(kFSEventStreamEventFlagItemIsDir, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagItemIsDir, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagItemIsFile) & flags > 0 {
            let d = String(kFSEventStreamEventFlagItemIsFile, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagItemIsFile, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagItemIsHardlink) & flags > 0 {
            let d = String(kFSEventStreamEventFlagItemIsHardlink, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagItemIsHardlink, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagItemIsLastHardlink) & flags > 0 {
            let d = String(kFSEventStreamEventFlagItemIsLastHardlink, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagItemIsLastHardlink, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagItemIsSymlink) & flags > 0 {
            let d = String(kFSEventStreamEventFlagItemIsSymlink, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagItemIsSymlink, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagItemRemoved) & flags > 0 {
            let d = String(kFSEventStreamEventFlagItemRemoved, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagItemRemoved, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagItemRenamed) & flags > 0 {
            let d = String(kFSEventStreamEventFlagItemRenamed, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagItemRenamed, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagItemXattrMod) & flags > 0 {
            let d = String(kFSEventStreamEventFlagItemXattrMod, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagItemXattrMod, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagItemModified) & flags > 0 {
            let d = String(kFSEventStreamEventFlagItemModified, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagItemModified, \(d)")
        }
        if UInt32(kFSEventStreamEventFlagOwnEvent) & flags > 0 {
            let d = String(kFSEventStreamEventFlagOwnEvent, radix: 2, uppercase: false)
            stringArray.append("kFSEventStreamEventFlagOwnEvent, \(d)")
        }
        return stringArray
    }
    
    func handleEvent(path: String, flags: FSEventStreamEventFlags, id: UInt64) {
        guard !URL(fileURLWithPath: path).lastPathComponent.hasPrefix(".") else {print("ignoring invisible file"); return}
        guard !(flags & FSEventStreamEventFlags(kFSEventStreamEventFlagOwnEvent) > 0) else {print("ignoring own"); return}
        if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagRootChanged)) > 0 {
            print("root changed")
            //relocate directory
            
            let fileDescriptor = activeMonitoringFileDescriptors[path]!
            var newPath = [UInt8](repeating: 0, count: Int(PATH_MAX))
            fcntl(fileDescriptor, F_GETPATH, &newPath)
            let newPathString = String(cString: newPath)
            
            //change the library's library_location, update the activeMonitoringURLs and libraryURLDictionary, close all open file descriptors, then re-initialize the stream
            
            let oldURL = URL(fileURLWithPath: path)
            let newURL = URL(fileURLWithPath: newPathString)
            globalRootLibrary?.someRootChanged(newURL: newURL, oldURL: oldURL)
            
            
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
            
        }
        if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated)) > 0 {
            if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified)) > 0 {
                print("item created, modified")
                if VALID_FILE_TYPES.contains(URL(fileURLWithPath: path).pathExtension) && fileManager.fileExists(atPath: path) {
                    self.urlsToAddToDatabase.append(URL(fileURLWithPath: path))
                }
            } else {
                print("item created, not modified")
                if VALID_FILE_TYPES.contains(URL(fileURLWithPath: path).pathExtension) && fileManager.fileExists(atPath: path) {
                    self.urlsToAddToDatabase.append(URL(fileURLWithPath: path))
                }
            }
        }
        if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified)) > 0 {
            if self.pendingCreatePaths.contains(path) {
                print("item created after pending")
                if VALID_FILE_TYPES.contains(URL(fileURLWithPath: path).pathExtension) {
                    self.urlsToAddToDatabase.append(URL(fileURLWithPath: path))
                }
                self.pendingCreatePaths.remove(at: self.pendingCreatePaths.firstIndex(of: path)!)
            }
        }
        if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed)) > 0 {
            print("item renamed")
            let rootDirectoryPaths = activeMonitoringFileDescriptors.map({return $0.key}).filter({return path.lowercased().hasPrefix($0.lowercased())})
            let rootDirectoryPath = rootDirectoryPaths.max(by: {$1.count < $0.count})!
            if let firstEvent = firstHalfRenameEvents[id - 1] {
                //this is definitely the second half of another rename event, which we may or may not care about
                if firstEvent.tracks != nil && globalRootLibrary!.keeps_track_of_files == true {
                    let newURLPathAbsoluteString = URL(fileURLWithPath: path).absoluteString
                    for track in firstEvent.tracks! {
                        track.location = track.location?.replacingOccurrences(of: firstEvent.initialPathAbsoluteURLString, with: newURLPathAbsoluteString, options: .anchored, range: nil)
                    }
                }
                firstHalfRenameEvents[id - 1] = nil
            } else {
                //either this location is valid and a new file or directory was added...
                var isDirectory = ObjCBool(booleanLiteral: false)
                if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) && path != rootDirectoryPath {
                    if globalRootLibrary?.monitors_directories_for_new as? Bool == true {
                        if isDirectory.boolValue == true {
                            DispatchQueue.global(qos: .default).async {
                                print("going and getting urls")
                                let urls = self.databaseManager.getMediaURLsInDirectoryURLs([URL(fileURLWithPath: path)]).0
                                self.urlsToAddToDatabase.append(contentsOf: urls)
                                print("about to add urls to database")
                                self.tryAddNewFilesToDatabase()
                            }
                        } else {
                            if VALID_FILE_TYPES.contains(URL(fileURLWithPath: path).pathExtension) {
                                backgroundContext.perform {
                                    self.databaseManager.addTracksFromURLs([URL(fileURLWithPath: path)], to: globalRootLibrary!, context: backgroundContext, visualUpdateHandler: nil, callback: nil)
                                    //ignores errors :(
                                }
                            }
                        }
                        //metadata should already exist.
                    }
                } else {
                    //...or this is the first half of a rename event, which we may or may not care about
                    if let tracks = {() -> [Track]? in
                        let fr = NSFetchRequest<Track>(entityName: "Track")
                        fr.predicate = NSPredicate(format: "location beginswith[c] %@", URL(fileURLWithPath: path).absoluteString)
                        do {
                            let tracks = try managedContext.fetch(fr)
                            return tracks
                        } catch {
                            print(error)
                        }
                        return nil
                        }() {
                        let newFirstHalfEvent = TrackFirstRenameEvent(path: path, flags: flags, tracks: tracks)
                        firstHalfRenameEvents[id] = newFirstHalfEvent
                    }
                }
            }
        }
    }
    
    func reinitializeEventStream() {
        if eventStreamRef != nil {
            closeEventStream(eventStream: self.eventStreamRef!)
        }
        initializeEventStream()
    }
    
    func updateLastEventID() {
        notEnablingUndo {
            globalRootLibrary?.last_fs_event = FSEventStreamGetLatestEventId(self.eventStreamRef!) as NSNumber?
            do {
                try managedContext.save()
            } catch {
                print(error)
            }
        }
    }
    
    func initializeEventStream() {
        var lastEventID = globalRootLibrary!.last_fs_event as? FSEventStreamEventId
        if lastEventID == 0 {
            lastEventID = FSEventStreamEventId(kFSEventStreamEventIdSinceNow)
        }
        var urls = [URL]()
        if globalRootLibrary!.monitors_directories_for_new == true || globalRootLibrary!.keeps_track_of_files == true {
            let url = globalRootLibrary!.getCentralMediaFolder()!
            urls.append(url)
            if let watchURLs = globalRootLibrary!.watch_dirs as? [URL] {
                urls.append(contentsOf: watchURLs)
            }
        }
        self.activeMonitoringURLs = Set(urls)
        let urlPaths = urls.map({return $0.path})
        createEventStream(paths: urlPaths, lastID: lastEventID)
    }
    
    func createEventStream(paths: [String], lastID: FSEventStreamEventId?) {
        let flag = kFSEventStreamCreateFlagMarkSelf | kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagWatchRoot
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
