//
//  AdvancedFilterViewController.swift
//  minimalTunes
//
//  Created by John Moody on 12/2/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class AdvancedFilterViewController: NSViewController {
    
    @IBOutlet weak var predicateEditor: NSPredicateEditor!
    
    @IBOutlet weak var createSmartPlaylistButton: NSButton!
    @IBOutlet weak var playlistLengthDeterminantSelector: NSPopUpButton!
    @IBOutlet weak var itemLimitField: NSTextField!
    @IBOutlet weak var playlistSelectionCriteriaSelector: NSPopUpButton!
    
    var mainWindowController: MainWindowController?
    
    @IBAction func lengthDeterminantChanged(sender: AnyObject) {
        
    }

    @IBAction func orderingCriterionChanged(sender: AnyObject) {
        
    }
    
    func initializePredicateEditor() {
        if predicateEditor.predicate == nil {
            predicateEditor.addRow(nil)
        }
    }
    
    @IBAction func createSmartPlaylistButtonPressed(sender: AnyObject) {
        let newSmartCriteria = NSEntityDescription.insertNewObjectForEntityForName("SmartCriteria", inManagedObjectContext: managedContext) as! SmartCriteria
        newSmartCriteria.fetch_limit = itemLimitField.integerValue
        newSmartCriteria.fetch_limit_type = playlistLengthDeterminantSelector.titleOfSelectedItem
        newSmartCriteria.ordering_criterion = playlistSelectionCriteriaSelector.titleOfSelectedItem
        newSmartCriteria.predicate = predicateEditor.predicate
        mainWindowController?.createPlaylistFromSmartCriteria(newSmartCriteria)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
