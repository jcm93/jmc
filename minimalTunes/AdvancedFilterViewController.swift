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
        predicateEditor.addRow(nil)
    }
    
    @IBAction func createSmartPlaylistButtonPressed(sender: AnyObject) {
        let newSmartCriteria = NSEntityDescription.insertNewObjectForEntityForName("SmartCriteria", inManagedObjectContext: managedContext) as! SmartCriteria
        newSmartCriteria.fetch_limit = itemLimitField.integerValue
        newSmartCriteria.fetch_limit_type = playlistLengthDeterminantSelector.stringValue
        newSmartCriteria.ordering_criterion = playlistSelectionCriteriaSelector.stringValue
        newSmartCriteria.predicate = predicateEditor.predicate
        let newPlaylist = NSEntityDescription.insertNewObjectForEntityForName("SongCollection", inManagedObjectContext: managedContext) as! SongCollection
        newPlaylist.smart_criteria = newSmartCriteria
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
