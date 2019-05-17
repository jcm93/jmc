//
//  AdvancedOrganizationOptionsWindowController.swift
//  jmc
//
//  Created by John Moody on 5/29/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class AdvancedOrganizationOptionsWindowController: NSWindowController, NSTokenFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var pathControl: NSPathControl!
    @IBOutlet weak var tableView: StupidTableView!
    
    @IBOutlet weak var tokenField: NSTokenField!
    
    var ruleControllers = [OrganizationRuleViewController]()
    var libraryTemplateBundle: OrganizationTemplateBundle?
    var draggedIndexes: IndexSet?
    var removedRuleControllers = [OrganizationRuleViewController]()
    
    var names = ["Album", "Album Artist", "Artist", "Year", "Title", "Disc-Track #"]
    
    @IBAction func browsePressed(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        let result = panel.runModal()
        if result == NSApplication.ModalResponse.OK {
            pathControl.url = panel.url
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "OrganizationRuleCellView"), owner: nil) as! OrganizationRuleCellView
        let newViewController = ruleControllers[row]
        view.initializeForController(newViewController)
        return view
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        self.draggedIndexes = rowIndexes
        pboard.addTypes([NSPasteboard.PasteboardType(rawValue: "special.poop.rows")], owner: nil)
        return true
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if dropOperation == .above && row < tableView.numberOfRows {
            return .move
        } else {
            return []
        }
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        var offset = 0
        guard self.draggedIndexes!.count == 1 else {
            print("fuck shit stack")
            return false
        }
        for thing in self.draggedIndexes! {
            swap(&ruleControllers[thing], &ruleControllers[row])
            if thing < row {
                offset -= 1
            }
            tableView.moveRow(at: thing, to: row)
        }
        //tableView.reloadData()
        self.draggedIndexes = nil
        print(ruleControllers.map({return $0.predicateEditor.predicate}))
        return true
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let viewForRow = ruleControllers[row]
        return viewForRow.view.fittingSize.height <= tableView.rowHeight ? tableView.rowHeight : viewForRow.view.fittingSize.height
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return ruleControllers.count
    }
    
    @IBAction func addFieldPressed(_ sender: Any) {
        tokenField.menu?.popUp(positioning: nil, at: tokenField.frame.origin.applying(CGAffineTransform(translationX: 0.0, y: -8.0)), in: self.window!.contentView!)
    }
    
    @IBAction func addRulePressed(_ sender: Any) {
        addRule(template: nil)
    }
    
    func addRule(template: OrganizationTemplate?) {
        let newViewController = OrganizationRuleViewController(nibName: "OrganizationRuleViewController", bundle: nil)
        newViewController.template = template
        ruleControllers.append(newViewController)
        if template == nil {
            tableView.insertRows(at: IndexSet(integer: tableView.numberOfRows < 0 ? 0 : tableView.numberOfRows), withAnimation: NSTableView.AnimationOptions.slideDown)
            newViewController.predicateEditor.addRow(nil)
            newViewController.pathControl.url = pathControl.url
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, representedObjectForEditing editingString: String) -> (Any)? {
        return OrganizationFieldToken(string: editingString)
    }
    
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        return (representedObject as! OrganizationFieldToken).stringRepresentation()
    }
    
    func tokenField(_ tokenField: NSTokenField, editingStringForRepresentedObject representedObject: Any) -> String? {
        return (representedObject as! OrganizationFieldToken).stringRepresentation()
    }
    
    func tokenField(_ tokenField: NSTokenField, styleForRepresentedObject representedObject: Any) -> NSTokenField.TokenStyle {
        let object = representedObject as! OrganizationFieldToken
        if object.tokenType == .other {
            return .none
        } else {
            return .rounded
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if tokenField.stringValue.contains("\\") {
            tokenField.stringValue = tokenField.stringValue.replacingOccurrences(of: "\\", with: "")
            tokenField.menu?.popUp(positioning: nil, at: tokenField.frame.origin.applying(CGAffineTransform(translationX: 0.0, y: -8.0)), in: self.window!.contentView!)
        } else {
            
        }
    }
    
    @IBAction func okPressed(_ sender: Any) {
        saveData()
        for rule in ruleControllers {
            rule.removeObservers()
        }
        self.window?.close()
    }
    
    func removeRule(_ vc: OrganizationRuleViewController) {
        let index = ruleControllers.firstIndex(of: vc)
        tableView.removeRows(at: IndexSet(integer: index!), withAnimation: NSTableView.AnimationOptions.slideUp)
        let removedRuleController = ruleControllers.remove(at: index!)
        removedRuleControllers.append(removedRuleController)
        tableView.reloadData()
    }
    
    func saveData() {
        withUndoBlock(name: "Edit Organization Template") {
            let templateBundle = globalRootLibrary?.organization_template
            templateBundle?.default_template?.tokens = self.tokenField.objectValue as! [OrganizationFieldToken] as NSArray
            templateBundle?.default_template?.base_url_string = self.pathControl.url?.absoluteString
            for rule in ruleControllers {
                let template = rule.template ?? NSEntityDescription.insertNewObject(forEntityName: "OrganizationTemplate", into: managedContext) as! OrganizationTemplate
                template.base_url_string = rule.pathControl.url!.absoluteString
                template.predicate = rule.predicateEditor.predicate!
                template.tokens = rule.tokenField.objectValue as? NSObject
            }
            let templateArray = ruleControllers.map({return $0.template!})
            let orderedSet = NSOrderedSet(array: templateArray)
            templateBundle?.other_templates = orderedSet
        }
    }
    func initializeData() {
        if let organizationTemplateBundle = globalRootLibrary?.organization_template {
            tokenField.objectValue = organizationTemplateBundle.default_template?.tokens
            pathControl.url = URL(string: organizationTemplateBundle.default_template!.base_url_string!)
            if let templates = organizationTemplateBundle.other_templates {
                for template in templates {
                    addRule(template: template as? OrganizationTemplate)
                }
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        return IndexSet()
    }
    
    @objc func addToken(sender: NSMenuItem) {
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
        self.tableView.reloadData()
        tableView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: "special.poop.rows")])
    }
    
}
