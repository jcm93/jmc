//
//  NewSourceSheetController.swift
//  jmc
//
//  Created by John Moody on 2/22/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class NewSourceSheetController: NSWindowController {
    
    let databaseManager = DatabaseManager()

    @IBOutlet weak var addSourceButton: NSButton!
    @IBOutlet weak var newSourcePathControl: NSPathControl!
    @IBOutlet weak var sourceAddProgressBar: NSProgressIndicator!
    @IBOutlet weak var sourceAddStatusText: NSTextField!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var organizeRadio: NSButton!
    @IBOutlet weak var importAsIsRadio: NSButton!
    
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
            databaseManager.addNewSource(url: newSourcePathControl.url!, organize: organize)
        }
        self.window?.close()
        (NSApplication.shared().delegate as! AppDelegate).mainWindowController?.sourceListViewController?.createTree()
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
