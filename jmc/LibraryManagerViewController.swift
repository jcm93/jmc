//
//  LibraryManagerViewController.swift
//  jmc
//
//  Created by John Moody on 2/13/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa
import DiskArbitration
import IOKit

class TrackNotFound: NSObject {
    var path: String?
    let track: Track
    var trackDescription: String
    init(path: String?, track: Track) {
        self.path = path
        self.track = track
        self.trackDescription = "\(track.artist?.name) - \(track.album?.name) - \(track.name)"
    }
}

class NewMediaURL: NSObject {
    let url: URL
    var toImport: Bool
    init(url: URL) {
        self.url = url
        self.toImport = true
    }
}

class LibraryManagerViewController: NSViewController, NSTableViewDelegate, NSTabViewDelegate {
    
    var fileManager = FileManager.default
    var databaseManager = DatabaseManager()
    var locationManager = (NSApplication.shared().delegate as! AppDelegate).locationManager!
    var library: Library?
    var missingTracks: [Track]?
    var newMediaURLs: [URL]?
    var delegate: AppDelegate?
    var watchFolders = [URL]()

    @IBOutlet weak var findNewMediaTabItem: NSTabViewItem!
    @IBOutlet weak var locationManagerTabItem: NSTabViewItem!
    
    //data controllers
    @IBOutlet var tracksNotFoundArrayController: NSArrayController!
    @IBOutlet var newTracksArrayController: NSArrayController!
    @IBOutlet var watchFoldersArrayController: NSArrayController!
    
    //source information elements
    @IBOutlet weak var watchFolderTableView: NSTableView!
    @IBOutlet weak var sourceNameField: NSTextField!
    @IBOutlet weak var sourceLocationStatusImage: NSImageView!
    @IBOutlet weak var sourceLocationStatusTextField: NSTextField!
    @IBOutlet weak var sourceMonitorStatusImageView: NSImageView!
    @IBOutlet weak var sourceMonitorStatusTextField: NSTextField!
    @IBOutlet weak var sourceLocationField: NSPathControl!
    @IBOutlet weak var doesOrganizeCheck: NSButton!
    @IBOutlet weak var moveRadio: NSButton!
    @IBOutlet weak var copyRadio: NSButton!
    @IBOutlet weak var changeLocationButton: NSButton!
    @IBOutlet weak var addWatchFolderButton: NSButton!
    @IBOutlet weak var removeWatchFolderButton: NSButton!
    @IBOutlet weak var mediaAddBehaviorLabel: NSTextField!
    @IBOutlet weak var consolidateLibraryButton: NSButton!
    @IBOutlet weak var watchFoldersLabel: NSTextField!
    @IBOutlet weak var fileMonitorDescriptionLabel: NSTextField!
    
    @IBOutlet weak var automaticallyAddFilesCheck: NSButton!
    @IBOutlet weak var enableDirectoryMonitoringCheck: NSButton!
    
    @IBAction func removeSourceButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func enableMonitoringCheckAction(_ sender: Any) {
        if enableDirectoryMonitoringCheck.state == NSOnState {
            library?.keeps_track_of_files = true as NSNumber
            sourceMonitorStatusImageView.image = NSImage(named: "NSStatusAvailable")
            sourceMonitorStatusTextField.stringValue = "Directory monitoring is enabled."
        } else {
            library?.keeps_track_of_files = false as NSNumber
            sourceMonitorStatusImageView.image = NSImage(named: "NSStatusUnavailable")
            sourceMonitorStatusTextField.stringValue = "Directory monitoring inactive."
        }
        initializeForLibrary(library: library!)
        self.locationManager.reinitializeEventStream()
        
    }
    @IBAction func automaticallyAddCheckAction(_ sender: Any) {
        library?.monitors_directories_for_new = automaticallyAddFilesCheck.state == NSOnState ? true as NSNumber : false as NSNumber
        if automaticallyAddFilesCheck.state == NSOnState {
            self.watchFolderTableView.isEnabled = true
            self.addWatchFolderButton.isEnabled = true
            self.removeWatchFolderButton.isEnabled = true
            self.watchFolderTableView.tableColumns[0].isHidden = false
            if let watchDirs = library?.watch_dirs as? NSArray {
                self.watchFolders = watchDirs as! [URL]
                self.watchFoldersArrayController.content = self.watchFolders
            }
        } else {
            self.watchFolderTableView.isEnabled = false
            self.addWatchFolderButton.isEnabled = false
            self.removeWatchFolderButton.isEnabled = false
            self.watchFolderTableView.tableColumns[0].isHidden = true
        }
        locationManager.reinitializeEventStream()
    }
    @IBAction func sourceNameWasEdited(_ sender: Any) {
        if let textField = sender as? NSTextField, textField.stringValue != "" {
            library?.name = textField.stringValue
            initializeForLibrary(library: library!)
        }
    }
    
