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


enum LibraryOrganizationType: Int {
    case none, move, copy
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
        //create library
        let newActualLibrary = NSEntityDescription.insertNewObject(forEntityName: "Library", into: managedContext) as! Library
        newActualLibrary.initialSetup(withCentralDirectory: libraryPathControl.url!, organizationType: organizationType.rawValue, renamesFiles: modifyMetadata)
        let defaultVolume = NSEntityDescription.insertNewObject(forEntityName: "Volume", into: managedContext) as! Volume
        defaultVolume.location = getVolumeOfURL(url: libraryPathControl.url!).absoluteString
        defaultVolume.name = (try? libraryPathControl.url!.resourceValues(forKeys: [.volumeNameKey]))?.volumeName
        newActualLibrary.addToVolumes(defaultVolume)
        
        let newActualLibrarySLI = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        newActualLibrarySLI.library = newActualLibrary
        newActualLibrarySLI.name = newActualLibrary.name
        //create dummy source list item as root of source list
        let source_list_root = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        source_list_root.is_root = true
        
        //create SLI for default volume
        let defaultVolumeSLI = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        defaultVolumeSLI.volume = defaultVolume
        newActualLibrarySLI.addToChildren(defaultVolumeSLI)
        
        //create source list headers
        let cd_library_header = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        cd_library_header.is_header = true
        cd_library_header.name = "Library"
        cd_library_header.sort_order = 0
        cd_library_header.parent = source_list_root
        newActualLibrarySLI.parent = cd_library_header
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
        
        let cachedComposerOrder = NSEntityDescription.insertNewObject(forEntityName: "CachedOrder", into: managedContext) as! CachedOrder
        cachedComposerOrder.order = "Composer"
        
        //create blank entities
        let unknownArtist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: managedContext) as! Artist
        unknownArtist.id = 1
        unknownArtist.name = ""
        let unknownAlbum = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
        unknownAlbum.id = 1
        unknownAlbum.name = ""
        let unknownComposer = NSEntityDescription.insertNewObject(forEntityName: "Composer", into: managedContext) as! Composer
        unknownComposer.id = 1
        unknownComposer.name = ""
        
        //set IDs
        library?.next_album_id = 2
        library?.next_track_id = 1
        library?.next_artist_id = 2
        library?.next_genre_id = 1
        library?.next_composer_id = 2
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
        notEnablingUndo {
            UserDefaults.standard.setValuesForKeys(DEFAULTS_INITIAL_DEFAULTS)
            if self.library == nil {
                setupForNilLibrary()
            }
            (NSApplication.shared().delegate as! AppDelegate).initializeLibraryAndShowMainWindow()
            self.window?.close()
        }
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
                let libraryPath = result!.getCentralMediaFolder()!
                directoryURL = libraryPath
                libraryPathControl.url = libraryPath
            } else {
                libraryPathControl.url = jmcDirURL
            }
        } catch {
            print(error)
        }
        super.windowDidLoad()
    }
    
}
