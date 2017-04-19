//
//  InitialSetupWindowController.swift
//  minimalTunes
//
//  Created by John Moody on 7/11/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


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
    var directoryURL: URL?
    var library: Library?
    
    @IBAction func moveRadioAction(_ sender: AnyObject) {
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
    
    @IBAction func browseClicked(_ sender: AnyObject) {
        openFile()
    }
    @IBAction func modifyCheckBoxToggled(_ sender: AnyObject) {
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
        if myFileDialog.url!.path != nil {
            directoryURL = myFileDialog.url!
            libraryPathControl.url = directoryURL
        }
        
        // Make sure that a path was chosen
    }
    
    func setupForNilLibrary() {
        print("nil library")
        //create glob root library
        let newLibrary = NSEntityDescription.insertNewObject(forEntityName: "Library", into: managedContext) as! Library
        newLibrary.name = NSFullUserName() + "'s library"
        newLibrary.parent = nil
        //create actual library
        let newActualLibrary = NSEntityDescription.insertNewObject(forEntityName: "Library", into: managedContext) as! Library
        newActualLibrary.library_location = libraryPathControl.url!.absoluteString
        newActualLibrary.name = libraryPathControl.url?.lastPathComponent
        newActualLibrary.parent = newLibrary
        newActualLibrary.is_active = true
        newActualLibrary.renames_files = modifyMetadata as NSNumber
        newActualLibrary.keeps_track_of_files = true
        var urlArray = [URL]()
        urlArray.append(libraryPathControl.url!)
        newActualLibrary.watch_dirs = urlArray as NSArray
        newActualLibrary.monitors_directories_for_new = false
        newActualLibrary.organization_type = organizationType.rawValue as NSNumber
        let newActualLibrarySLI = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        newActualLibrarySLI.library = newActualLibrary
        newActualLibrarySLI.name = newActualLibrary.name
        //create dummy source list item as root of source list
        let source_list_root = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        source_list_root.is_root = true
        
        //create source list headers
        let cd_library_header = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        cd_library_header.is_header = true
        cd_library_header.name = "Library"
        cd_library_header.sort_order = 0
        cd_library_header.parent = source_list_root
        let cd_shared_header = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        cd_shared_header.is_header = true
        cd_shared_header.name = "Shared Libraries"
        cd_shared_header.sort_order = 1
        cd_shared_header.parent = source_list_root
        let cd_playlists_header = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        cd_playlists_header.is_header = true
        cd_playlists_header.name = "Playlists"
        cd_playlists_header.sort_order = 2
        cd_playlists_header.parent = source_list_root
        
        //create master playlist source list item
        let cd_library_master_playlist_source_item = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        cd_library_master_playlist_source_item.parent = cd_library_header
        cd_library_master_playlist_source_item.name = "Music"
        cd_library_master_playlist_source_item.library = newLibrary
        
        newActualLibrarySLI.parent = cd_library_master_playlist_source_item
        
        //create cached orders
        let cachedArtistOrder = NSEntityDescription.insertNewObject(forEntityName: "CachedOrder", into: managedContext) as! CachedOrder
        cachedArtistOrder.order = "Artist"
        
        let cachedAlbumOrder = NSEntityDescription.insertNewObject(forEntityName: "CachedOrder", into: managedContext) as! CachedOrder
        cachedAlbumOrder.order = "Album"
        
        let dateAddedOrder = NSEntityDescription.insertNewObject(forEntityName: "CachedOrder", into: managedContext) as! CachedOrder
        dateAddedOrder.order = "Date Added"
        
        let cachedAlbumArtistOrder = NSEntityDescription.insertNewObject(forEntityName: "CachedOrder", into: managedContext) as! CachedOrder
        cachedAlbumArtistOrder.order = "Album Artist"

        let cachedKindOrder = NSEntityDescription.insertNewObject(forEntityName: "CachedOrder", into: managedContext) as! CachedOrder
        cachedKindOrder.order = "Kind"
        
        let cachedDateReleasedOrder = NSEntityDescription.insertNewObject(forEntityName: "CachedOrder", into: managedContext) as! CachedOrder
        cachedDateReleasedOrder.order = "Date Released"
        
        let cachedGenreOrder = NSEntityDescription.insertNewObject(forEntityName: "CachedOrder", into: managedContext) as! CachedOrder
        cachedGenreOrder.order = "Genre"
        
        let cachedNameOrder = NSEntityDescription.insertNewObject(forEntityName: "CachedOrder", into: managedContext) as! CachedOrder
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
    
    @IBAction func OKPressed(_ sender: AnyObject) {
        UserDefaults.standard.set(true, forKey: DEFAULTS_ARE_INITIALIZED_STRING)

        UserDefaults.standard.set(false, forKey: DEFAULTS_SHUFFLE_STRING)
        UserDefaults.standard.set(1.0, forKey: DEFAULTS_VOLUME_STRING)
        UserDefaults.standard.set(1, forKey: DEFAULTS_IS_EQ_ENABLED_STRING)
        
        UserDefaults.standard.set(true, forKey: DEFAULTS_CHECK_ALBUM_DIRECTORY_FOR_ART_STRING)
        UserDefaults.standard.set(true, forKey: DEFAULTS_SHARING_STRING)
        if self.library == nil {
            setupForNilLibrary()
        }
        (NSApplication.shared().delegate as! AppDelegate).initializeLibraryAndShowMainWindow()
        self.window?.close()
    }
    
    override func windowDidLoad() {
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        moveRadioAction(self)
        do {
            let userMusicDirURL = try FileManager.default.url(for: .musicDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let jmcDirURL = userMusicDirURL.appendingPathComponent("jmc", isDirectory: true)
            try FileManager.default.createDirectory(atPath: jmcDirURL.path, withIntermediateDirectories: true, attributes: nil)
            let libraryFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Library")
            let predicate = NSPredicate(format: "is_network == false or is_network == nil")
            libraryFetchRequest.predicate = predicate
            var result: Library?
            do {
                let libraryResult = try managedContext.fetch(libraryFetchRequest) as? [Library]
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
                    let libraryURL = URL(string: libraryPath!)
                    if libraryURL != nil {
                        directoryURL = libraryURL
                        libraryPathControl.url = libraryURL
                    }
                }
            } else {
                libraryPathControl.url = jmcDirURL
            }
        } catch {
            print(error)
        }
        super.windowDidLoad()
    }
    
}
