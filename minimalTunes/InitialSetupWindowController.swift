//
//  InitialSetupWindowController.swift
//  minimalTunes
//
//  Created by John Moody on 7/11/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

public enum LibraryOrganizationType: Int {
    case move = 1
    case copy = 2
    case none = 0
}

class InitialSetupWindowController: NSWindowController {

    @IBOutlet weak var moveRadioButton: NSButton!
    @IBOutlet weak var copyRadioButton: NSButton!
    @IBOutlet weak var noOrganizeRadioButton: NSButton!
    @IBOutlet weak var modifyMetadataCheckBox: NSButton!
    @IBOutlet weak var libraryPathField: NSTextField!
    @IBOutlet weak var organizationDescField: NSTextField!
    
    var organizationType: LibraryOrganizationType = .none
    var modifyMetadata: Bool = false
    var directoryPath: String?
    var moveString = "Added media will be moved into a subdirectory of this directory"
    var copyString = "Added media will be copied into a subdirectory of this directory"
    var noString = "Added media will not be organized"
    
    @IBAction func moveRadioAction(sender: AnyObject) {
        if moveRadioButton.state == NSOnState {
            organizationType = .move
            organizationDescField.stringValue = moveString
        }
        else if copyRadioButton.state == NSOnState {
            organizationType = .copy
            organizationDescField.stringValue = copyString
        }
        else if noOrganizeRadioButton.state == NSOnState {
            organizationType = .none
            organizationDescField.stringValue = noString
        }
    }
    
    @IBAction func browseClicked(sender: AnyObject) {
        openFile()
    }
    @IBAction func modifyCheckBoxToggled(sender: AnyObject) {
        if modifyMetadataCheckBox.state == NSOnState {
            modifyMetadata = true
        }
        else {
            modifyMetadata = false
        }
    }
    
    func openFile() {
        
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        myFileDialog.canChooseFiles = false
        myFileDialog.canChooseDirectories = true
        myFileDialog.runModal()
        
        // Get the path to the file chosen in the NSOpenPanel
        if myFileDialog.URL!.path != nil {
            directoryPath = myFileDialog.URL!.path!
            libraryPathField.stringValue = directoryPath!
        }
        
        // Make sure that a path was chosen
        if (directoryPath != nil) {
            let err = NSError?()
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func OKPressed(sender: AnyObject) {
        self.window?.close()
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasStartedBefore")
        NSUserDefaults.standardUserDefaults().setBool(modifyMetadata, forKey: "modifyMetadata")
        NSUserDefaults.standardUserDefaults().setObject(organizationType.rawValue, forKey: "organizationType")
        NSUserDefaults.standardUserDefaults().setObject(directoryPath, forKey: "libraryPath")
        (NSApplication.sharedApplication().delegate as! AppDelegate).initializeLibraryAndShowMainWindow()
    }
    
}
