//
//  DragAndDropImageView.swift
//  minimalTunes
//
//  Created by John Moody on 7/19/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class DragAndDropImageView: NSImageView {
    
    var mainWindowController: MainWindowController?
    
    override func awakeFromNib() {
        self.register(forDraggedTypes: [NSPasteboardTypePNG, NSPasteboardTypeTIFF, NSFilenamesPboardType])
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        Swift.print("called dragging entered")
        if mainWindowController?.currentTrack != nil {
            Swift.print("not nil")
            return NSDragOperation.every
        } else {
            Swift.print("nil")
            return NSDragOperation()
        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        //do the album art stuff
        if let board = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
            let urls = board.map({return URL(fileURLWithPath: $0 as! String)})
            if mainWindowController?.currentTrack != nil {
                let databaseManager = DatabaseManager()
                var results = [Bool]()
                for url in urls {
                    results.append(databaseManager.addArtForTrack(mainWindowController!.currentTrack!, from: url, managedContext: managedContext))
                }
                if results.contains(true) {
                    mainWindowController?.initAlbumArtwork()
                }
            }
            else {
                return false
            }
        }
        return false
    }

}
