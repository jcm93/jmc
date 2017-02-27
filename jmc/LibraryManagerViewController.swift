//
//  LibraryManagerViewController.swift
//  jmc
//
//  Created by John Moody on 2/13/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class TrackNotFound: NSObject {
    let url: URL
    let track: Track
    init(url: URL, track: Track) {
        self.url = url
        self.track = track
    }
}

class LibraryManagerViewController: NSWindowController {
    
    //sheets
    var addSourceSheet: NewSourceSheetController?

    //data controllers
    @IBOutlet var libraryArrayController: NSArrayController!
    @IBOutlet var tracksNotFoundArrayController: NSArrayController!
    @IBOutlet var newTracksArrayController: NSArrayController!
    
    //source information elements
    @IBOutlet weak var sourceTitleLabel: NSTextField!
    @IBOutlet weak var sourceNameField: NSTextField!
    @IBOutlet weak var sourceLocationStatusImage: NSImageView!
    @IBOutlet weak var sourceLocationStatusTextField: NSTextField!
    @IBOutlet weak var sourceMonitorStatusImageView: NSImageView!
    @IBOutlet weak var sourceMonitorStatusTextField: NSTextField!
    @IBOutlet weak var sourceLocationField: NSTextField!
    
    @IBAction func addSourceButtonPressed(_ sender: Any) {
        self.addSourceSheet = NewSourceSheetController(windowNibName: "NewSourceSheetController")
        self.window?.beginSheet(self.addSourceSheet!.window!, completionHandler: addSourceModalComplete)
    }
    
    func addSourceModalComplete(response: NSModalResponse) {
        
    }
    
    @IBAction func removeSourceButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func changeSourceLocationButtonPressed(_ sender: Any) {
        
    }
    //location manager
    @IBOutlet weak var verifyLocationsButton: NSButton!
    @IBOutlet weak var libraryLocationStatusImageView: NSImageView!
    
    @IBAction func verifyLocationsButtonPressed(_ sender: Any) {
        
    }
    @IBAction func locateTrackButtonPressed(_ sender: Any) {
        
    }
    
    //dir scanner
    @IBAction func scanSourceButtonPressed(_ sender: Any) {
        
    }
    
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
