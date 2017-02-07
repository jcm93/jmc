//
//  stupidPlaybackObserver.swift
//  minimalTunes
//
//  Created by John Moody on 6/17/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class stupidPlaybackObserver: NSObject {
    fileprivate var kvocontext = 0
    
    fileprivate let queue: AudioModule
    
    init(the_queue: AudioModule) {
        self.queue = the_queue
        super.init()
        queue.addObserver(self, forKeyPath: "is_initialized", options: .new, context: &kvocontext)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &kvocontext {
            return
        }
    }
}
