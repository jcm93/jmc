//
//  NewSourceSheetController.swift
//  jmc
//
//  Created by John Moody on 2/22/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class NewSourceSheetController: NSWindowController, ProgressBarController {
    
    let databaseManager = DatabaseManager()

    @IBOutlet weak var addSourceButton: NSButton!
    @IBOutlet weak var newSourcePathControl: NSPathControl!
    @IBOutlet weak var sourceAddProgressBar: NSProgressIndicator!
    @IBOutlet weak var sourceAddStatusText: NSTextField!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var organizeRadio: NSButton!
    @IBOutlet weak var importAsIsRadio: NSButton!
    var actionName: String = ""
    var thingName: String = ""
    var thingCount: Int = 0
    
    
    @IBAction func browseButtonPressed(_ sender: Any) {
        let fileDialog = NSOpenPanel()
        fileDialog.canChooseFiles = false
        fileDialog.canChooseDirectories = true
        fileDialog.allowsMultipleSelection = false
        let modalResult = fileDialog.runModal()
        if modalResult == NSFileHandlingPanelOKButton {
            let url = fileDialog.urls[0]
            newSourcePathControl.url = url
            addSourceButton.isEnabled = true
        }
    }
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.window?.close()
    }
    
    @IBAction func newRadioAction(_ sender: Any) {

    }
    
    @IBAction func addSourceButtonPressed(_ sender: Any) {
        sourceAddProgressBar.usesThreadedAnimation = true
        sourceAddProgressBar.startAnimation(nil)
        sourceAddStatusText.isHidden = false
        sourceAddStatusText.stringValue = "Importing media..."
        sourceAddProgressBar.isHidden = false
        cancelButton.isEnabled = false
        let organize = importAsIsRadio.state == NSOnState ? false : true
        if newSourcePathControl.url != nil {
            databaseManager.addNewSource(url: newSourcePathControl.url!, organize: organize, visualUpdateHandler: self)
        }
    }
    
    func prepareForNewTask(actionName: String, thingName: String, thingCount: Int) {
        self.sourceAddProgressBar.isIndeterminate = false
        self.actionName = actionName
        self.thingName = thingName
        self.thingCount = thingCount
        self.sourceAddProgressBar.maxValue = Double(thingCount)
        self.sourceAddProgressBar.doubleValue = 0
        self.sourceAddStatusText.stringValue = "\(self.actionName) 0 of \(self.thingCount) \(self.thingName)..."
    }
    
    func increment(thingsDone: Int) {
        self.sourceAddProgressBar.doubleValue = Double(thingsDone)
        self.sourceAddStatusText.stringValue = "\(self.actionName) \(thingsDone) of \(self.thingCount) \(self.thingName)..."
    }
    
    func makeIndeterminate(actionName: String) {
        self.sourceAddStatusText.stringValue = "\(actionName)..."
        self.sourceAddProgressBar.isIndeterminate = true
        self.sourceAddProgressBar.startAnimation(nil)
    }
    
    func finish() {
        (NSApplication.shared().delegate as! AppDelegate).mainWindowController?.sourceListViewController?.recreateTree()
        (NSApplication.shared().delegate as! AppDelegate).mainWindowController?.sourceListViewController?.reloadData()
        self.window?.close()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        newSourcePathControl.url = URL(fileURLWithPath: NSHomeDirectory())
        addSourceButton.isEnabled = false
        organizeRadio.action = #selector(newRadioAction)
        importAsIsRadio.action = #selector(newRadioAction)
        importAsIsRadio.state = NSOnState
        
        sourceAddProgressBar.isHidden = true
    }
    
}
