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
    
    @IBOutlet weak var tabView: NSTabView!
    var fileManager = FileManager.default
    var databaseManager = DatabaseManager()
    var locationManager = (NSApplication.shared().delegate as! AppDelegate).locationManager!
    var library: Library?
    var missingTracks: [Track]?
    var newMediaURLs: [URL]?
    var delegate: AppDelegate?
    var watchFolders = [URL]()
    var advancedOrganizationOptionsWindowController: AdvancedOrganizationOptionsWindowController?
    var missingFilesViewController: MissingFilesViewController?

    @IBOutlet weak var findNewMediaTabItem: NSTabViewItem!
    @IBOutlet weak var locationManagerTabItem: NSTabViewItem!
    
    //data controllers
    @IBOutlet var tracksNotFoundArrayController: NSArrayController!
    @IBOutlet var newTracksArrayController: NSArrayController!
    @IBOutlet var watchFoldersArrayController: NSArrayController!
    
    //source information elements
    @IBOutlet weak var watchFolderTableView: NSTableView!
    @IBOutlet weak var sourceNameField: NSTextField!
    @IBOutlet weak var sourceMonitorStatusImageView: NSImageView!
    @IBOutlet weak var sourceMonitorStatusTextField: NSTextField!
    @IBOutlet weak var sourceLocationField: JMPathControl!
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
        library!.monitors_directories_for_new = automaticallyAddFilesCheck.state == NSOnState ? true as NSNumber : false as NSNumber
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
            do {
                try managedContext.save()
            } catch {
                print(error)
            }
            initializeForLibrary(library: library!)
        }
    }
    
    @IBAction func changeSourceCentralMediaFolderButtonPressed(_ sender: Any) {
        let parent = self.view.window?.windowController as! PreferencesWindowController
        parent.changeFolderSheet = ChangePrimaryFolderSheetController(windowNibName: "ChangePrimaryFolderSheetController")
        parent.changeFolderSheet?.libraryManager = self
        parent.window?.beginSheet(parent.changeFolderSheet!.window!, completionHandler: nil)
        
    }
    
    @IBAction func changeSourceLocationButtonPressed(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        let response = openPanel.runModal()
        if response == NSFileHandlingPanelOKButton {
            let newURL = openPanel.urls[0]
            library?.changeCentralFolderLocation(newURL: newURL)
            locationManager.reinitializeEventStream()
            initializeForLibrary(library: self.library!)
        }
    }
    @IBAction func advancedOrganizationPressed(_ sender: Any) {
        self.advancedOrganizationOptionsWindowController = AdvancedOrganizationOptionsWindowController(windowNibName: "AdvancedOrganizationOptionsWindowController")
        self.view.window?.addChildWindow(self.advancedOrganizationOptionsWindowController!.window!, ordered: .above)
    }
    
    @IBAction func orgBehaviorChecked(_ sender: Any) {
        if doesOrganizeCheck.state == NSOffState {
            library?.organization_type = NO_ORGANIZATION_TYPE as NSNumber
            moveRadio.isEnabled = false
            copyRadio.isEnabled = false
            changeLocationButton.isEnabled = false
        } else {
            moveRadio.isEnabled = true
            copyRadio.isEnabled = true
            changeLocationButton.isEnabled = true
            sourceLocationField.url = library?.getCentralMediaFolder()
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
        let parent = self.view.window?.windowController as! PreferencesWindowController
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
        let parent = self.view.window?.windowController as! PreferencesWindowController
        parent.someOtherSheet = GenericProgressBarSheetController(windowNibName: "GenericProgressBarSheetController")
        parent.window?.beginSheet(parent.someOtherSheet!.window!, completionHandler: nil)
        DispatchQueue.global(qos: .default).async {
            let things = getNonMatchingTracks(library: globalRootLibrary!, visualUpdateHandler: parent.someOtherSheet)
            DispatchQueue.main.async {
                parent.someOtherSheet?.finish()
                parent.consolidateSheet = ConsolidateLibrarySheetController(windowNibName: "ConsolidateLibrarySheetController")
                parent.consolidateSheet?.things = things
                parent.window?.beginSheet(parent.consolidateSheet!.window!, completionHandler: nil)
                parent.consolidateSheet?.libraryManager = self
            }
        }
    }
    
    func initializeForLibrary(library: Library) {
        print("init for \(library.name)")
        self.library = library
        sourceNameField.stringValue = library.name!
        if let centralMediaFolderURL = library.getCentralMediaFolder() {
            sourceLocationField.url = centralMediaFolderURL
        }
        if library.organization_type != nil && library.organization_type != 0 {
            copyRadio.isEnabled = true
            moveRadio.isEnabled = true
            changeLocationButton.isEnabled = true
            doesOrganizeCheck.state = NSOnState
            if library.organization_type?.intValue == MOVE_ORGANIZATION_TYPE {
                moveRadio.state = NSOnState
            } else if library.organization_type?.intValue == COPY_ORGANIZATION_TYPE {
                copyRadio.state = NSOnState
            }
        } else {
            doesOrganizeCheck.state = NSOffState
            copyRadio.isEnabled = false
            moveRadio.isEnabled = false
            changeLocationButton.isEnabled = false
        }
        if library.monitors_directories_for_new == true {
            automaticallyAddFilesCheck.state = NSOnState
            if let watchDirs = library.watch_dirs as? [URL] {
                self.watchFolders = watchDirs
                self.watchFoldersArrayController.content = self.watchFolders
            }
            addWatchFolderButton.isEnabled = true
            removeWatchFolderButton.isEnabled = true
        } else {
            automaticallyAddFilesCheck.state = NSOffState
            self.watchFolders = [URL]()
            addWatchFolderButton.isEnabled = false
            removeWatchFolderButton.isEnabled = false
        }
        if library.keeps_track_of_files == true {
            enableDirectoryMonitoringCheck.state = NSOnState
            sourceMonitorStatusImageView.image = NSImage(named: "NSStatusAvailable")
            sourceMonitorStatusTextField.stringValue = "Directory monitoring is active."
        } else {
            enableDirectoryMonitoringCheck.state = NSOffState
            sourceMonitorStatusImageView.image = NSImage(named: "NSStatusUnavailable")
            sourceMonitorStatusTextField.stringValue = "Directory monitoring inactive."
        }
    }
    
    //location manager
    @IBOutlet weak var locationManagerView: NSView!
    @IBOutlet weak var trackLocationStatusText: NSTextField!
    @IBOutlet weak var verifyLocationsButton: NSButton!
    @IBOutlet weak var libraryLocationStatusImageView: NSImageView!
    
    @IBAction func verifyLocationsPressed(_ sender: Any) {
        let parent = self.view.window?.windowController as! PreferencesWindowController
        parent.verifyLocationsSheet = LocationVerifierSheetController(windowNibName: "LocationVerifierSheetController")
        parent.window?.beginSheet(parent.verifyLocationsSheet!.window!, completionHandler: verifyLocationsModalComplete)
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            self.missingTracks = self.databaseManager.verifyTrackLocations(visualUpdateHandler: parent.verifyLocationsSheet, library: self.library!)
            DispatchQueue.main.async {
                self.verifyLocationsModalComplete(response: 1)
            }
        }
    }
    
    func displayMissingFilesViewController(for tracks: inout [Track]) {
        self.missingFilesViewController = MissingFilesViewController(nibName: "MissingFilesViewController", bundle: nil, tracks: &tracks)
        self.missingFilesViewController?.libraryManager = self
        self.locationManagerView.addSubview(self.missingFilesViewController!.view)
        self.missingFilesViewController!.view.topAnchor.constraint(equalTo: self.locationManagerView.topAnchor).isActive = true
        self.missingFilesViewController!.view.leftAnchor.constraint(equalTo: self.locationManagerView.leftAnchor).isActive = true
        self.missingFilesViewController!.view.bottomAnchor.constraint(equalTo: self.locationManagerView.bottomAnchor).isActive = true
        self.missingFilesViewController!.view.rightAnchor.constraint(equalTo: self.locationManagerView.rightAnchor).isActive = true
    }
    
    func verifyLocationsModalComplete(response: NSModalResponse) {
        guard response != NSModalResponseCancel else {return}
        if self.missingTracks!.count > 0 {
            displayMissingFilesViewController(for: &self.missingTracks!)
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
    
    func updateMissingTracks(count: Int) {
        if count > 0 {
            self.libraryLocationStatusImageView.image = NSImage(named: "NSStatusPartiallyAvailable")
            self.trackLocationStatusText.stringValue = "\(count) tracks not found."
        } else {
            self.libraryLocationStatusImageView.image = NSImage(named: "NSStatusAvailable")
            self.trackLocationStatusText.stringValue = "All tracks located."
        }
    }
    
    //dir scanner
    @IBOutlet weak var newMediaTableView: NSTableView!
    @IBOutlet weak var dirScanStatusTextField: NSTextField!
    @IBOutlet weak var directoryPicker: NSPopUpButton!
    
    @IBAction func scanSourceButtonPressed(_ sender: Any) {
        let parent = self.view.window?.windowController as! PreferencesWindowController
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
        let errors = databaseManager.addTracksFromURLs(mediaURLsToAdd, to: self.library!, visualUpdateHandler: nil, callback: nil)
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
