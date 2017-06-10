//
//  AdvancedOrganizationOptionsWindowController.swift
//  jmc
//
//  Created by John Moody on 5/29/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class AdvancedOrganizationOptionsWindowController: NSWindowController, NSTokenFieldDelegate {
    
    @IBOutlet weak var pathControl: NSPathControl!
    @IBOutlet weak var splitView: NSSplitView!
    
    @IBOutlet weak var tokenField: NSTokenField!
    
    var ruleControllers = [OrganizationRuleViewcontroller]()
    var libraryTemplateBundle: OrganizationTemplateBundle?
    
    var names = ["Album", "Album Artist", "Artist", "Track #", "Year", "Track Name"]
    
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
    
    @IBAction func addRulePressed(_ sender: Any) {
        addRule(template: nil)
    }
    
    func addRule(template: OrganizationTemplate?) {
        let newViewController = OrganizationRuleViewcontroller(nibName: "OrganizationRuleViewcontroller", bundle: nil)
        ruleControllers.append(newViewController!)
        splitView.addArrangedSubview(newViewController!.view)
        newViewController?.tokenField.objectValue = template?.tokens
        newViewController?.pathControl.url = URL(string: template!.base_url_string!)
        if template != nil {
            newViewController?.predicateEditor.objectValue = template?.predicate
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
            tokenField.menu?.popUp(positioning: nil, at: tokenField.frame.origin.applying(CGAffineTransform(translationX: 0.0, y: -8.0)), in: self.window!.contentView!)
        } else {
            
        }
    }
    
    @IBAction func okPressed(_ sender: Any) {
        saveData()
    }
    
    func saveData() {
        withUndoBlock(name: "Edit Organization Template") {
            let newTemplateBundle = NSEntityDescription.insertNewObject(forEntityName: "OrganizationTemplateBundle", into: managedContext) as! OrganizationTemplateBundle
            let defaultTemplate = NSEntityDescription.insertNewObject(forEntityName: "OrganizationTemplate", into: managedContext) as! OrganizationTemplate
            defaultTemplate.tokens = self.tokenField.objectValue as? NSObject
            defaultTemplate.base_url_string = self.pathControl.url?.absoluteString
            newTemplateBundle.default_template = defaultTemplate
            for rule in ruleControllers {
                let template = NSEntityDescription.insertNewObject(forEntityName: "OrganizationTemplate", into: managedContext) as! OrganizationTemplate
                template.predicate = rule.predicateEditor.predicate!
                template.tokens = rule.tokenField.objectValue as? NSObject
                template.base_url_string = rule.pathControl.url!.absoluteString
                newTemplateBundle.addToOther_templates(template)
            }
            globalRootLibrary?.organization_templates = newTemplateBundle
        }
    }
    func initializeData() {
        if let organizationTemplateBundle = globalRootLibrary?.organization_template {
            tokenField.objectValue = organizationTemplateBundle.default_template?.tokens
            pathControl.url = URL(string: organizationTemplateBundle.default_template!.base_url_string!)
            for template in (organizationTemplateBundle.other_templates as! Set<OrganizationTemplate>) {
                addRule(template: template)
            }
        }
    }
    
    func addToken(sender: NSMenuItem) {
        var currentTokenArray = tokenField.objectValue as! [OrganizationFieldToken]
        let newToken = OrganizationFieldToken(string: sender.title)
        currentTokenArray.append(newToken)
        tokenField.objectValue = currentTokenArray as NSArray
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        tokenField.delegate = self
        for item in self.names {
            tokenField.menu?.addItem(withTitle: item, action: #selector(self.addToken), keyEquivalent: "")
        }
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        initializeData()
    }
    
}
