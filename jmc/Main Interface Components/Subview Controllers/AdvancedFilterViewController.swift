//
//  AdvancedFilterViewController.swift
//  minimalTunes
//
//  Created by John Moody on 12/2/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

private var my_context = 0

class AdvancedFilterViewController: NSViewController {
    
    @IBOutlet weak var predicateEditor: NSPredicateEditor!
    
    @IBOutlet weak var limitCheck: NSButton!
    @IBOutlet weak var createSmartPlaylistButton: NSButton!
    @IBOutlet weak var playlistLengthDeterminantSelector: NSPopUpButton!
    @IBOutlet weak var itemLimitField: NSTextField!
    @IBOutlet weak var playlistSelectionCriteriaSelector: NSPopUpButton!
    
    var mainWindowController: MainWindowController!
    var tableViewController: LibraryTableViewController!
    var editingSmartPlaylist = false
    var isInitialized = false
    
    init(tableViewController: LibraryTableViewController) {
        super.init(nibName: "AdvancedFilterViewController", bundle: nil)
        self.tableViewController = tableViewController
        self.tableViewController.advancedFilterVisible = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func doesLimitChanged(_ sender: Any) {
        guard let button = sender as? NSButton else { return }
        if button.state == NSControl.StateValue.on {
            self.tableViewController.playlist?.smart_criteria?.fetch_limit = self.itemLimitField.integerValue as NSNumber?
            self.tableViewController.playlist?.smart_criteria?.fetch_limit_type = self.playlistLengthDeterminantSelector.titleOfSelectedItem!
            self.tableViewController.playlist?.smart_criteria?.ordering_criterion = self.playlistSelectionCriteriaSelector.titleOfSelectedItem!
        } else {
            self.tableViewController.playlist?.smart_criteria?.fetch_limit = nil
            self.tableViewController.playlist?.smart_criteria?.fetch_limit_type = nil
            self.tableViewController.playlist?.smart_criteria?.ordering_criterion = nil
        }
        self.refreshSmartPlaylist(self)
        
    }
    @IBAction func refreshSmartPlaylist(_ sender: Any) {
        self.tableViewController.initializeSmartPlaylist()
        self.tableViewController.initializeForPlaylist()
    }
    
    @IBAction func fetchLimitChanged(_ sender: Any) {
        guard let textField = sender as? NSTextField else { return }
        guard limitCheck.state == NSControl.StateValue.on else { return }
        self.tableViewController.playlist?.smart_criteria?.fetch_limit = textField.integerValue as NSNumber?
        self.refreshSmartPlaylist(self)
    }
    
    @IBAction func lengthDeterminantChanged(_ sender: AnyObject) {
        guard let popUpButton = sender as? NSPopUpButton else { return }
        guard limitCheck.state == NSControl.StateValue.on else { return }
        self.tableViewController.playlist?.smart_criteria?.fetch_limit_type = popUpButton.titleOfSelectedItem!
        self.refreshSmartPlaylist(self)
    }

    @IBAction func orderingCriterionChanged(_ sender: AnyObject) {
        guard let popUpButton = sender as? NSPopUpButton else { return }
        guard limitCheck.state == NSControl.StateValue.on else { return }
        self.tableViewController.playlist?.smart_criteria?.ordering_criterion = popUpButton.titleOfSelectedItem!
        self.refreshSmartPlaylist(self)
    }
    
    func initializePredicateEditor() {
        if let smartCriteria = self.tableViewController.playlist?.smart_criteria {
            self.predicateEditor.objectValue = smartCriteria.predicate
            self.itemLimitField.stringValue = smartCriteria.fetch_limit?.stringValue ?? ""
            self.limitCheck.state = smartCriteria.fetch_limit != nil ? NSControl.StateValue.on : NSControl.StateValue.off
            if smartCriteria.fetch_limit_type != nil {
                self.playlistLengthDeterminantSelector.selectItem(withTitle: smartCriteria.fetch_limit_type!)
            }
            if smartCriteria.ordering_criterion != nil {
                self.playlistSelectionCriteriaSelector.selectItem(withTitle: smartCriteria.ordering_criterion!)
            }
        } else {
            self.predicateEditor.objectValue = self.tableViewController.trackViewArrayController.filterPredicate
        }
        if predicateEditor.predicate == nil {
            predicateEditor.addRow(nil)
        }
    }
    
    @IBAction func predicateEditorAction(_ sender: Any) {
        print("predicate value changed")
        if self.tableViewController.playlist?.smart_criteria != nil {
            if self.editingSmartPlaylist == false {
                self.tableViewController.trackViewArrayController.content = nil
                self.editingSmartPlaylist = true
            }
            self.tableViewController.playlist!.smart_criteria!.predicate = self.predicateEditor.predicate!
            self.refreshSmartPlaylist(self)
        }
    }
    
    @IBAction func createSmartPlaylistButtonPressed(_ sender: AnyObject) {
        let newSmartCriteria = NSEntityDescription.insertNewObject(forEntityName: "SmartCriteria", into: managedContext) as! SmartCriteria
        if limitCheck.state == NSControl.StateValue.on {
            newSmartCriteria.fetch_limit = itemLimitField.integerValue as NSNumber?
            newSmartCriteria.fetch_limit_type = playlistLengthDeterminantSelector.titleOfSelectedItem
            newSmartCriteria.ordering_criterion = playlistSelectionCriteriaSelector.titleOfSelectedItem
        } else {
            newSmartCriteria.fetch_limit = nil
            newSmartCriteria.fetch_limit_type = nil
            newSmartCriteria.ordering_criterion = nil
        }
        newSmartCriteria.predicate = predicateEditor.predicate
        mainWindowController?.createPlaylistFromSmartCriteria(newSmartCriteria)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if mainWindowController?.currentTableViewController?.playlist != nil {
            createSmartPlaylistButton.isEnabled = false
        }
        // Do view setup here.
    }
    
}
