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
    
    var lastFMDelegate: LastFMDelegate!
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [NSToolbarItem.Identifier(rawValue: "general"), NSToolbarItem.Identifier(rawValue: "sharing"), NSToolbarItem.Identifier(rawValue: "lastfm"), NSToolbarItem.Identifier(rawValue: "advanced"), NSToolbarItem.Identifier(rawValue: "library")]
    }
    
    @IBAction func selectGeneral(_ sender: Any) {
        tabView.selectTabViewItem(at: 0)
        resizeSmaller()
    }
    @IBAction func selectSharing(_ sender: Any) {
        tabView.selectTabViewItem(at: 1)
        resizeSmaller()
    }
    @IBAction func selectLastFM(_ sender: Any) {
        tabView.selectTabViewItem(at: 2)
        resizeSmaller()
    }
    
    @IBAction func selectAdvanced(_ sender: Any) {
        tabView.selectTabViewItem(at: 3)
        resizeSmaller()
    }
    @IBAction func selectLibrary(_ sender: Any) {
        tabView.selectTabViewItem(at: 4)
        resizeLarger()
    }
    
    func resizeLarger() {
        let currentHeight: CGFloat = self.window!.frame.height
        let currentWidth: CGFloat = self.window!.frame.width
        let newHeight: CGFloat = 568 + 110
        let newWidth: CGFloat = 892
        let xDifference = (newWidth - currentWidth) / 2
        let yDifference = newHeight - currentHeight
        let newX = self.window!.frame.origin.x - xDifference
        let newY = self.window!.frame.origin.y - yDifference
        let newOrigin = CGPoint(x: newX, y: newY)
        let newSize = CGSize(width: newWidth, height: newHeight)
        let newFrame = NSRect(origin: newOrigin, size: newSize)
        self.window?.animator().setFrame(newFrame, display: true)
    }
    
    func resizeSmaller() {
        let currentHeight: CGFloat = self.window!.frame.height
        let currentWidth: CGFloat = self.window!.frame.width
        let newHeight: CGFloat = 206 + 80
        let newWidth: CGFloat = 527
        let xDifference = (newWidth - currentWidth) / 2
        let yDifference = newHeight - currentHeight
        let newX = self.window!.frame.origin.x - xDifference
        let newY = self.window!.frame.origin.y - yDifference
        let newOrigin = CGPoint(x: newX, y: newY)
        let newSize = CGSize(width: newWidth, height: newHeight)
        let newFrame = NSRect(origin: newOrigin, size: newSize)
        self.window?.animator().setFrame(newFrame, display: true)
    }
    
    @IBAction func artworkSelectRadioAction(_ sender: Any) {
        switch artworkSelectedTrackRadio.state {
        case NSControl.StateValue.on:
            UserDefaults.standard.set(true, forKey: DEFAULTS_ARTWORK_SHOWS_SELECTED)
        default:
            UserDefaults.standard.set(false, forKey: DEFAULTS_ARTWORK_SHOWS_SELECTED)
        }
    }
    
    @IBAction func numTrackQueueTracksEdited(_ sender: Any) {
        UserDefaults.standard.set(trackQueueNumTracksField.integerValue, forKey: DEFAULTS_NUM_PAST_TRACKS)
        //very bad.
        (NSApplication.shared.delegate as! AppDelegate).mainWindowController?.trackQueueViewController?.tableView.minimumNumberVisibleRows = trackQueueNumTracksField.integerValue + 2
    }
    
    @IBAction func sliderAction(_ sender: Any) {
        UserDefaults.standard.set(slider.doubleValue, forKey: DEFAULTS_TRACK_PLAY_REGISTER_POINT)
    }
    
    //Sharing
    @IBOutlet weak var sharingCheck: NSButton!
    @IBOutlet weak var libraryNameField: NSTextField!
    
    @IBAction func sharingCheckAction(_ sender: Any) {
        guard let check = sender as? NSButton else { return }
        switch check.state {
        case NSControl.StateValue.on:
            UserDefaults.standard.set(true, forKey: DEFAULTS_SHARING_STRING)
        default:
            UserDefaults.standard.set(false, forKey: DEFAULTS_SHARING_STRING)
        }
    }
    
    @IBAction func libraryNameFieldEdtied(_ sender: Any) {
        guard let field = sender as? NSTextField, field.stringValue != "" else { return }
        globalRootLibrary?.name = field.stringValue
    }
    
    //Last.fm
    
    @IBOutlet weak var confirmAuthButton: NSButton!
    @IBOutlet weak var authStatusLabel: NSTextField!
    @IBOutlet weak var authStatusImage: NSImageView!
    @IBOutlet weak var authFailedLabel: NSTextField!
    @IBOutlet weak var authProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var startAuthButton: NSButton!
    @IBOutlet weak var browserTextLabel: NSTextField!
    
    func getLastFMDelegate() {
        if self.lastFMDelegate == nil {
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            self.lastFMDelegate = appDelegate.lastFMDelegate
            self.lastFMDelegate.setup()
        }
    }
    
    @IBAction func scrobbleCheck(_ sender: Any) {
        getLastFMDelegate()
        guard let check = sender as? NSButton else { return }
        switch check.state {
        case NSControl.StateValue.on:
            self.lastFMDelegate.scrobbles = true
            UserDefaults.standard.set(true, forKey: DEFAULTS_SCROBBLES)
        default:
            self.lastFMDelegate.scrobbles = false
            UserDefaults.standard.set(false, forKey: DEFAULTS_SCROBBLES)
        }
    }
    
    @IBAction func authenticateLastFMPressed(_ sender: Any) {
        getLastFMDelegate()
        lastFMDelegate.launchAuthentication()
        confirmAuthButton.isHidden = false
    }
    
    @IBAction func confirmAuthButtonPressed(_ sender: Any) {
        getLastFMDelegate()
        lastFMDelegate.getSessionKey(callback: lastFMSessionAuthenticated)
        hideAllElements()
    }
    
    func hideAllElements() {
        confirmAuthButton.isHidden = true
        authFailedLabel.isHidden = true
        startAuthButton.isHidden = true
        browserTextLabel.isHidden = true
        authProgressIndicator.isHidden = false
        authProgressIndicator.startAnimation(nil)
    }
    
    func authFailed() {
        authFailedLabel.isHidden = false
        confirmAuthButton.isHidden = true
        startAuthButton.isHidden = false
        browserTextLabel.isHidden = false
    }
    
    func authSucceeded(name: String) {
        self.authStatusImage.image = NSImage(named: NSImage.statusAvailableName)
        self.authStatusLabel.stringValue = "Authenticated with Last.fm for user \(name)"
        authFailedLabel.isHidden = true
        startAuthButton.isHidden = false
        browserTextLabel.isHidden = false
        confirmAuthButton.isHidden = true
    }
    
    func lastFMSessionAuthenticated(username: String) {
        authProgressIndicator.stopAnimation(nil)
        authProgressIndicator.isHidden = true
        if username != "" {
            authSucceeded(name: username)
        } else {
            authFailed()
        }
    }
    
    //Library
    @IBOutlet weak var libraryManagerTargetView: NSView!
    var libraryManagerViewController: LibraryManagerViewController?
    var verifyLocationsSheet: LocationVerifierSheetController?
    var mediaScannerSheet: MediaScannerSheet?
    var watchFolderSheet: AddWatchFolderSheetController?
    var changeFolderSheet: ChangePrimaryFolderSheetController?
    var consolidateSheet: ConsolidateLibrarySheetController?
    var someOtherSheet: GenericProgressBarSheetController?
    
    //Advanced
    
    @IBOutlet weak var skipBehaviorKeepCurrentFocusRadioButton: NSButton!
    @IBOutlet weak var skipBehaviorFocusNewTrackRadioButton: NSButton!
    
    @IBOutlet weak var sortBehaviorKeepCurrentFocusRadioButton: NSButton!
    @IBOutlet weak var sortBehaviorFocusCurrentTrackRadioButton: NSButton!
    @IBOutlet weak var sortBehaviorFocusSelectionRadioButton: NSButton!
    
    @IBAction func tableSkipBehaviorRadioAction(_ sender: Any) {
        switch skipBehaviorKeepCurrentFocusRadioButton.state {
        case NSControl.StateValue.on:
            UserDefaults.standard.set(false, forKey: DEFAULTS_TABLE_SKIP_SHOWS_NEW_TRACK)
        default:
            UserDefaults.standard.set(true, forKey: DEFAULTS_TABLE_SKIP_SHOWS_NEW_TRACK)
        }
    }
    
    @IBAction func tableSortBehaviorRadioAction(_ sender: Any) {
        if sortBehaviorFocusSelectionRadioButton.state == NSControl.StateValue.on {
            UserDefaults.standard.set(TableSortBehavior.followsSelection.rawValue, forKey: DEFAULTS_TABLE_SORT_BEHAVIOR)
        } else if sortBehaviorFocusCurrentTrackRadioButton.state == NSControl.StateValue.on {
            UserDefaults.standard.set(TableSortBehavior.followsCurrentTrack.rawValue, forKey: DEFAULTS_TABLE_SORT_BEHAVIOR)
        } else {
            UserDefaults.standard.set(TableSortBehavior.followsNothing.rawValue, forKey: DEFAULTS_TABLE_SORT_BEHAVIOR)
        }
    }
    
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        toolbar.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: "general")
        self.trackQueueNumTracksField.integerValue = UserDefaults.standard.integer(forKey: DEFAULTS_NUM_PAST_TRACKS)
        if UserDefaults.standard.bool(forKey: DEFAULTS_ARTWORK_SHOWS_SELECTED) {
            artworkSelectedTrackRadio.state = NSControl.StateValue.on
        } else {
            artworkCurrentTrackRadio.state = NSControl.StateValue.on
        }
        let trackWasPlayedPoint = UserDefaults.standard.double(forKey: DEFAULTS_TRACK_PLAY_REGISTER_POINT)
        if trackWasPlayedPoint != 0.0 {
            slider.doubleValue = trackWasPlayedPoint
        } else {
            slider.doubleValue = 0.75
            UserDefaults.standard.set(0.75, forKey: DEFAULTS_TRACK_PLAY_REGISTER_POINT)
        }
        if UserDefaults.standard.bool(forKey: DEFAULTS_SHARING_STRING) {
            sharingCheck.state = NSControl.StateValue.on
        } else {
            sharingCheck.state = NSControl.StateValue.off
        }
        libraryNameField.stringValue = globalRootLibrary?.name ?? ""
        
        if UserDefaults.standard.bool(forKey: DEFAULTS_TABLE_SKIP_SHOWS_NEW_TRACK) {
            skipBehaviorFocusNewTrackRadioButton.state = NSControl.StateValue.on
        } else {
            skipBehaviorKeepCurrentFocusRadioButton.state = NSControl.StateValue.on
        }
        let sortBehavior = TableSortBehavior(rawValue: UserDefaults.standard.integer(forKey: DEFAULTS_TABLE_SORT_BEHAVIOR))!
        switch sortBehavior {
        case .followsCurrentTrack:
            sortBehaviorFocusCurrentTrackRadioButton.state = NSControl.StateValue.on
        case .followsNothing:
            sortBehaviorKeepCurrentFocusRadioButton.state = NSControl.StateValue.on
        default:
            sortBehaviorFocusSelectionRadioButton.state = NSControl.StateValue.on
        }
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        if globalRootLibrary?.last_fm_session_key != nil {
            lastFMSessionAuthenticated(username: globalRootLibrary!.last_fm_username!)
        }
        self.libraryManagerViewController = LibraryManagerViewController(nibName: "LibraryManagerViewController", bundle: nil)
        self.libraryManagerTargetView.addSubview(self.libraryManagerViewController!.view)
        self.libraryManagerViewController?.initializeForLibrary(library: globalRootLibrary!)
        
    }
    
}
