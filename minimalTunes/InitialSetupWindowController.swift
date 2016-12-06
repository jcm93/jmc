//
//  InitialSetupWindowController.swift
//  minimalTunes
//
//  Created by John Moody on 7/11/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

public enum LibraryOrganizationType: Int {
    case move = 1
    case copy = 2
    case none = 0
}

class InitialSetupWindowController: NSWindowController {

    @IBOutlet weak var moveRadioButton: NSButton!
    @IBOutlet weak var copyRadioButton: NSButton!
    @IBOutlet weak var noOrganizeRadioButton: NSButton!
    @IBOutlet weak var modifyMetadataCheckBox: NSButton!
    @IBOutlet weak var organizationDescField: NSTextField!
    @IBOutlet weak var libraryPathControl: NSPathControl!
    
    var organizationType: LibraryOrganizationType = .move
    var modifyMetadata: Bool = false
    var directoryURL: NSURL?
    var moveString = "Added media will be moved into a subdirectory of this directory"
    var copyString = "Added media will be copied into a subdirectory of this directory"
    var noString = "Added media will not be organized"
    var library: Library?
    
    @IBAction func moveRadioAction(sender: AnyObject) {
        if moveRadioButton.state == NSOnState {
            organizationType = .move
            organizationDescField.stringValue = moveString
        }
        else if copyRadioButton.state == NSOnState {
            organizationType = .copy
            organizationDescField.stringValue = copyString
        }
        else if noOrganizeRadioButton.state == NSOnState {
            organizationType = .none
            organizationDescField.stringValue = noString
        }
    }
    
    @IBAction func browseClicked(sender: AnyObject) {
        openFile()
    }
    @IBAction func modifyCheckBoxToggled(sender: AnyObject) {
        if modifyMetadataCheckBox.state == NSOnState {
            modifyMetadata = true
        }
        else {
            modifyMetadata = false
        }
    }
    
    func openFile() {
        
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        myFileDialog.canChooseFiles = false
        myFileDialog.canChooseDirectories = true
        myFileDialog.runModal()
        
        // Get the path to the file chosen in the NSOpenPanel
        if myFileDialog.URL!.path != nil {
            directoryURL = myFileDialog.URL!
            libraryPathControl.URL = directoryURL
        }
        
        // Make sure that a path was chosen
        if (directoryURL != nil) {
            let err = NSError?()
        }
    }
    
    func setupForNilLibrary() {
        print("nil library")
        let newLibrary = NSEntityDescription.insertNewObjectForEntityForName("Library", inManagedObjectContext: managedContext) as! Library
        newLibrary.library_location = libraryPathControl.URL!.absoluteString
        newLibrary.name = NSUserName() + "'s library"
        //create dummy source list item as root of source list
        let source_list_root = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
        source_list_root.is_root = true
        
        //create source list headers
        let cd_library_header = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
        cd_library_header.is_header = true
        cd_library_header.name = "Library"
        cd_library_header.sort_order = 0
        cd_library_header.parent = source_list_root
        let cd_shared_header = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
        cd_shared_header.is_header = true
        cd_shared_header.name = "Shared Libraries"
        cd_shared_header.sort_order = 1
        cd_shared_header.parent = source_list_root
        let cd_playlists_header = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
        cd_playlists_header.is_header = true
        cd_playlists_header.name = "Playlists"
        cd_playlists_header.sort_order = 2
        cd_playlists_header.parent = source_list_root
        
        //create master playlist source list item
        let cd_library_master_playlist_source_item = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
        cd_library_master_playlist_source_item.parent = cd_library_header
        cd_library_master_playlist_source_item.name = "Music"
        cd_library_master_playlist_source_item.library = newLibrary
        do {
            try managedContext.save()
        } catch {
            print(error)
        }
    }
    
    @IBAction func OKPressed(sender: AnyObject) {
        self.window?.close()
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: DEFAULTS_ARE_INITIALIZED_STRING)
        NSUserDefaults.standardUserDefaults().setBool(modifyMetadata, forKey: DEFAULTS_RENAMES_FILES_STRING)
        NSUserDefaults.standardUserDefaults().setObject(organizationType.rawValue, forKey: DEFAULTS_LIBRARY_ORGANIZATION_TYPE_STRING)
        NSUserDefaults.standardUserDefaults().setObject(directoryURL?.absoluteString, forKey: DEFAULTS_LIBRARY_PATH_STRING)
        if self.library == nil {
            setupForNilLibrary()
        }
        (NSApplication.sharedApplication().delegate as! AppDelegate).initializeLibraryAndShowMainWindow()
    }
    
    override func windowDidLoad() {
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        moveRadioAction(self)
        let libraryFetchRequest = NSFetchRequest(entityName: "Library")
        let predicate = NSPredicate(format: "is_network == false")
        libraryFetchRequest.predicate = predicate
        var result: Library?
        do {
            let libraryResult = try managedContext.executeFetchRequest(libraryFetchRequest) as? [Library]
            if libraryResult?.count > 0 {
                result = libraryResult![0]
            }
        } catch {
            print(error)
        }
        if result != nil {
            library = result!
            let libraryPath = result!.library_location
            if libraryPath != nil {
                let libraryURL = NSURL(string: libraryPath!)
                if libraryURL != nil {
                    directoryURL = libraryURL
                    libraryPathControl.URL = libraryURL
                }
            }
        }
        super.windowDidLoad()
    }
    
}
