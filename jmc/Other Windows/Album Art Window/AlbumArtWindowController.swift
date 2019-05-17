//
//  AlbumArtWindowController.swift
//  jmc
//
//  Created by John Moody on 5/18/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class AlbumArtWindowController: NSWindowController {
    
    @IBOutlet weak var contentView: NSView!
    var albumFilesViewController: AlbumFilesViewController?
    var timer: Timer?
    var track: Track?
    
    override func mouseMoved(with event: NSEvent) {
        if self.timer != nil {
            self.timer?.invalidate()
        }
        self.window!.standardWindowButton(.closeButton)!.superview!.animator().alphaValue = 1
        self.timer = Timer.scheduledTimer(timeInterval: 0.9, target: self, selector: #selector(fadeOutTitleBar), userInfo: nil, repeats: false)
    }
    
    override func mouseExited(with event: NSEvent) {
        fadeOutTitleBar()
    }
    
    @objc func fadeOutTitleBar() {
        //self.window!.standardWindowButton(.closeButton)!.superview!.
        self.window!.standardWindowButton(.closeButton)!.superview!.animator().alphaValue = 0
    }
    
    func resize(newSize: NSSize) {
        let rect = NSRect(origin: self.window!.frame.origin, size: newSize)
        self.window?.animator().setFrame(rect, display: true)
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        let trackingArea = NSTrackingArea(rect: self.window!.frame, options: [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.inVisibleRect, NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.mouseMoved], owner: self, userInfo: nil)
        self.window?.contentView?.addTrackingArea(trackingArea)

        //self.window?.contentView?.translatesAutoresizingMaskIntoConstraints = false
        self.window?.isMovableByWindowBackground = true
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.albumFilesViewController = AlbumFilesViewController(nibName: "AlbumFilesViewController", bundle: nil)
        self.albumFilesViewController?.track = self.track
        self.albumFilesViewController?.windowController = self
        self.contentView.addSubview(self.albumFilesViewController!.view)
        self.albumFilesViewController?.view.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        self.albumFilesViewController?.view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        self.albumFilesViewController?.view.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        self.albumFilesViewController?.view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        self.window?.title = self.track!.album!.name!

    }
    
}
