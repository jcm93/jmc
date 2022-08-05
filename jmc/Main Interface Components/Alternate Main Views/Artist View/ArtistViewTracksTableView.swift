//
//  ArtistViewTracksTableView.swift
//  jmc
//
//  Created by John Moody on 12/26/21.
//  Copyright © 2021 John Moody. All rights reserved.
//

import Cocoa

class ArtistViewTracksTableView: NSTableView {
    
    var artistViewController: ArtistViewController?
    var artistViewTableCellView: ArtistViewTableCellView?
    var trackQueueViewController: TrackQueueViewController?
    var windowIdentifier: String?
    var draggedRowIndexes: IndexSet?
    
    var shouldDrawFocusRing = false
    
    
    let types = ["Track"]


    override func draw(_ dirtyRect: NSRect) {
        if self.shouldDrawFocusRing {
            NSFocusRingPlacement.only.set()
            self.bounds.fill()
        }
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    
    override func awakeFromNib() {
        //self.registerForDraggedTypes(types)
    }
    
    override func rightMouseDown(with theEvent: NSEvent) {
        let globalLocation = theEvent.locationInWindow
        let localLocation = self.convert(globalLocation, from: nil)
        let clickedRow = self.row(at: localLocation)
        if clickedRow != -1 {
            artistViewTableCellView?.determineRightMouseDownTarget()
        } else {
            artistViewTableCellView?.rightMouseDownTarget = nil
        }
        super.rightMouseDown(with: theEvent)
    }
    
    override func keyDown(with theEvent: NSEvent) {
        Swift.print("\(theEvent.keyCode) was pressed")
        if theEvent.keyCode == 49 {
            artistViewTableCellView?.interpretSpacebarEvent()
        } else if theEvent.keyCode == 36 {
            artistViewTableCellView?.interpretEnterEvent()
        } else if theEvent.keyCode == 51 {
            artistViewTableCellView?.interpretDeleteEvent()
            trackQueueViewController?.interpretDeleteEvent()
        } else if theEvent.keyCode == 124 {
            print("skipping")
            self.artistViewTableCellView?.artistViewController.mainWindowController?.skip()
        }
        else if theEvent.keyCode == 123 {
            self.artistViewTableCellView?.artistViewController?.mainWindowController?.skipBackward()
        } else {
            super.keyDown(with: theEvent)
        }
    }
    
}
