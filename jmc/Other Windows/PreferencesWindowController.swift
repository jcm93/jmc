//
//  PreferencesWindowController.swift
//  jmc
//
//  Created by John Moody on 4/21/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController, NSToolbarDelegate {

    @IBOutlet weak var toolbar: NSToolbar!
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var slider: NSSlider!
    @IBOutlet weak var trackQueueNumTracksField: NSTextField!
    @IBOutlet weak var artworkSelectedTrackRadio: NSButton!
    @IBOutlet weak var artworkCurrentTrackRadio: NSButton!
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [String] {
        return ["general", "sharing", "advanced"]
    }
    
    @IBAction func selectGeneral(_ sender: Any) {
        tabView.selectTabViewItem(at: 0)
    }
    @IBAction func selectSharing(_ sender: Any) {
        tabView.selectTabViewItem(at: 1)
    }
    @IBAction func selectAdvanced(_ sender: Any) {
        tabView.selectTabViewItem(at: 2)
    }
    
    @IBAction func artworkSelectRadioAction(_ sender: Any) {
        switch artworkSelectedTrackRadio.state {
        case NSOnState:
            UserDefaults.standard.set(true, forKey: DEFAULTS_ARTWORK_SHOWS_SELECTED)
        default:
            UserDefaults.standard.set(false, forKey: DEFAULTS_ARTWORK_SHOWS_SELECTED)
        }
    }
    
    @IBAction func numTrackQueueTracksEdited(_ sender: Any) {
        UserDefaults.standard.set(trackQueueNumTracksField.integerValue, forKey: DEFAULTS_NUM_PAST_TRACKS)
    }
    
    @IBAction func sliderAction(_ sender: Any) {
        UserDefaults.standard.set(slider.doubleValue, forKey: DEFAULTS_TRACK_PLAY_REGISTER_POINT)
    }
    
    //SHARING
    
    @IBAction func sharingCheckAction(_ sender: Any) {
        guard let check = sender as? NSButton else { return }
        switch check.state {
        case NSOnState:
            UserDefaults.standard.set(true, forKey: DEFAULTS_SHARING_STRING)
        default:
            UserDefaults.standard.set(false, forKey: DEFAULTS_SHARING_STRING)
        }
    }
    
    @IBAction func libraryNameFieldEdtied(_ sender: Any) {
        guard let field = sender as? NSTextField, field.stringValue != "" else { return }
        globalRootLibrary?.name = field.stringValue
    }
    
    //ADVANCED
    
    @IBOutlet weak var skipBehaviorKeepCurrentFocusRadioButton: NSButton!
    @IBOutlet weak var skipBehaviorFocusNewTrackRadioButton: NSButton!
    
    @IBOutlet weak var sortBehaviorKeepCurrentFocusRadioButton: NSButton!
    @IBOutlet weak var sortBehaviorFocusCurrentTrackRadioButton: NSButton!
    @IBOutlet weak var sortBehaviorFocusSelectionRadioButton: NSButton!
    
    @IBAction func tableSkipBehaviorRadioAction(_ sender: Any) {
        switch skipBehaviorKeepCurrentFocusRadioButton.state {
        case NSOnState:
            UserDefaults.standard.set(false, forKey: DEFAULTS_TABLE_SKIP_SHOWS_NEW_TRACK)
        default:
            UserDefaults.standard.set(true, forKey: DEFAULTS_TABLE_SKIP_SHOWS_NEW_TRACK)
        }
    }
    
    @IBAction func tableSortBehaviorRadioAction(_ sender: Any) {
        if sortBehaviorFocusSelectionRadioButton.state == NSOnState {
            UserDefaults.standard.set(TableSortBehavior.followsSelection.rawValue, forKey: DEFAULTS_TABLE_SORT_BEHAVIOR)
        } else if sortBehaviorFocusCurrentTrackRadioButton.state == NSOnState {
            UserDefaults.standard.set(TableSortBehavior.followsCurrentTrack.rawValue, forKey: DEFAULTS_TABLE_SORT_BEHAVIOR)
        } else {
            UserDefaults.standard.set(TableSortBehavior.followsNothing.rawValue, forKey: DEFAULTS_TABLE_SORT_BEHAVIOR)
        }
    }
    
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        toolbar.selectedItemIdentifier = "general"

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
