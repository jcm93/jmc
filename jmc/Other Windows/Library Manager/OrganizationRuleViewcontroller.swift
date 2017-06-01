//
//  OrganizationRuleViewcontroller.swift
//  jmc
//
//  Created by John Moody on 5/29/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class OrganizationRuleViewcontroller: NSViewController, NSTokenFieldDelegate {
    
    @IBOutlet weak var tokenField: NSTokenField!
    @IBOutlet weak var pathControl: NSPathControl!
    
    @IBAction func browsePressed(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        let result = panel.runModal()
        if result == NSModalResponseOK {
            pathControl.url = panel.url
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, representedObjectForEditing editingString: String) -> Any {
        print("called")
        return OrganizationFieldToken(string: editingString)
    }
    
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        print("called")
        return (representedObject as! OrganizationFieldToken).stringRepresentation()
    }
    
    func tokenField(_ tokenField: NSTokenField, editingStringForRepresentedObject representedObject: Any) -> String? {
        print("called")
        return (representedObject as! OrganizationFieldToken).stringRepresentation()
    }
    
    func tokenField(_ tokenField: NSTokenField, styleForRepresentedObject representedObject: Any) -> NSTokenStyle {
        print("called")
        let object = representedObject as! OrganizationFieldToken
        if object.tokenType == .other {
            return .none
        } else {
            return .rounded
        }
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        print("called")
        if tokenField.stringValue.contains("\\") {
            tokenField.stringValue = tokenField.stringValue.replacingOccurrences(of: "\\", with: "")
            tokenField.menu?.popUp(positioning: nil, at: tokenField.frame.origin.applying(CGAffineTransform(translationX: 0.0, y: -8.0)), in: self.view)
        } else {
            
        }
    }
    
    func addToken(sender: NSMenuItem) {
        var currentTokenArray = tokenField.objectValue as! [OrganizationFieldToken]
        let newToken = OrganizationFieldToken(string: sender.title)
        currentTokenArray.append(newToken)
        tokenField.objectValue = currentTokenArray as NSArray
    }

    @IBOutlet weak var predicateEditor: NSPredicateEditor!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        predicateEditor.addRow(nil)
        tokenField.delegate = self
        for item in self.names {
            tokenField.menu?.addItem(withTitle: item, action: #selector(self.addToken), keyEquivalent: "")
        }
    }
    
}
