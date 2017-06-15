//
//  OrganizationRuleViewcontroller.swift
//  jmc
//
//  Created by John Moody on 5/29/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

private var my_context = 0

class OrganizationRuleViewcontroller: NSViewController, NSTokenFieldDelegate {
    
    @IBOutlet weak var specialScrollView: SpecialScrollView!
    @IBOutlet weak var tokenField: NSTokenField!
    @IBOutlet weak var pathControl: NSPathControl!
    @IBOutlet weak var box: NSBox!
    
    var names = ["Album", "Album Artist", "Artist", "Year", "Title", "Disc-Track #"]
    var template: OrganizationTemplate?
    
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
    @IBAction func addFieldPressed(_ sender: Any) {
        tokenField.menu?.popUp(positioning: nil, at: tokenField.frame.origin.applying(CGAffineTransform(translationX: 0.0, y: -8.0)), in: self.view)
    }
    
    func tokenField(_ tokenField: NSTokenField, representedObjectForEditing editingString: String) -> Any {
        return OrganizationFieldToken(string: editingString)
    }
    
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        return (representedObject as! OrganizationFieldToken).stringRepresentation()
    }
    
    func tokenField(_ tokenField: NSTokenField, editingStringForRepresentedObject representedObject: Any) -> String? {
        return (representedObject as! OrganizationFieldToken).stringRepresentation()
    }
    
    func tokenField(_ tokenField: NSTokenField, styleForRepresentedObject representedObject: Any) -> NSTokenStyle {
        let object = representedObject as! OrganizationFieldToken
        if object.tokenType == .other {
            return .none
        } else {
            return .rounded
        }
    }
    
    override func controlTextDidChange(_ obj: Notification) {
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
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "predicate" {
            DispatchQueue.main.async {
                let parentWC = self.view.window!.windowController as! AdvancedOrganizationOptionsWindowController
                let indexOfSelf = (parentWC.viewControllerArrayController.arrangedObjects as! NSArray).index(of: self)
                parentWC.tableView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: indexOfSelf))
            }
        }
    }

    @IBOutlet weak var predicateEditor: NSPredicateEditor!
    override func viewDidLoad() {
        super.viewDidLoad()
        tokenField.delegate = self
        self.tokenField.objectValue = self.template?.tokens
        if self.template?.base_url_string != nil {
            self.pathControl.url = URL(string: template!.base_url_string!)
        }
        if self.template != nil {
            self.predicateEditor.objectValue = template?.predicate
        }
        // Do view setup here.
        self.view.translatesAutoresizingMaskIntoConstraints = false
        //self.predicateEditor.translatesAutoresizingMaskIntoConstraints = false
        self.specialScrollView.translatesAutoresizingMaskIntoConstraints = false
        self.box.translatesAutoresizingMaskIntoConstraints = false
        //predicateEditor.addRow(nil)
        let constraint = NSLayoutConstraint(item: specialScrollView, attribute: .height, relatedBy: .equal, toItem: predicateEditor, attribute: .height, multiplier: 1.0, constant: 0.0)
        NSLayoutConstraint.activate([constraint])
        self.view.wantsLayer = true
        for item in self.names {
            tokenField.menu?.addItem(withTitle: item, action: #selector(self.addToken), keyEquivalent: "")
        }
        predicateEditor.addObserver(self, forKeyPath: "predicate", options: .new, context: &my_context)
        box.wantsLayer = true
        box.cornerRadius = 4.0
    }
    
}
