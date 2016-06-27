//
//  dragAndDropView.swift
//  minimalTunes
//
//  Created by John Moody on 6/22/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class dragAndDropView: NSView {
    
    
    var progressBar: NSProgressIndicator?
    var dragOrigin: CGFloat?
    var mainWindowController: MainWindowController?

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        // Drawing code here.
    }
    
    override func mouseDown(theEvent: NSEvent) {
        self.mainWindowController?.timer?.invalidate()
        let frac = Double((theEvent.locationInWindow.x - self.convertRect(self.visibleRect, toView: nil).origin.x) / self.frame.width)
        progressBar?.doubleValue = frac * 100
        mainWindowController!.seek(frac)
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        let frac = Double((theEvent.locationInWindow.x - self.convertRect(self.visibleRect, toView: nil).origin.x) / self.frame.width)
        progressBar?.doubleValue = frac * 100
        mainWindowController!.seek(frac)
        if (mainWindowController?.timer == nil || mainWindowController?.timer?.valid == false) {
            self.mainWindowController?.startTimer()
        }
    }
    
    override func mouseUp(theEvent: NSEvent) {
        //let frac = Double((theEvent.locationInWindow.x - self.convertRect(self.visibleRect, toView: nil).origin.x) / self.frame.width)
        //progressBar?.doubleValue = frac * 100
        //mainWindowController!.seek(frac)
        if (mainWindowController?.timer == nil || mainWindowController?.timer?.valid == false) {
            self.mainWindowController?.startTimer()
        }
    }

    
}