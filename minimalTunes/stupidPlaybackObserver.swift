//
//  stupidPlaybackObserver.swift
//  minimalTunes
//
//  Created by John Moody on 6/17/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class stupidPlaybackObserver: NSObject {
    private var kvocontext = 0
    
    private let queue: AudioModule
    
    init(the_queue: AudioModule) {
        self.queue = the_queue
        super.init()
        queue.addObserver(self, forKeyPath: "is_initialized", options: .New, context: &kvocontext)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &kvocontext {
            return
        }
    }
}
