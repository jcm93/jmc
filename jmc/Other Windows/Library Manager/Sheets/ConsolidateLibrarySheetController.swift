//
//  ConsolidateLibrarySheetController.swift
//  jmc
//
//  Created by John Moody on 4/22/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class ConsolidateLibrarySheetController: NSWindowController, ProgressBarController {
    
    var actionName: String = ""
    var thingName: String = ""
    var thingCount: Int = 0
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var progressTextLabel: NSTextField!
    
    @IBOutlet var disparateTracksArrayController: NSArrayController!
    var libraryManager: LibraryManagerViewController?
    
    @IBAction func selectNonePressed(_ sender: Any) {
        tableView.deselectAll(nil)
    }
    
    @IBAction func selectAllPressed(_ sender: Any) {
        tableView.selectAll(nil)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.window?.close()
    }
    
    @IBAction func radioActio(_ sender: Any) {
        
    }

    @IBAction func consolidatePressed(_ sender: Any) {
        let selectedTracks = disparateTracksArrayController.selectedObjects as! [Track]
        self.libraryManager?.databaseManager.batchMoveTracks(tracks: selectedTracks, visualUpdateHandler: self)
        self.progressBar.isHidden = false
        self.progressTextLabel.isHidden = false
        self.progressBar.maxValue = Double(selectedTracks.count)
        self.progressTextLabel.stringValue = "Consolidating tracks..."
        self.thingCount = selectedTracks.count
        
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
        
        self.disparateTracksArrayController.content = getTracksOutsideHomeDirectory(library: libraryManager!.library!)
        

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
