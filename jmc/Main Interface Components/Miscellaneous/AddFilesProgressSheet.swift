//
//  GenericProgressBarSheetController.swift
//  jmc
//
//  Created by John Moody on 4/19/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class GenericProgressBarSheetController: NSWindowController, ProgressBarController {
    
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var progressLabelTextField: NSTextField!
    
    var thingCount: Int = 0
    var thingName: String = ""
    var actionName: String = ""
    
    func prepareForNewTask(actionName: String, thingName: String, thingCount: Int) {
        self.actionName = actionName
        self.thingName = thingName
        self.thingCount = thingCount
        self.progressBar.isIndeterminate = false
        self.progressLabelTextField.stringValue = "\(actionName) 0 of \(thingCount) \(thingName)..."
        self.progressBar.maxValue = Double(thingCount)
    }
    
    func increment(thingsDone: Int) {
        self.progressBar.doubleValue = Double(thingsDone)
        self.progressLabelTextField.stringValue = "\(actionName) \(thingsDone) of \(thingCount) \(thingName)..."
    }
    
    func makeIndeterminate(actionName: String) {
        self.progressBar.isIndeterminate = true
        self.progressBar.startAnimation(nil)
        self.progressLabelTextField.stringValue = actionName
    }
    
    func finish() {
        self.window?.close()
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
