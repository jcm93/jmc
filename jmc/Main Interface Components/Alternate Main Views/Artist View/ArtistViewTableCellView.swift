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
    var tracksViewController: ArtistViewTrackListViewController?
    
    var album: Album?
    
    func populateTracksTable(_ album: Album) {
        self.album = album
        self.tracksViewController = ArtistViewTrackListViewController(nibName: "ArtistViewTrackListViewController", bundle: nil, album: self.album!)
        self.tracksView.addSubview(tracksViewController!.view)
        Swift.print(self.tracksViewController!.trackArray.count)
        if let loc = album.primary_art?.location {
            if let url = URL(string: loc) {
                if let image = NSImage(contentsOf: url) {
                    self.artistImageView.image = image
                }
            }
        }
        let currentConstraint = self.tracksView.constraints.filter({return $0.firstAttribute == .height})
        NSLayoutConstraint.deactivate(currentConstraint)
        let constraint = NSLayoutConstraint(item: self.tracksView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(self.tracksViewController!.trackArray.count + 1) * self.tracksViewController!.tableView.rowHeight)
        NSLayoutConstraint.activate([constraint])
        self.albumNameLabel.stringValue = self.album!.name!
        self.artistImageView.wantsLayer = true
        self.artistImageView.layer?.cornerRadius = 10
        self.tracksViewController!.view.frame = self.tracksView.bounds
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
