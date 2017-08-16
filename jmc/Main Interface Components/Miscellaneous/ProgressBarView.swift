//
//  dragAndDropView.swift
//  minimalTunes
//
//  Created by John Moody on 6/22/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class ProgressBarView: NSView {
    
    var progressBar: NSProgressIndicator?
    var dragOrigin: CGFloat?
    var mainWindowController: MainWindowController?
    var blockingSeekEvents = false
    
    override var mouseDownCanMoveWindow: Bool { get {
        return false
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        self.blockingSeekEvents = false
        Swift.print("sensed mouse down inside view")
        self.mainWindowController?.timer?.invalidate()
        let frac = Double((theEvent.locationInWindow.x - self.convert(self.visibleRect, to: nil).origin.x) / self.frame.width)
        progressBar?.doubleValue = frac * 100
        //progressBar?.displayIfNeeded()
        mainWindowController!.seek(frac)
    }
    
    override func mouseDragged(with theEvent: NSEvent) {
        guard self.blockingSeekEvents != true else {Swift.print("blocking seek events");return}
        let frac = Double((theEvent.locationInWindow.x - self.convert(self.visibleRect, to: nil).origin.x) / self.frame.width)
        progressBar?.doubleValue = frac * 100
        //progressBar?.displayIfNeeded()
        mainWindowController!.seek(frac)
        if (mainWindowController?.timer == nil || mainWindowController?.timer?.isValid == false && mainWindowController!.paused != true) {
            Swift.print("strating timer from seek")
            self.mainWindowController?.startTimer()
        }
    }
    
    override func mouseUp(with theEvent: NSEvent) {
        //let frac = Double((theEvent.locationInWindow.x - self.convertRect(self.visibleRect, toView: nil).origin.x) / self.frame.width)
        //progressBar?.doubleValue = frac * 100
        //mainWindowController!.seek(frac)
        if (mainWindowController?.timer == nil || mainWindowController?.timer?.isValid == false && mainWindowController!.paused != true) {
            Swift.print("starting timer from seek")
            self.mainWindowController?.startTimer()
        }
        self.blockingSeekEvents = false
    }
    
    func blockSeekEvents() {
        self.blockingSeekEvents = true
    }

    
}
