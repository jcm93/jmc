//
//  AddFilesQueueLoop.swift
//  jmc
//
//  Created by John Moody on 4/20/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class FileAddQueueChunk {
    
    var library: Library
    var urls: [URL]
    
    init(library: Library, urls: [URL]) {
        self.library = library
        self.urls = urls
    }
}

class AddFilesQueueLoop: NSObject {
    
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
    
    func start() {
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(loopAction), userInfo: nil, repeats: true)
        RunLoop.current.add(self.timer!, forMode: RunLoopMode.commonModes)
        self.isRunning = true
    }
    
    func loopAction() {
        if urlsToAddChunks.count > 0 && self.canAddMoreFiles == true {
            self.canAddMoreFiles = false
            let chunk = urlsToAddChunks.removeFirst()
            if self.showsProgressBar == true {
                delegate.launchAddFilesDialog()
            }
            let errors = databaseManager.addTracksFromURLs(chunk.urls, to: chunk.library, visualUpdateHandler: delegate.backgroundAddFilesHandler, callback: self.finishedAddingChunkCallback)
            let retryableErrors = errors.filter({return $0.error == kFileAddErrorNoSizeMetadata})
            let retryableURLs = retryableErrors.map({return URL(string: $0.urlString)!})
            let newChunk = FileAddQueueChunk(library: chunk.library, urls: retryableURLs)
            self.urlsToAddChunks.append(newChunk)
        } else if self.canAddMoreFiles == true {
            //no urls to add.
            self.consecutiveEmptyLoops += 1
            if self.consecutiveEmptyLoops >= 30 {
                self.stop()
            }
        }
    }
    
    func addChunksToQueue(urls: [Library : [URL]]) {
        for library in urls.keys {
            let newChunk = FileAddQueueChunk(library: library, urls: urls[library]!)
            self.urlsToAddChunks.append(newChunk)
        }
    }
    
    func finishedAddingChunkCallback() {
        self.canAddMoreFiles = true
    }
    
    func stop() {
        self.timer?.invalidate()
        self.isRunning = false
    }
}
