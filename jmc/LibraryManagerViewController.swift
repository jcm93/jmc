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
    let url: URL
    let track: Track
    init(url: URL, track: Track) {
        self.url = url
        self.track = track
    }
}

class LibraryManagerViewController: NSWindowController, NSTableViewDelegate {
    
    var fileManager = FileManager.default
    
    //sheets
    var addSourceSheet: NewSourceSheetController?
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
        
    }
    
    func sourceSelectionDidChange() {
        print("doingus")
        let library = initializeForLibrary(library: self.libraryArrayController.selectedObjects[0] as! Library)
    }
    
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        sourceSelectionDidChange()
        return true
    }
    
    func initializeForLibrary(library: Library) {
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
    @IBOutlet weak var verifyLocationsButton: NSButton!
    @IBOutlet weak var libraryLocationStatusImageView: NSImageView!
    
    @IBAction func verifyLocationsButtonPressed(_ sender: Any) {
        
    }
    @IBAction func locateTrackButtonPressed(_ sender: Any) {
        
    }
    
    //dir scanner
    @IBAction func scanSourceButtonPressed(_ sender: Any) {
        
    }
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        sourceTableView.delegate = self
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
