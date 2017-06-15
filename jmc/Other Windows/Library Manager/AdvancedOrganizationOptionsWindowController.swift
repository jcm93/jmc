//
//  AdvancedOrganizationOptionsWindowController.swift
//  jmc
//
//  Created by John Moody on 5/29/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class AdvancedOrganizationOptionsWindowController: NSWindowController, NSTokenFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet var viewControllerArrayController: NSArrayController!
    @IBOutlet weak var pathControl: NSPathControl!
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var tokenField: NSTokenField!
    
    var ruleControllers = [OrganizationRuleViewcontroller]()
    var libraryTemplateBundle: OrganizationTemplateBundle?
    var draggedIndexes: IndexSet?
    
    var names = ["Album", "Album Artist", "Artist", "Year", "Title", "Disc-Track #"]
    
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
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.make(withIdentifier: "OrganizationRuleCellView", owner: nil) as! OrganizationRuleCellView
        let newViewController = (self.viewControllerArrayController.arrangedObjects as! NSArray)[row] as! OrganizationRuleViewcontroller
        view.organizationView?.addSubview(newViewController.view)
        //newViewController.view.frame = view.bounds
        newViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        newViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        newViewController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        newViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        //newViewController.viewDidLoad()
        return view
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        self.draggedIndexes = rowIndexes
        pboard.addTypes(["special.poop.rows"], owner: nil)
        return true
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        if dropOperation == .above {
            return .move
        } else {
            return []
        }
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        var offset = 0
        for thing in self.draggedIndexes! {
            tableView.moveRow(at: thing, to: row)
            let viewController = (viewControllerArrayController.arrangedObjects as! NSArray)[thing]
            viewControllerArrayController.remove(atArrangedObjectIndex: thing)
            if thing < row {
                offset -= 1
            }
            viewControllerArrayController.insert(viewController, atArrangedObjectIndex: row)
        }
        tableView.reloadData()
        self.draggedIndexes = nil
        return true
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let viewForRow = (viewControllerArrayController.arrangedObjects as! NSArray)[row] as! OrganizationRuleViewcontroller
        print(viewForRow.view.fittingSize)
        return viewForRow.view.fittingSize.height <= tableView.rowHeight ? tableView.rowHeight : viewForRow.view.fittingSize.height
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return (viewControllerArrayController.arrangedObjects as! NSArray).count
    }
    
    @IBAction func addFieldPressed(_ sender: Any) {
        tokenField.menu?.popUp(positioning: nil, at: tokenField.frame.origin.applying(CGAffineTransform(translationX: 0.0, y: -8.0)), in: self.window!.contentView!)
    }
    
    @IBAction func addRulePressed(_ sender: Any) {
        addRule(template: nil)
    }
    
    func addRule(template: OrganizationTemplate?) {
        let newViewController = OrganizationRuleViewcontroller(nibName: "OrganizationRuleViewcontroller", bundle: nil)
        newViewController!.template = template
        ruleControllers.append(newViewController!)
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
            defaultTemplate.tokens = self.tokenField.objectValue as! [OrganizationFieldToken] as NSArray
            defaultTemplate.base_url_string = self.pathControl.url?.absoluteString
            newTemplateBundle.default_template = defaultTemplate
            for rule in ruleControllers {
                let template = NSEntityDescription.insertNewObject(forEntityName: "OrganizationTemplate", into: managedContext) as! OrganizationTemplate
                template.predicate = rule.predicateEditor.predicate!
                template.tokens = rule.tokenField.objectValue as? NSObject
                template.base_url_string = rule.pathControl.url!.absoluteString
                newTemplateBundle.addToOther_templates(template)
            }
            globalRootLibrary?.organization_template = newTemplateBundle
        }
    }
    func initializeData() {
        if let organizationTemplateBundle = globalRootLibrary?.organization_template {
            tokenField.objectValue = organizationTemplateBundle.default_template?.tokens
            pathControl.url = URL(string: organizationTemplateBundle.default_template!.base_url_string!)
            if let templates = organizationTemplateBundle.other_templates {
                for template in templates {
                    addRule(template: template as! OrganizationTemplate)
                }
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        return IndexSet()
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
        self.viewControllerArrayController.content = self.ruleControllers
        self.tableView.reloadData()
        tableView.register(forDraggedTypes: ["special.poop.rows"])
    }
    
}
