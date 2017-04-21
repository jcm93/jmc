//
//  AddFilesQueueLoop.swift
//  jmc
//
//  Created by John Moody on 4/20/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class FileAddQueueChunk: NSObject {
    
    var library: Library
    var urls: [URL]
    
    init(library: Library, urls: [URL]) {
        self.library = library
        self.urls = urls
    }
}

class AddFilesQueueLoop: NSObject, ProgressBarController {
    
    var urlsToAddChunks = [FileAddQueueChunk]()
    var databaseManager = DatabaseManager()
    var showsProgressBar = true
    var canAddMoreFiles = true
    var delegate: AppDelegate
    var timer: Timer?
    var isRunning = false
    var consecutiveEmptyLoops = 0
    
    init(delegate: AppDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    var actionName = ""
    var thingName = ""
    var thingCount = 0
    var thingsDone = 0
    
    func prepareForNewTask(actionName: String, thingName: String, thingCount: Int) {
        
    }
    
    func increment(thingsDone: Int) {
        self.thingsDone += 1
        delegate.backgroundAddFilesHandler?.increment(thingsDone: self.thingsDone)
    }
    
    func makeIndeterminate(actionName: String) {
        
    }
    
    func finish() {
        
    }
    
    func start() {
        print("queue here, starting")
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.loopAction), userInfo: nil, repeats: true)
            CFRunLoopAddTimer(CFRunLoopGetMain(), self.timer!, CFRunLoopMode.commonModes)
        }
    }
    
    func getURLsToAdd() -> FileAddQueueChunk {
        let baseChunk = urlsToAddChunks.removeFirst()
        //get all other urls for this library in the chunk queue, remove their chunks and harvest their urls
        var indexesToDelete = [Int]()
        for (index, otherChunk) in urlsToAddChunks.enumerated() {
            if otherChunk.library == baseChunk.library {
                baseChunk.urls.append(contentsOf: otherChunk.urls)
                indexesToDelete.append(index)
            }
        }
        for index in indexesToDelete.sorted().reversed() {
            urlsToAddChunks.remove(at: index)
        }
        return baseChunk
    }
    
    @objc func loopAction(timer: Timer) {
        if self.showsProgressBar == true && self.canAddMoreFiles == true && self.urlsToAddChunks.count > 0 {
            self.delegate.launchAddFilesDialog()
            self.delegate.backgroundAddFilesHandler?.prepareForNewTask(actionName: "Importing", thingName: "tracks", thingCount: self.thingCount)
            self.delegate.backgroundAddFilesHandler?.increment(thingsDone: self.thingsDone)
            self.isRunning = true
        }
        DispatchQueue.global(qos: .default).async {
            if self.urlsToAddChunks.count > 0 && self.canAddMoreFiles == true {
                self.canAddMoreFiles = false
                self.consecutiveEmptyLoops = 0
                //do some chunk optimization
                let chunk = self.getURLsToAdd()
                //get errors that indicate we can retry on the current thread, do the rest of the work on the main thread
                let errors = self.databaseManager.addTracksFromURLs(chunk.urls, to: chunk.library, visualUpdateHandler: self, callback: self.finishedAddingChunkCallback)
                let retryableErrors = errors.filter({return $0.error == kFileAddErrorMetadataNotYetPopulated})
                let retryableURLs = retryableErrors.map({return URL(string: $0.urlString)!})
                if retryableURLs.count > 0 {
                    let newChunk = FileAddQueueChunk(library: chunk.library, urls: retryableURLs)
                    self.urlsToAddChunks.append(newChunk)
                }
                //has the potential to retry forever, if a file's size metadata is never available.
            } else if self.canAddMoreFiles == true {
                //no urls to add.
                self.consecutiveEmptyLoops += 1
                if self.consecutiveEmptyLoops >= 5 {
                    self.stop()
                }
            }
        }
    }
    
    
    func addChunksToQueue(urls: [Library : [URL]]) {
        for library in urls.keys {
            let newChunk = FileAddQueueChunk(library: library, urls: urls[library]!)
            self.urlsToAddChunks.append(newChunk)
            self.thingCount += newChunk.urls.count
            self.delegate.backgroundAddFilesHandler?.prepareForNewTask(actionName: "Importing", thingName: "tracks", thingCount: self.thingCount)
            self.delegate.backgroundAddFilesHandler?.increment(thingsDone: self.thingsDone)
        }
    }
    
    func finishedAddingChunkCallback() {
        self.canAddMoreFiles = true
    }
    
    func stop() {
        print("stop called")
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.isRunning = false
            self.delegate.backgroundAddFilesHandler?.finish()
        }
    }
}
