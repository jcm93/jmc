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
    var pendingCreatePaths = [String]()
    var urlsToAddToDatabase = [Library : [URL]]()
    var unpopulatedMetadataURLs = [Library: [URL]]()
    var currentlyAddingFiles = false
    var delegate: AppDelegate
    
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
            self.urlsToAddToDatabase = [Library : [URL]]()
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
            
        }
        if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated)) > 0 {
            if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified)) > 0 {
                print("item created, modified")
                let rootDirectoryPaths = activeMonitoringFileDescriptors.map({return $0.key}).filter({return path.lowercased().hasPrefix($0.lowercased())})
                let rootDirectoryPath = rootDirectoryPaths.max(by: {$1.characters.count < $0.characters.count})
                let library = self.libraryURLDictionary[URL(fileURLWithPath: rootDirectoryPath!)]!
                if VALID_FILE_TYPES.contains(URL(fileURLWithPath: path).pathExtension) && fileManager.fileExists(atPath: path) {
                    if self.urlsToAddToDatabase[library] == nil {
                        self.urlsToAddToDatabase[library] = [URL]()
                    }
                    self.urlsToAddToDatabase[library]!.append(URL(fileURLWithPath: path))
                }
            } else {
                print("item created, not modified")
                let rootDirectoryPaths = activeMonitoringFileDescriptors.map({return $0.key}).filter({return path.lowercased().hasPrefix($0.lowercased())})
                let rootDirectoryPath = rootDirectoryPaths.max(by: {$1.characters.count < $0.characters.count})!
                let library = self.libraryURLDictionary[URL(fileURLWithPath: rootDirectoryPath)]!
                if VALID_FILE_TYPES.contains(URL(fileURLWithPath: path).pathExtension) && fileManager.fileExists(atPath: path) {
                    if self.urlsToAddToDatabase[library] == nil {
                        self.urlsToAddToDatabase[library] = [URL]()
                    }
                    self.urlsToAddToDatabase[library]!.append(URL(fileURLWithPath: path))
                }
            }
        }
        if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified)) > 0 {
            if self.pendingCreatePaths.contains(path) {
                print("item created after pending")
                let rootDirectoryPaths = activeMonitoringFileDescriptors.map({return $0.key}).filter({return path.lowercased().hasPrefix($0.lowercased())})
                let rootDirectoryPath = rootDirectoryPaths.max(by: {$1.characters.count < $0.characters.count})!
                let library = self.libraryURLDictionary[URL(fileURLWithPath: rootDirectoryPath)]!
                if VALID_FILE_TYPES.contains(URL(fileURLWithPath: path).pathExtension) {
                    if self.urlsToAddToDatabase[library] == nil {
                        self.urlsToAddToDatabase[library] = [URL]()
                    }
                    self.urlsToAddToDatabase[library]!.append(URL(fileURLWithPath: path))
                }
                self.pendingCreatePaths.remove(at: self.pendingCreatePaths.index(of: path)!)
            }
        }
        if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed)) > 0 {
            print("item renamed")
            let rootDirectoryPaths = activeMonitoringFileDescriptors.map({return $0.key}).filter({return path.lowercased().hasPrefix($0.lowercased())})
            let rootDirectoryPath = rootDirectoryPaths.max(by: {$1.characters.count < $0.characters.count})!
            if withinDirRenameEvents[rootDirectoryPath]??.id == id - 1 {
                //this is definitely the second half of another rename event, which we may or may not care about
                let firstEvent = withinDirRenameEvents[rootDirectoryPath]!
                if firstEvent!.track != nil && firstEvent!.track!.library!.keeps_track_of_files == true {
                    firstEvent!.track!.location = URL(fileURLWithPath: path).absoluteString
                    do {
                        try managedContext.save()
                    } catch {
                        print(error)
                    }
                }
                withinDirRenameEvents[rootDirectoryPath] = nil
            } else {
                //either this location is valid and a new file was added, or...
                var isDirectory = ObjCBool(booleanLiteral: false)
                if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) && path != rootDirectoryPath {
                    let library = self.libraryURLDictionary[URL(fileURLWithPath: rootDirectoryPath)]!
                    if library.monitors_directories_for_new as? Bool == true {
                        if isDirectory.boolValue == true {
                            DispatchQueue.global(qos: .default).async {
                                print("going and getting urls")
                                let urls = self.databaseManager.getMediaURLsInDirectoryURLs([URL(fileURLWithPath: path)]).0
                                if self.urlsToAddToDatabase[library] == nil {
                                    self.urlsToAddToDatabase[library] = [URL]()
                                }
                                self.urlsToAddToDatabase[library]!.append(contentsOf: urls)
                                print("about to add urls to database")
                                self.tryAddNewFilesToDatabase()
                            }
                        } else {
                            if VALID_FILE_TYPES.contains(URL(fileURLWithPath: path).pathExtension) {
                                let errors = databaseManager.addTracksFromURLs([URL(fileURLWithPath: path)], to: library, visualUpdateHandler: nil, callback: nil) //ignores errors :(
                            }
                        }
                        //metadata should already exist.
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
        notEnablingUndo {
            globalRootLibrary?.last_fs_event = FSEventStreamGetLatestEventId(self.eventStreamRef!) as NSNumber?
        }
    }
    
    func initializeEventStream(libraries: [Library]) {
        var lastEventID = globalRootLibrary!.last_fs_event as? FSEventStreamEventId
        if lastEventID == 0 {
            lastEventID = FSEventStreamEventId(kFSEventStreamEventIdSinceNow)
        }
        var urls = [URL]()
        for libraryInList in libraries {
            if libraryInList.monitors_directories_for_new == true || libraryInList.keeps_track_of_files == true {
                let url = URL(string: libraryInList.central_media_folder_url_string!)!
                urls.append(url)
                libraryURLDictionary[url] = libraryInList
                if let watchURLs = libraryInList.watch_dirs as? [URL] {
                    urls.append(contentsOf: watchURLs)
                    for url in watchURLs {
                        self.libraryURLDictionary[url] = libraryInList
                    }
                }
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
