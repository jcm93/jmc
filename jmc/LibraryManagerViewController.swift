//
//  LibraryManagerViewController.swift
//  jmc
//
//  Created by John Moody on 2/13/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa
import DiskArbitration

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

class LibraryManagerViewController: NSWindowController, NSTableViewDelegate {
    
    var fileManager = FileManager.default
    var databaseManager = DatabaseManager()
    var library: Library?
    var missingTracks: [Track]?
    var newMediaURLs: [URL]?
    
    //sheets
    var addSourceSheet: NewSourceSheetController?
    var verifyLocationsSheet: LocationVerifierSheetController?
    var mediaScannerSheet: MediaScannerSheet?
    
    var managedContext = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
    @IBOutlet weak var sourceTableView: NSTableView!
    
    //data controllers
    @IBOutlet var libraryArrayController: NSArrayController!
    @IBOutlet var tracksNotFoundArrayController: NSArrayController!
    @IBOutlet var newTracksArrayController: NSArrayController!
    
    //source information elements
    @IBOutlet weak var sourceTitleLabel: NSTextField!
    @IBOutlet weak var sourceNameField: NSTextField!
    @IBOutlet weak var sourceLocationStatusImage: NSImageView!
    @IBOutlet weak var sourceLocationStatusTextField: NSTextField!
    @IBOutlet weak var sourceMonitorStatusImageView: NSImageView!
    @IBOutlet weak var sourceMonitorStatusTextField: NSTextField!
    @IBOutlet weak var sourceLocationField: NSTextField!
    
    @IBAction func addSourceButtonPressed(_ sender: Any) {
        self.addSourceSheet = NewSourceSheetController(windowNibName: "NewSourceSheetController")
        self.window?.beginSheet(self.addSourceSheet!.window!, completionHandler: addSourceModalComplete)
    }
    
    func addSourceModalComplete(response: NSModalResponse) {
        
    }
    
    @IBAction func removeSourceButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func changeSourceLocationButtonPressed(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.runModal()
        if openPanel.urls.count > 0 {
            let newURL = openPanel.urls[0]
            self.library?.library_location = newURL.absoluteString
            initializeForLibrary(library: self.library!)
        }
    }
    
    func sourceSelectionDidChange() {
        print("doingus")
        initializeForLibrary(library: self.libraryArrayController.selectedObjects[0] as! Library)
    }
    
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        sourceSelectionDidChange()
        return true
    }
    
    func initializeForLibrary(library: Library) {
        self.library = library
        sourceTitleLabel.stringValue = ("Information for \(library.name!):")
        sourceNameField.stringValue = library.name!
        let sourceLocationURL = URL(string: library.library_location!)!
        sourceLocationField.stringValue = sourceLocationURL.path
        var isDirectory = ObjCBool(Bool(0))
        if fileManager.fileExists(atPath: sourceLocationURL.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            sourceLocationStatusImage.image = NSImage(named: "NSStatusAvailable")
            sourceLocationStatusTextField.stringValue = "Source is located and available."
        } else {
            sourceLocationStatusImage.image = NSImage(named: "NSStatusUnavailable")
            sourceLocationStatusTextField.stringValue = "Source cannot be located."
        }
        if let session = DASessionCreate(kCFAllocatorDefault) {
            var volumeURL: AnyObject?
            do {
                try (sourceLocationURL as NSURL).getResourceValue(&volumeURL, forKey: URLResourceKey.volumeURLKey)
                if let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, volumeURL as! NSURL) {
                    let diskInformation = DADiskCopyDescription(disk) as! [String: AnyObject]
                    if diskInformation[kDADiskDescriptionMediaRemovableKey as String] != nil {
                        let removable = diskInformation[kDADiskDescriptionMediaRemovableKey as String] as! CFBoolean
                        if removable == kCFBooleanTrue {
                            sourceMonitorStatusImageView.image = NSImage(named: "NSStatusPartiallyAvailable")
                            sourceMonitorStatusTextField.stringValue = "Directory is on an external drive. Directory monitoring is active, but if another computer has modified the contents of this directory, you may need to re-verify the locations of media, or re-scan the directory if new media has been added."
                        }  else {
                            sourceMonitorStatusImageView.image = NSImage(named: "NSStatusAvailable")
                            sourceMonitorStatusTextField.stringValue = "Directory monitoring is active."
                        }
                    } else {
                        if diskInformation[kDADiskDescriptionVolumeNetworkKey as String] != nil {
                            let networkStatus = diskInformation[kDADiskDescriptionVolumeNetworkKey as String] as! CFBoolean
                            if networkStatus == kCFBooleanTrue {
                                sourceMonitorStatusImageView.image = NSImage(named: "NSStatusPartiallyAvailable")
                                sourceMonitorStatusTextField.stringValue = "Directory is remote. Directory monitoring is active, but if another computer has modified the contents of this directory, you may need to re-verify the locations of media, or re-scan the directory if new media has been added."
                            }
                        } else {
                            sourceMonitorStatusImageView.image = NSImage(named: "NSStatusPartiallyAvailable")
                            sourceMonitorStatusTextField.stringValue = "Directory watch status unknown!"
                        }
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    //location manager
    @IBOutlet weak var lostTracksTableView: NSTableView!
    @IBOutlet weak var trackLocationStatusText: NSTextField!
    @IBOutlet weak var verifyLocationsButton: NSButton!
    @IBOutlet weak var libraryLocationStatusImageView: NSImageView!
    
    
    
    @IBAction func verifyLocationsButtonPressed(_ sender: Any) {
        self.verifyLocationsSheet = LocationVerifierSheetController(windowNibName: "LocationVerifierSheetController")
        self.window?.beginSheet(self.verifyLocationsSheet!.window!, completionHandler: verifyLocationsModalComplete)
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            self.missingTracks = self.databaseManager.verifyTrackLocations(visualUpdateHandler: self.verifyLocationsSheet, library: self.library!)
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
        }
    }
    
    @IBAction func locateTrackButtonPressed(_ sender: Any) {
        print("locate pressed")
        let row = lostTracksTableView.row(for: (sender as! NSButton).superview as! NSTableCellView)
        let trackContainer = (tracksNotFoundArrayController.arrangedObjects as! [TrackNotFound])[row]
        let track = trackContainer.track
        let fileDialog = NSOpenPanel()
        fileDialog.allowsMultipleSelection = false
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
    
    @IBAction func scanSourceButtonPressed(_ sender: Any) {
        self.mediaScannerSheet = MediaScannerSheet(windowNibName: "MediaScannerSheet")
        self.window?.beginSheet(self.mediaScannerSheet!.window!, completionHandler: scanMediaModalComplete)
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            self.newMediaURLs = self.databaseManager.scanForNewMedia(visualUpdateHandler: self.mediaScannerSheet, library: self.library!)
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
        let errors = databaseManager.addTracksFromURLs(mediaURLsToAdd, to: self.library!)
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
    
    override func windowDidLoad() {
        super.windowDidLoad()
        sourceTableView.delegate = self
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
