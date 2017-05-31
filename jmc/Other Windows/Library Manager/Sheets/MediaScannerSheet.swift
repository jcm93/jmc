//
//  MediaScannerSheet.swift
//  jmc
//
//  Created by John Moody on 3/5/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class MediaScannerSheet: NSWindowController {

    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var statusTextField: NSTextField!
    @IBOutlet weak var cancelButton: NSButton!
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    func initializeForSetCreation() {
        progressBar.isIndeterminate = true
        progressBar.usesThreadedAnimation = true
        statusTextField.stringValue = "Indexing current track locations..."
        progressBar.startAnimation(nil)
    }
    
    func initializeForDirectoryParsing() {
        statusTextField.stringValue = "Getting all media in directory..."
    }
    
    func initializeForFiltering(count: Int) {
        progressBar.isIndeterminate = false
        statusTextField.stringValue = "Checking file 0 of \(count)..."
        progressBar.maxValue = Double(count)
        progressBar.minValue = 0
        progressBar.doubleValue = Double(0)
    }
    
    func filteringCallback(numFilesChecked: Int) {
        progressBar.doubleValue = Double(numFilesChecked)
    }
    
    func doneFiltering() {
        self.window?.close()
    }

}
