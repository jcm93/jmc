//
//  CustomFieldWindowController.swift
//  minimalTunes
//
//  Created by John Moody on 10/28/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class CustomFieldWindowController: NSWindowController {

    @IBOutlet weak var fieldNameField: NSTextField!
    @IBOutlet weak var fieldTypeButton: NSPopUpButton!
    @IBOutlet weak var confirmButton: NSButton!
    
    var mainWindow: MainWindowController?
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func confirmPressed(sender: AnyObject) {
        let property = NSEntityDescription.insertNewObjectForEntityForName("Property", inManagedObjectContext: managedContext) as! Property
        property.type = fieldTypeButton.selectedItem?.title
        property.name = fieldNameField.stringValue
        let tableColumn = NSTableColumn(identifier: property.name!)
        tableColumn.title = property.name!
        mainWindow?.customFieldCreated(tableColumn)
    }
}
