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
    var mediaFolderURL: URL?
    
    @IBAction func radioButtonAction(_ sender: AnyObject) {
        
    }
    @IBAction func generalPressed(_ sender: AnyObject) {
        tabView.selectTabViewItem(at: 0)
    }
    
    @IBAction func playbackPressed(_ sender: AnyObject) {
        tabView.selectTabViewItem(at: 1)
    }
    
    @IBAction func sharingPressed(_ sender: AnyObject) {
        tabView.selectTabViewItem(at: 2)
    }
    
    @IBAction func libraryPressed(_ sender: AnyObject) {
        tabView.selectTabViewItem(at: 3)
    }
    
    @IBAction func advancedPressed(_ sender: AnyObject) {
        tabView.selectTabViewItem(at: 4)
    }
    
    @IBOutlet weak var browseButton: NSButton!
    
    @IBAction func organizationCheckAction(_ sender: AnyObject) {
        if organizeLibraryCheck.state == NSOnState {
            moveRadio.isEnabled = true
            copyRadio.isEnabled = true
            moveRadio.state = NSOnState
            browseButton.isEnabled = true
        } else {
            browseButton.isEnabled = false
            moveRadio.isEnabled = false
            copyRadio.isEnabled = false
            moveRadio.state = NSOffState
            copyRadio.state = NSOffState
        }
    }
    
    @IBAction func browseClicked(_ sender: AnyObject) {
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        myFileDialog.canChooseFiles = false
        myFileDialog.canChooseDirectories = true
        myFileDialog.runModal()
        
        // Get the path to the file chosen in the NSOpenPanel
        if myFileDialog.url!.path != nil {
            mediaFolderURL = myFileDialog.url!
            mediaFolderPath.stringValue = mediaFolderURL!.path
        }
    }

    func initializeFields() {
        let defaults = UserDefaults.standard
        
        libraryNameField.stringValue = defaults.string(forKey: DEFAULTS_LIBRARY_NAME_STRING) != nil ? defaults.string(forKey: DEFAULTS_LIBRARY_NAME_STRING)! : ""
        let organization = defaults.integer(forKey: DEFAULTS_LIBRARY_ORGANIZATION_TYPE_STRING)
        if organization == NO_ORGANIZATION_TYPE {
            organizeLibraryCheck.state = NSOffState
            mediaFolderPath.stringValue = ""
            browseButton.isEnabled = false
            moveRadio.isEnabled = false
            copyRadio.isEnabled = false
            organizationString.stringValue = LIBRARY_DOES_NOTHING_DESCRIPTION
        } else {
            browseButton.isEnabled = true
            moveRadio.isEnabled = true
            copyRadio.isEnabled = true
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
        
        let sharing = defaults.bool(forKey: DEFAULTS_SHARING_STRING)
        sharingCheck.state = sharing == true ? NSOnState : NSOffState
        
        let checkEmbedded = defaults.bool(forKey: DEFAULTS_CHECK_EMBEDDED_ARTWORK_STRING)
        checkEmbeddedArtworkCheck.state = checkEmbedded == true ? NSOnState : NSOffState
        
        let checkDir = defaults.bool(forKey: DEFAULTS_CHECK_ALBUM_DIRECTORY_FOR_ART_STRING)
        checkAlbumDirectoryCheck.state = checkDir == true ? NSOnState : NSOffState
        
        mediaFolderPath.stringValue = defaults.string(forKey: DEFAULTS_LIBRARY_PATH_STRING)!
        
        
    }
    @IBAction func cancelAction(_ sender: AnyObject) {
        print("cancel action on preferences")
        self.window?.close()
    }
    
    @IBAction func okAction(_ sender: AnyObject) {
        print("ok action on preferences")
        let defaults = UserDefaults.standard
        defaults.set(libraryNameField.stringValue, forKey: DEFAULTS_LIBRARY_NAME_STRING)
        let sharingBool = sharingCheck.state != 0
        let artBool = checkEmbeddedArtworkCheck.state != 0
        let artDirectoryBool = checkAlbumDirectoryCheck.state != 0
        defaults.set(sharingBool, forKey: DEFAULTS_SHARING_STRING)
        defaults.set(artBool, forKey: DEFAULTS_CHECK_EMBEDDED_ARTWORK_STRING)
        defaults.set(artDirectoryBool, forKey: DEFAULTS_CHECK_ALBUM_DIRECTORY_FOR_ART_STRING)
        if organizeLibraryCheck.state == NSOffState {
            defaults.set(NO_ORGANIZATION_TYPE, forKey: DEFAULTS_LIBRARY_ORGANIZATION_TYPE_STRING)
        } else {
            if mediaFolderPath.stringValue != "/" && mediaFolderPath.stringValue != "" {
                defaults.set(mediaFolderPath.stringValue, forKey: DEFAULTS_LIBRARY_PATH_STRING)
            }
            if moveRadio.state == NSOnState {
                defaults.set(MOVE_ORGANIZATION_TYPE, forKey: DEFAULTS_LIBRARY_ORGANIZATION_TYPE_STRING)
            } else if copyRadio.state == NSOnState {
                defaults.set(COPY_ORGANIZATION_TYPE, forKey: DEFAULTS_LIBRARY_ORGANIZATION_TYPE_STRING)
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
