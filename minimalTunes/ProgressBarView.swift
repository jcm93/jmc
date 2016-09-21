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

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        // Drawing code here.
    }
    
    override func mouseDown(theEvent: NSEvent) {
        Swift.print("sensed mouse down inside view")
        self.mainWindowController?.timer?.invalidate()
        let frac = Double((theEvent.locationInWindow.x - self.convertRect(self.visibleRect, toView: nil).origin.x) / self.frame.width)
        progressBar?.doubleValue = frac * 100
        mainWindowController!.seek(frac)
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        let frac = Double((theEvent.locationInWindow.x - self.convertRect(self.visibleRect, toView: nil).origin.x) / self.frame.width)
        progressBar?.doubleValue = frac * 100
        mainWindowController!.seek(frac)
        if (mainWindowController?.timer == nil || mainWindowController?.timer?.valid == false && mainWindowController!.paused != true) {
            Swift.print("strating timer from seek")
            self.mainWindowController?.startTimer()
        }
        self.mainWindowController?.updateValuesUnsafe()
    }
    
    override func mouseUp(theEvent: NSEvent) {
        //let frac = Double((theEvent.locationInWindow.x - self.convertRect(self.visibleRect, toView: nil).origin.x) / self.frame.width)
        //progressBar?.doubleValue = frac * 100
        //mainWindowController!.seek(frac)
        if (mainWindowController?.timer == nil || mainWindowController?.timer?.valid == false && mainWindowController!.paused != true) {
            Swift.print("starting timer from seek")
            self.mainWindowController?.startTimer()
        }
        self.mainWindowController?.updateValuesUnsafe()
    }

    
}