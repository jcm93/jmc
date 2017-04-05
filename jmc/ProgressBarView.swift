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

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        Swift.print("sensed mouse down inside view")
        self.mainWindowController?.timer?.invalidate()
        let frac = Double((theEvent.locationInWindow.x - self.convert(self.visibleRect, to: nil).origin.x) / self.frame.width)
        progressBar?.doubleValue = frac * 100
        progressBar?.displayIfNeeded()
        mainWindowController!.seek(frac)
    }
    
    override func mouseDragged(with theEvent: NSEvent) {
        let frac = Double((theEvent.locationInWindow.x - self.convert(self.visibleRect, to: nil).origin.x) / self.frame.width)
        progressBar?.doubleValue = frac * 100
        progressBar?.displayIfNeeded()
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
    }

    
}
