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
    var library: Library?
    
    @IBAction func moveRadioAction(sender: AnyObject) {
        if moveRadioButton.state == NSOnState {
            organizationType = .move
            organizationDescField.stringValue = LIBRARY_MOVES_DESCRIPTION
        }
        else if copyRadioButton.state == NSOnState {
            organizationType = .copy
            organizationDescField.stringValue = LIBRARY_COPIES_DESCRIPTION
        }
        else if noOrganizeRadioButton.state == NSOnState {
            organizationType = .none
            organizationDescField.stringValue = LIBRARY_DOES_NOTHING_DESCRIPTION
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
        
        //create cached orders
        let cachedArtistOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: managedContext) as! CachedOrder
        cachedArtistOrder.order = "Artist"
        
        let cachedAlbumOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: managedContext) as! CachedOrder
        cachedAlbumOrder.order = "Album"
        
        let dateAddedOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: managedContext) as! CachedOrder
        dateAddedOrder.order = "Date Added"
        
        let cachedAlbumArtistOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: managedContext) as! CachedOrder
        cachedAlbumArtistOrder.order = "Album Artist"

        let cachedKindOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: managedContext) as! CachedOrder
        cachedKindOrder.order = "Kind"
        
        let cachedDateReleasedOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: managedContext) as! CachedOrder
        cachedDateReleasedOrder.order = "Date Released"
        
        let cachedGenreOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: managedContext) as! CachedOrder
        cachedGenreOrder.order = "Genre"
        
        let cachedNameOrder = NSEntityDescription.insertNewObjectForEntityForName("CachedOrder", inManagedObjectContext: managedContext) as! CachedOrder
        cachedNameOrder.order = "Name"
        
        //set IDs
        library?.next_album_id = 1
        library?.next_track_id = 1
        library?.next_artist_id = 1
        library?.next_genre_id = 1
        library?.next_composer_id = 1
        library?.next_playlist_id = 1
        library?.next_album_artwork_id = 1
        library?.next_album_artwork_collection_id = 1
        
        do {
            try managedContext.save()
        } catch {
            print(error)
        }
    }
    
    @IBAction func OKPressed(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: DEFAULTS_ARE_INITIALIZED_STRING)
        NSUserDefaults.standardUserDefaults().setBool(modifyMetadata, forKey: DEFAULTS_RENAMES_FILES_STRING)
        NSUserDefaults.standardUserDefaults().setObject(organizationType.rawValue, forKey: DEFAULTS_LIBRARY_ORGANIZATION_TYPE_STRING)
        NSUserDefaults.standardUserDefaults().setObject(directoryURL?.path, forKey: DEFAULTS_LIBRARY_PATH_STRING)
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: DEFAULTS_SHUFFLE_STRING)
        NSUserDefaults.standardUserDefaults().setFloat(1.0, forKey: DEFAULTS_VOLUME_STRING)
        NSUserDefaults.standardUserDefaults().setInteger(1, forKey: DEFAULTS_IS_EQ_ENABLED_STRING)
        NSUserDefaults.standardUserDefaults().setObject("\(NSFullUserName())'s Library", forKey: DEFAULTS_LIBRARY_NAME_STRING)
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: DEFAULTS_CHECK_ALBUM_DIRECTORY_FOR_ART_STRING)
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: DEFAULTS_SHARING_STRING)
        if self.library == nil {
            setupForNilLibrary()
        }
        (NSApplication.sharedApplication().delegate as! AppDelegate).initializeLibraryAndShowMainWindow()
        self.window?.close()
    }
    
    override func windowDidLoad() {
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        moveRadioAction(self)
        let libraryFetchRequest = NSFetchRequest(entityName: "Library")
        let predicate = NSPredicate(format: "is_network == false or is_network == nil")
        libraryFetchRequest.predicate = predicate
        var result: Library?
        do {
            let libraryResult = try managedContext.executeFetchRequest(libraryFetchRequest) as? [Library]
            if libraryResult?.count > 0 {
                print("has library")
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