    func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        if libraryIsAvailable(library: self.library!) {
            return true
        } else {
            if tabViewItem! == locationManagerTabItem || tabViewItem! == findNewMediaTabItem {
                return false
            } else {
                return true
            }
        }
    }
    @IBAction func changeSourceLocationButtonPressed(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        let response = openPanel.runModal()
        if response == NSFileHandlingPanelOKButton {
            let newURL = openPanel.urls[0]
            changeLibraryLocation(library: self.library!, newLocation: newURL)
            initializeForLibrary(library: self.library!)
        }
    }
    
    @IBAction func orgBehaviorChecked(_ sender: Any) {
        if doesOrganizeCheck.state == NSOffState {
            library?.organization_type = NO_ORGANIZATION_TYPE as NSNumber
            moveRadio.isEnabled = false
            copyRadio.isEnabled = false
        } else {
            moveRadio.isEnabled = true
            copyRadio.isEnabled = true
            orgBehaviorRadioAction(self)
        }
    }
    @IBAction func orgBehaviorRadioAction(_ sender: Any) {
        if moveRadio.state == NSOnState {
            library?.organization_type = MOVE_ORGANIZATION_TYPE as NSNumber
        } else {
            library?.organization_type = COPY_ORGANIZATION_TYPE as NSNumber
        }
    }
    
    @IBAction func addWatchFolderPressed(_ sender: Any) {
        let parent = self.view.window?.windowController as! LibraryManagerSourceSelector
        parent.watchFolderSheet = AddWatchFolderSheetController(windowNibName: "AddWatchFolderSheetController")
        parent.watchFolderSheet?.libraryManager = self
        parent.window?.beginSheet(parent.watchFolderSheet!.window!, completionHandler: nil)
    }
    
    func addWatchFolder(_ watchFolder: URL) {
        watchFoldersArrayController.addObject(watchFolder)
        var currentLibraryWatchDirs = self.library?.watch_dirs as? [URL] ?? [URL]()
        currentLibraryWatchDirs.append(watchFolder)
        self.library?.watch_dirs = currentLibraryWatchDirs as NSArray
        self.locationManager.reinitializeEventStream()
    }
    
    @IBAction func removeWatchFolderPressed(_ sender: Any) {
        guard watchFoldersArrayController.selectedObjects.count > 0 else {return}
        let watchFolder = watchFoldersArrayController.selectedObjects[0] as! URL
        self.removeWatchFolder(watchFolder)
    }
    
    func removeWatchFolder(_ watchFolder: URL) {
        watchFoldersArrayController.removeObject(watchFolder)
        var currentLibraryWatchDirs = self.library?.watch_dirs as? [URL] ?? [URL]()
        currentLibraryWatchDirs.remove(at: currentLibraryWatchDirs.index(of: watchFolder)!)
        self.library?.watch_dirs = currentLibraryWatchDirs as NSObject
        self.locationManager.reinitializeEventStream()
    }
    
    @IBAction func consolidateLibraryPressed(_ sender: Any) {
        
    }
    
    func initializeForLibrary(library: Library) {
        print("init for \(library.name)")
        self.library = library
        sourceNameField.stringValue = library.name!
        let sourceLocationURL = URL(string: library.library_location!)!
        sourceLocationField.stringValue = sourceLocationURL.path
        let libraryWasAvailable = library.is_available
        let libraryIsNowAvailable = libraryIsAvailable(library: library)
        if libraryIsNowAvailable {
            doesOrganizeCheck.isEnabled = true
            moveRadio.isEnabled = true
            copyRadio.isEnabled = true
            sourceLocationField.isEnabled = true
            automaticallyAddFilesCheck.isEnabled = true
            watchFolderTableView.isEnabled = true
            addWatchFolderButton.isEnabled = true
            removeWatchFolderButton.isEnabled = true
            enableDirectoryMonitoringCheck.isEnabled = true
            mediaAddBehaviorLabel.isEnabled = true
            consolidateLibraryButton.isEnabled = true
            watchFoldersLabel.isEnabled = true
            fileMonitorDescriptionLabel.isEnabled = true
            sourceMonitorStatusTextField.isEnabled = true
            sourceLocationStatusImage.image = NSImage(named: "NSStatusAvailable")
            sourceLocationStatusTextField.stringValue = "Source is located and available."
            enableDirectoryMonitoringCheck.isEnabled = true
            if library.organization_type != nil && Int(library.organization_type!) != NO_ORGANIZATION_TYPE {
                self.doesOrganizeCheck.state = NSOnState
                if Int(library.organization_type!) == MOVE_ORGANIZATION_TYPE {
                    self.moveRadio.state = NSOnState
                    self.copyRadio.state = NSOffState
                } else {
                    self.moveRadio.state = NSOffState
                    self.copyRadio.state = NSOnState
                }
            } else {
                self.doesOrganizeCheck.state = NSOffState
                self.orgBehaviorChecked(self)
            }
            self.automaticallyAddFilesCheck.isEnabled = true
            if library.monitors_directories_for_new == true {
                self.automaticallyAddFilesCheck.state = NSOnState
                self.watchFolderTableView.tableColumns[0].isHidden = false
                if let watchDirs = library.watch_dirs as? NSArray {
                    self.watchFolders = watchDirs as! [URL]
                    self.watchFoldersArrayController.content = self.watchFolders
                }
                self.addWatchFolderButton.isEnabled = true
                self.removeWatchFolderButton.isEnabled = true
            } else if library.monitors_directories_for_new == false {
                self.automaticallyAddFilesCheck.state = NSOffState
                self.watchFolderTableView.isEnabled = false
                self.watchFolderTableView.tableColumns[0].isHidden = true
                self.addWatchFolderButton.isEnabled = false
                self.removeWatchFolderButton.isEnabled = false
            }
            if library.keeps_track_of_files == true {
                self.enableDirectoryMonitoringCheck.state = NSOnState
                sourceMonitorStatusImageView.image = NSImage(named: "NSStatusAvailable")
                sourceMonitorStatusTextField.stringValue = "Directory monitoring is enabled."
            } else if library.keeps_track_of_files == false {
                self.enableDirectoryMonitoringCheck.state = NSOffState
                sourceMonitorStatusImageView.image = NSImage(named: "NSStatusUnavailable")
                sourceMonitorStatusTextField.stringValue = "Directory monitoring inactive."
            }
        } else {
            //library isn't located. disable everything
            doesOrganizeCheck.isEnabled = false
            moveRadio.isEnabled = false
            copyRadio.isEnabled = false
            sourceLocationField.isEnabled = false
            automaticallyAddFilesCheck.isEnabled = false
            watchFolderTableView.isEnabled = false
            addWatchFolderButton.isEnabled = false
            removeWatchFolderButton.isEnabled = false
            mediaAddBehaviorLabel.isEnabled = false
            consolidateLibraryButton.isEnabled = false
            watchFoldersLabel.isEnabled = false
            fileMonitorDescriptionLabel.isEnabled = false
            sourceMonitorStatusTextField.isEnabled = false
            sourceLocationStatusImage.image = NSImage(named: "NSStatusUnavailable")
            sourceLocationStatusTextField.stringValue = "Source cannot be located."
            enableDirectoryMonitoringCheck.isEnabled = false
            sourceMonitorStatusTextField.stringValue = "Directory monitoring inactive."
            sourceMonitorStatusImageView.image = NSImage(named: "NSStatusUnavailable")
        }
        if libraryIsNowAvailable != (libraryWasAvailable as? Bool) {
            delegate?.mainWindowController?.sourceListViewController?.reloadData()
        }
    }
    
    //location manager
    @IBOutlet weak var lostTracksTableView: NSTableView!
    @IBOutlet weak var trackLocationStatusText: NSTextField!
    @IBOutlet weak var verifyLocationsButton: NSButton!
    @IBOutlet weak var libraryLocationStatusImageView: NSImageView!
    
    @IBAction func verifyLocationsPressed(_ sender: Any) {
        let parent = self.view.window?.windowController as! LibraryManagerSourceSelector
        parent.verifyLocationsSheet = LocationVerifierSheetController(windowNibName: "LocationVerifierSheetController")
        parent.window?.beginSheet(parent.verifyLocationsSheet!.window!, completionHandler: verifyLocationsModalComplete)
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            self.missingTracks = self.databaseManager.verifyTrackLocations(visualUpdateHandler: parent.verifyLocationsSheet, library: self.library!)
            DispatchQueue.main.async {
                self.verifyLocationsModalComplete(response: 1)
            }
        }
    }
    
    func verifyLocationsModalComplete(response: NSModalResponse) {
        guard response != NSModalResponseCancel else {return}
        if self.missingTracks!.count > 0 {
            let trackNotFoundArray = self.missingTracks!.map({(track: Track) -> TrackNotFound in
                if let location = track.location {
                    if let url = URL(string: location) {
                        return TrackNotFound(path: url.path, track: track)
                    } else {
                        return TrackNotFound(path: location, track: track)
                    }
                } else {
                    return TrackNotFound(path: nil, track: track)
                }
            })
            self.libraryLocationStatusImageView.image = NSImage(named: "NSStatusPartiallyAvailable")
            self.trackLocationStatusText.stringValue = "\(self.missingTracks!.count) tracks not found."
            tracksNotFoundArrayController.content = trackNotFoundArray
        } else {
            self.libraryLocationStatusImageView.image = NSImage(named: "NSStatusAvailable")
            self.trackLocationStatusText.stringValue = "All tracks located."
        }
    }
    
    @IBAction func locateTrackButtonPressed(_ sender: Any) {
        print("locate pressed")
        let row = lostTracksTableView.row(for: (sender as! NSButton).superview as! NSTableCellView)
        let trackContainer = (tracksNotFoundArrayController.arrangedObjects as! [TrackNotFound])[row]
        let track = trackContainer.track
        let fileDialog = NSOpenPanel()
        fileDialog.allowsMultipleSelection =  false
        fileDialog.canChooseDirectories = false
        fileDialog.allowedFileTypes = VALID_FILE_TYPES
        fileDialog.runModal()
        if fileDialog.urls.count > 0 {
            let url = fileDialog.urls[0]
            track.location = url.absoluteString
            tracksNotFoundArrayController.removeObject(trackContainer)
            databaseManager.fixInfoForTrack(track: track)
            missingTracks!.remove(at: missingTracks!.index(of: track)!)
            lostTracksTableView.reloadData()
        }
    }
    
    //dir scanner
    @IBOutlet weak var newMediaTableView: NSTableView!
    @IBOutlet weak var dirScanStatusTextField: NSTextField!
    @IBOutlet weak var directoryPicker: NSPopUpButton!
    
    @IBAction func scanSourceButtonPressed(_ sender: Any) {
        let parent = self.view.window?.windowController as! LibraryManagerSourceSelector
        parent.mediaScannerSheet = MediaScannerSheet(windowNibName: "MediaScannerSheet")
        parent.window?.beginSheet(parent.mediaScannerSheet!.window!, completionHandler: scanMediaModalComplete)
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            self.newMediaURLs = self.databaseManager.scanForNewMedia(visualUpdateHandler: parent.mediaScannerSheet, library: self.library!)
            DispatchQueue.main.async {
                self.scanMediaModalComplete(response: 1)
            }
        }
    }
    
    func scanMediaModalComplete(response: NSModalResponse) {
        if self.newMediaURLs!.count > 0{
            newTracksArrayController.content = self.newMediaURLs!.map({return NewMediaURL(url: $0)})
            
            dirScanStatusTextField.stringValue = "\(self.newMediaURLs!.count) new media files found."
            newMediaTableView.reloadData()
        } else {
            dirScanStatusTextField.stringValue = "No new media found."
        }
    }
    
    @IBAction func importSelectedPressed(_ sender: Any) {
        let mediaURLsToAdd = (newTracksArrayController.arrangedObjects as! [NewMediaURL]).filter({return $0.toImport == true}).map({return $0.url})
        let errors = databaseManager.addTracksFromURLs(mediaURLsToAdd, to: self.library!, visualUpdateHandler: nil)
        for url in mediaURLsToAdd {
            newMediaURLs!.remove(at: newMediaURLs!.index(of: url)!)
        }
        newTracksArrayController.content = self.newMediaURLs!.map({return NewMediaURL(url: $0)})
        newMediaTableView.reloadData()
    }
    
    @IBAction func selectAllPressed(_ sender: Any) {
        for trackContainer in (newTracksArrayController.arrangedObjects as! [NewMediaURL]) {
            trackContainer.toImport = true
        }
        newMediaTableView.reloadData()
    }
    
    @IBAction func selectNonePressed(_ sender: Any) {
        for trackContainer in (newTracksArrayController.arrangedObjects as! [NewMediaURL]) {
            trackContainer.toImport = false
        }
        newMediaTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
