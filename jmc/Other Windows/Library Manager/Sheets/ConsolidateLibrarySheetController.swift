//
//  ConsolidateLibrarySheetController.swift
//  jmc
//
//  Created by John Moody on 4/22/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class DisparateTrack: NSObject {
    var track: Track
    dynamic var potentialNewURL: URL
    init(track: Track, potentialURL: URL) {
        self.track = track
        self.potentialNewURL = potentialURL
    }
}

class ConsolidateLibrarySheetController: NSWindowController, ProgressBarController {
    
    @IBOutlet weak var targetView: NSSplitView!
    var actionName: String = ""
    var thingName: String = ""
    var thingCount: Int = 0
    var preConsolidationFileViewController: AlbumFileLocationViewController!
    var postConsolidationFileViewController: AlbumFileLocationViewController!
    var things = [NSObject : URL]()
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var progressTextLabel: NSTextField!

    var libraryManager: LibraryManagerViewController?
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.window?.close()
    }
    
    @IBAction func radioActio(_ sender: Any) {
        
    }

    @IBAction func consolidatePressed(_ sender: Any) {
        /*let selectedTracks = self.postConsolidationFileViewController?.trackViewArrayController.selectedObjects as! [DisparateTrack]
        self.libraryManager?.databaseManager.batchMoveTracks(tracks: selectedTracks.map({return $0.track}), visualUpdateHandler: self)
        self.progressBar.isHidden = false
        self.progressTextLabel.isHidden = false
        self.progressBar.maxValue = Double(selectedTracks.count)
        self.progressTextLabel.stringValue = "Consolidating tracks..."
        self.thingCount = selectedTracks.count*/
        
    }
    
    func prepareForNewTask(actionName: String, thingName: String, thingCount: Int) {
        
    }
    
    func increment(thingsDone: Int) {
        self.progressBar.doubleValue = Double(thingsDone)
        self.progressTextLabel.stringValue = "Consolidating \(thingsDone) of \(self.thingCount) tracks..."
    }
    
    func makeIndeterminate(actionName: String) {
        self.progressBar.isIndeterminate = true
        self.progressBar.startAnimation(nil)
        self.progressTextLabel.stringValue = "Committing changes..."
    }
    
    func finish() {
        self.window?.close()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.preConsolidationFileViewController = AlbumFileLocationViewController(nibName: NSNib.Name(rawValue: "AlbumFileLocationViewController"), bundle: nil)
        var currentTrackLocations = getCurrentLocations(visualUpdateHandler: nil)
        self.preConsolidationFileViewController.tree = AlbumFilePathTree(files: &currentTrackLocations)
        self.targetView.addSubview(self.preConsolidationFileViewController.view)
        self.postConsolidationFileViewController = AlbumFileLocationViewController(nibName: NSNib.Name(rawValue: "AlbumFileLocationViewController"), bundle: nil)
        self.postConsolidationFileViewController.tree = AlbumFilePathTree(files: &self.things)
        self.targetView.addSubview(postConsolidationFileViewController.view)
        self.postConsolidationFileViewController!.view.topAnchor.constraint(equalTo: targetView.topAnchor).isActive = true
        self.postConsolidationFileViewController!.view.rightAnchor.constraint(equalTo: targetView.rightAnchor).isActive = true
        self.postConsolidationFileViewController!.view.bottomAnchor.constraint(equalTo: targetView.bottomAnchor).isActive = true
        self.postConsolidationFileViewController!.view.leftAnchor.constraint(equalTo: targetView.leftAnchor).isActive = true
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
