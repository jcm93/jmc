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
        if let board = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray,
            let imagePath = board[0] as? String {
            let fileManager = FileManager.default
            let artURL = URL(fileURLWithPath: imagePath)
            let artImage = NSImage(contentsOf: artURL)
            if artImage != nil {
                if mainWindowController?.currentTrack != nil {
                    let track = mainWindowController?.currentTrack
                    let location = URL(string: track!.location!)
                    let albumDirectory = location?.deletingLastPathComponent()
                    let fileName = artURL.lastPathComponent
                    let newURL = albumDirectory?.appendingPathComponent(fileName)
                    do {
                        try fileManager.copyItem(at: artURL, to: newURL!)
                    }catch {
                        Swift.print("error writing file: \(error)")
                        return false
                    }
                    let newArt = NSEntityDescription.insertNewObject(forEntityName: "AlbumArtwork", into: managedContext) as! AlbumArtwork
                    newArt.image_hash = artImage!.tiffRepresentation?.hashValue as NSNumber?
                    newArt.artwork_location = newURL?.absoluteString
                    if track!.album!.primary_art == nil {
                        newArt.primary_album = track!.album!
                    }
                    else if track!.album!.other_art == nil {
                        let oldPrimaryArt = track!.album!.primary_art
                        let newCollection = NSEntityDescription.insertNewObject(forEntityName: "AlbumArtworkCollection", into: managedContext) as! AlbumArtworkCollection
                        newCollection.album = track!.album!
                        oldPrimaryArt!.collection = newCollection
                        oldPrimaryArt?.primary_album = nil
                        newArt.primary_album = track!.album!
                    }
                    else {
                        let collection = track!.album!.other_art!
                        newArt.collection = collection
                    }
                    self.image = artImage
                    return true
                }
                else {
                    return false
                }
            }
        }
        return false
    }

}
