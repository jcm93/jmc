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
        self.registerForDraggedTypes([NSPasteboardTypePNG, NSPasteboardTypeTIFF, NSFilenamesPboardType])
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        Swift.print("called dragging entered")
        if mainWindowController?.currentTrack != nil {
            Swift.print("not nil")
            return NSDragOperation.Every
        } else {
            Swift.print("nil")
            return NSDragOperation.None
        }
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        //do the album art stuff
        if let board = sender.draggingPasteboard().propertyListForType("NSFilenamesPboardType") as? NSArray,
            imagePath = board[0] as? String {
            let fileManager = NSFileManager.defaultManager()
            let artURL = NSURL(fileURLWithPath: imagePath)
            let artImage = NSImage(contentsOfURL: artURL)
            if artImage != nil {
                if mainWindowController?.currentTrack != nil {
                    let track = mainWindowController?.currentTrack
                    let location = NSURL(string: track!.location!)
                    let albumDirectory = location?.URLByDeletingLastPathComponent
                    let fileName = artURL.lastPathComponent
                    let newURL = albumDirectory?.URLByAppendingPathComponent(fileName!)
                    do {
                        try fileManager.copyItemAtURL(artURL, toURL: newURL!)
                    }catch {
                        Swift.print("error writing file: \(error)")
                        return false
                    }
                    let newArt = NSEntityDescription.insertNewObjectForEntityForName("AlbumArtwork", inManagedObjectContext: managedContext) as! AlbumArtwork
                    newArt.image_hash = artImage!.TIFFRepresentation?.hashValue
                    newArt.artwork_location = newURL?.absoluteString
                    if track!.album!.primary_art == nil {
                        newArt.primary_album = track!.album!
                    }
                    else if track!.album!.other_art == nil {
                        let oldPrimaryArt = track!.album!.primary_art
                        let newCollection = NSEntityDescription.insertNewObjectForEntityForName("AlbumArtworkCollection", inManagedObjectContext: managedContext) as! AlbumArtworkCollection
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
