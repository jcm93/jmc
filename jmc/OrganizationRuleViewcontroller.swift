//
//  OrganizationRuleViewcontroller.swift
//  jmc
//
//  Created by John Moody on 5/29/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class OrganizationRuleViewcontroller: NSViewController, NSTokenFieldDelegate {
    
    var names = Set(tokenList.map({return $0.name}))
    
    @IBOutlet weak var tokenField: NSTokenField!
    @IBOutlet weak var pathControl: NSPathControl!
    
    override func controlTextDidChange(_ obj: Notification) {
        print("called")
        if tokenField.stringValue.contains("\\") {
            tokenField.stringValue = tokenField.stringValue.replacingOccurrences(of: "\\", with: "")
            tokenField.menu?.popUp(positioning: nil, at: tokenField.frame.origin.applying(CGAffineTransform(translationX: 0.0, y: -8.0)), in: self.view)
        } else {
            
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, representedObjectForEditing editingString: String) -> Any {
        return OrganizationFieldToken(name: editingString)
    }
    
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        return (representedObject as! OrganizationFieldToken).name
    }
    
    func tokenField(_ tokenField: NSTokenField, editingStringForRepresentedObject representedObject: Any) -> String? {
        return (representedObject as! OrganizationFieldToken).name
    }
    
    func tokenField(_ tokenField: NSTokenField, styleForRepresentedObject representedObject: Any) -> NSTokenStyle {
        let object = representedObject as! OrganizationFieldToken
        if !names.contains(object.name) {
            //return NSPlainTextTokenStyle
            return .none
        } else {
            return .rounded
        }
    }
    
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
    func addToken(sender: NSMenuItem) {
        let currentPosition = tokenField.currentEditor()!.selectedRange.location
        var currentTokenArray = tokenField.objectValue as! [OrganizationFieldToken]
        currentTokenArray.append(OrganizationFieldToken(name: sender.title))
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
