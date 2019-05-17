//
//  DragAndDropImageView.swift
//  minimalTunes
//
//  Created by John Moody on 7/19/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class DragAndDropImageView: NSImageView {
    
    var viewController: AlbumArtViewController?
    var mouseDownHappened = false
    
    override func awakeFromNib() {
        self.registerForDraggedTypes([NSPasteboard.PasteboardType.png, NSPasteboard.PasteboardType.tiff, NSPasteboard.PasteboardType(kUTTypeURL as String)])
        self.animates = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func mouseDown(with event: NSEvent) {
        self.mouseDownHappened = true
    }
    
    override func mouseUp(with event: NSEvent) {
        if self.mouseDownHappened {
            self.viewController!.loadAlbumArtWindow()
        }
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        Swift.print("called dragging entered")
        if viewController!.mainWindow!.currentTrack != nil {
            Swift.print("not nil")
            return NSDragOperation.every
        } else {
            Swift.print("nil")
            return NSDragOperation()
        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        //do the album art stuff
        if let board = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray {
            let urls = board.map({return URL(fileURLWithPath: $0 as! String)})
            if let currentTrack = viewController?.mainWindow?.currentTrack {
                let databaseManager = DatabaseManager()
                var results = [AnyObject]()
                for url in urls {
                    if let urlUTI = getUTIFrom(url: url) {
                        if UTTypeConformsTo(urlUTI as CFString, kUTTypeImage) || UTTypeConformsTo(urlUTI as CFString, kUTTypePDF) {
                            if let result = databaseManager.addArtForTrack(currentTrack, from: url, managedContext: managedContext, organizes: true) {
                                results.append(result)
                            }
                        } else {
                            if let result = databaseManager.addMiscellaneousFile(forTrack: currentTrack, from: url, managedContext: managedContext, organizes: true) {
                                results.append(result)
                            }
                        }
                    }
                }
                if results.count > 0 {
                    self.viewController?.initAlbumArt(currentTrack)
                }
            }
            else {
                return false
            }
        }
        return false
    }

}
