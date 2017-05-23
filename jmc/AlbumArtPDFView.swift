//
//  AlbumArtPDFView.swift
//  jmc
//
//  Created by John Moody on 5/21/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Quartz

class AlbumArtPDFView: PDFView {
    
    override var mouseDownCanMoveWindow: Bool {
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
