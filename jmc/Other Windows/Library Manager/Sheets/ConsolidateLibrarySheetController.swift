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
    @objc dynamic var potentialNewURL: URL
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
    var progressSheet: GenericProgressBarSheetController?
    var databaseManager = DatabaseManager()
    var moves = true
    @IBOutlet weak var copyFilesRadioButton: NSButton!
    @IBOutlet weak var moveFilesRadioButton: NSButton!
    
    var libraryManager: LibraryManagerViewController?
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.window?.close()
    }
    
    @IBAction func radioActio(_ sender: Any) {
        if copyFilesRadioButton.state == NSControl.StateValue.on {
            self.moves = false
        } else {
            self.moves = true
        }
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
    
    func showSelectionPressed(sender: AlbumFileLocationViewController, items: Set<NSObject>) {
        if sender == self.preConsolidationFileViewController {
            self.postConsolidationFileViewController.showItems(items: items)
        } else {
            self.preConsolidationFileViewController.showItems(items: items)
        }
    }
    
    func initialize(context: NSManagedObjectContext, visualUpdateHandler: ProgressBarController?) {
        self.preConsolidationFileViewController = AlbumFileLocationViewController(nibName: "AlbumFileLocationViewController", bundle: nil)
        var currentTrackLocations = getCurrentLocations(context: context, visualUpdateHandler: visualUpdateHandler)
        self.preConsolidationFileViewController.masterTree = AlbumFilePathTree(files: &currentTrackLocations, visualUpdateHandler: visualUpdateHandler)
        self.postConsolidationFileViewController = AlbumFileLocationViewController(nibName: "AlbumFileLocationViewController", bundle: nil)
        self.postConsolidationFileViewController.masterTree = AlbumFilePathTree(files: &self.things, visualUpdateHandler: visualUpdateHandler)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.targetView.addArrangedSubview(self.preConsolidationFileViewController.view)
        self.preConsolidationFileViewController.setupForOldLocations()
        self.preConsolidationFileViewController.parentController = self
        self.targetView.addArrangedSubview(self.postConsolidationFileViewController.view)
        self.postConsolidationFileViewController.setupForNewLocations()
        self.postConsolidationFileViewController.parentController = self
    }
    
    @IBAction func consolidatePressed(_ sender: Any) {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.informativeText = "Are you sure you want to consolidate your music library? This operation cannot be undone."
        let response = alert.runModal()
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            print("consolidating library")
            self.progressSheet = GenericProgressBarSheetController(windowNibName: "GenericProgressBarSheetController")
            self.window?.beginSheet(self.progressSheet!.window!, completionHandler: nil)
            backgroundContext.perform {
                self.databaseManager.consolidateLibrary(withLocations: self.postConsolidationFileViewController.masterTree.rootNode.objectPathDictionaryIfRoot!, context: backgroundContext, visualUpdateHandler: self.progressSheet, moves: self.moves)
                DispatchQueue.main.async {
                    self.window?.close()
                }
            }
        }
    }
}
