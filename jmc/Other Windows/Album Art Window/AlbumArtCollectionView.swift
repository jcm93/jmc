//
//  AlbumArtCollectionView.swift
//  jmc
//
//  Created by John Moody on 5/21/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class AlbumArtCollectionView: NSCollectionView {
    
    var viewController: AlbumFilesViewController?
    
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == String(Character(UnicodeScalar(NSEvent.SpecialKey.delete.rawValue)!)) {
            viewController?.deleteSelection()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
}
