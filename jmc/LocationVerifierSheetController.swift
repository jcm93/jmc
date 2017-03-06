//
//  LocationVerifierSheetController.swift
//  jmc
//
//  Created by John Moody on 3/5/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class LocationVerifierSheetController: NSWindowController {

    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var verifyStatusText: NSTextField!
    var count: Int?
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    @IBAction func cancelPressed(_ sender: Any) {
        
    }
    
    func visualUpdateHandlerCallback(numTracksChecked: Int) {
        self.verifyStatusText.stringValue = "Verifying \(numTracksChecked) of \(self.count!) tracks..."
        self.progressBar.doubleValue = Double(numTracksChecked)
    }
    
    func initialize(count: Int) {
        self.count = count
        self.verifyStatusText.stringValue = "Verifying 0 of \(count) tracks..."
        self.progressBar.maxValue = Double(count)
        self.progressBar.minValue = 0
    }
    
    func completionHandler() {
        self.window?.close()
    }
    
}
