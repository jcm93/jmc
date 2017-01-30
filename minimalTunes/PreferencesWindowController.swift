//
//  PreferencesWindowController.swift
//  minimalTunes
//
//  Created by John Moody on 7/8/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController {
    
    
    @IBOutlet weak var libraryNameField: NSTextField!
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var organizeLibraryCheck: NSButton!
    @IBOutlet weak var organizationString: NSTextField!

    @IBOutlet weak var checkAlbumDirectoryCheck: NSButton!
    @IBOutlet weak var checkEmbeddedArtworkCheck: NSButton!
    @IBOutlet weak var sharingCheck: NSButton!
    @IBOutlet weak var copyRadio: NSButton!
    @IBOutlet weak var moveRadio: NSButton!
    @IBOutlet weak var mediaFolderPath: NSTextField!
    var mediaFolderURL: NSURL?
    
    @IBAction func radioButtonAction(sender: AnyObject) {
        
    }
    @IBAction func generalPressed(sender: AnyObject) {
        tabView.selectTabViewItemAtIndex(0)
    }
    
    @IBAction func playbackPressed(sender: AnyObject) {
        tabView.selectTabViewItemAtIndex(1)
    }
    
    @IBAction func sharingPressed(sender: AnyObject) {
        tabView.selectTabViewItemAtIndex(2)
    }
    
    @IBAction func libraryPressed(sender: AnyObject) {
        tabView.selectTabViewItemAtIndex(3)
    }
    
    @IBAction func advancedPressed(sender: AnyObject) {
        tabView.selectTabViewItemAtIndex(4)
    }
    
    @IBOutlet weak var browseButton: NSButton!
    
    @IBAction func organizationCheckAction(sender: AnyObject) {
        if organizeLibraryCheck.state == NSOnState {
            moveRadio.enabled = true
            copyRadio.enabled = true
            moveRadio.state = NSOnState
            browseButton.enabled = true
        } else {
            browseButton.enabled = false
            moveRadio.enabled = false
            copyRadio.enabled = false
            moveRadio.state = NSOffState
            copyRadio.state = NSOffState
        }
    }
    
    @IBAction func browseClicked(sender: AnyObject) {
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        myFileDialog.canChooseFiles = false
        myFileDialog.canChooseDirectories = true
        myFileDialog.runModal()
        
        // Get the path to the file chosen in the NSOpenPanel
        if myFileDialog.URL!.path != nil {
            mediaFolderURL = myFileDialog.URL!
            mediaFolderPath.stringValue = mediaFolderURL!.path!
        }
    }

    func initializeFields() {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        libraryNameField.stringValue = defaults.stringForKey(DEFAULTS_LIBRARY_NAME_STRING) != nil ? defaults.stringForKey(DEFAULTS_LIBRARY_NAME_STRING)! : ""
        let organization = defaults.integerForKey(DEFAULTS_LIBRARY_ORGANIZATION_TYPE_STRING)
        if organization == NO_ORGANIZATION_TYPE {
            organizeLibraryCheck.state = NSOffState
            mediaFolderPath.stringValue = ""
            browseButton.enabled = false
            moveRadio.enabled = false
            copyRadio.enabled = false
            organizationString.stringValue = LIBRARY_DOES_NOTHING_DESCRIPTION
        } else {
            browseButton.enabled = true
            moveRadio.enabled = true
            copyRadio.enabled = true
            if organization == MOVE_ORGANIZATION_TYPE {
                moveRadio.state = NSOnState
                copyRadio.state = NSOffState
                organizationString.stringValue = LIBRARY_MOVES_DESCRIPTION
            } else {
                copyRadio.state = NSOnState
                moveRadio.state = NSOffState
                organizationString.stringValue = LIBRARY_COPIES_DESCRIPTION
            }
        }
        
        let sharing = defaults.boolForKey(DEFAULTS_SHARING_STRING)
        sharingCheck.state = sharing == true ? NSOnState : NSOffState
        
        let checkEmbedded = defaults.boolForKey(DEFAULTS_CHECK_EMBEDDED_ARTWORK_STRING)
        checkEmbeddedArtworkCheck.state = checkEmbedded == true ? NSOnState : NSOffState
        
        let checkDir = defaults.boolForKey(DEFAULTS_CHECK_ALBUM_DIRECTORY_FOR_ART_STRING)
        checkAlbumDirectoryCheck.state = checkDir == true ? NSOnState : NSOffState
        
        mediaFolderPath.stringValue = defaults.stringForKey(DEFAULTS_LIBRARY_PATH_STRING)!
        
        
    }
    @IBAction func cancelAction(sender: AnyObject) {
        print("cancel action on preferences")
        self.window?.close()
    }
    
    @IBAction func okAction(sender: AnyObject) {
        print("ok action on preferences")
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(libraryNameField.stringValue, forKey: DEFAULTS_LIBRARY_NAME_STRING)
        defaults.setBool(Bool(sharingCheck.state), forKey: DEFAULTS_SHARING_STRING)
        defaults.setBool(Bool(checkEmbeddedArtworkCheck.state), forKey: DEFAULTS_CHECK_EMBEDDED_ARTWORK_STRING)
        defaults.setBool(Bool(checkAlbumDirectoryCheck.state), forKey: DEFAULTS_CHECK_ALBUM_DIRECTORY_FOR_ART_STRING)
        if organizeLibraryCheck.state == NSOffState {
            defaults.setInteger(NO_ORGANIZATION_TYPE, forKey: DEFAULTS_LIBRARY_ORGANIZATION_TYPE_STRING)
        } else {
            if mediaFolderPath.stringValue != "/" && mediaFolderPath.stringValue != "" {
                defaults.setObject(mediaFolderPath.stringValue, forKey: DEFAULTS_LIBRARY_PATH_STRING)
            }
            if moveRadio.state == NSOnState {
                defaults.setInteger(MOVE_ORGANIZATION_TYPE, forKey: DEFAULTS_LIBRARY_ORGANIZATION_TYPE_STRING)
            } else if copyRadio.state == NSOnState {
                defaults.setInteger(COPY_ORGANIZATION_TYPE, forKey: DEFAULTS_LIBRARY_ORGANIZATION_TYPE_STRING)
            }
        }
        self.window?.close()
    }
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        generalPressed(self)
        initializeFields()
        

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
