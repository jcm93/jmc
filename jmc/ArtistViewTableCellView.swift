//
//  ArtistViewTableCellView.swift
//  jmc
//
//  Created by John Moody on 5/22/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class ArtistViewTableCellView: NSTableCellView {
    
    @IBOutlet var artistImageView: NSImageView!
    @IBOutlet var albumNameLabel: NSTextField!
    @IBOutlet var albumInfoLabel: NSTextField!
    @IBOutlet var tracksView: NSView!
    var tracksViewController: NSViewController?
    
    var album: Album?
    
    func populateTracksTable(_ album: Album) {
        self.album = album
        self.tracksViewController = ArtistViewTrackListViewController(nibName: "ArtistViewTrackListViewController", bundle: nil, album: self.album!)
        self.tracksView.addSubview(tracksViewController!.view)
        self.albumNameLabel.stringValue = self.album!.name!
        if self.album?.primary_art != nil {
            self.artistImageView.image = NSImage(byReferencing: URL(string: self.album!.primary_art!.artwork_location!)!)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
