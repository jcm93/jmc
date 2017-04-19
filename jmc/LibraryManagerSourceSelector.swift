//
//  LibraryManagerSourceSelector.swift
//  jmc
//
//  Created by John Moody on 3/7/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class LibraryManagerSourceSelector: NSWindowController, NSTableViewDelegate {
    
    var addSourceSheet: NewSourceSheetController?
    var verifyLocationsSheet: LocationVerifierSheetController?
    var mediaScannerSheet: MediaScannerSheet?
    var removeSourceSheet: RemoveSourceSheetController?
    var currentLibrary: Library?
    var currentLibraryManagerViewController: LibraryManagerViewController?
    var libraryViews = [Library : LibraryManagerViewController]()
    var delegate: AppDelegate?
    var watchFolderSheet: AddWatchFolderSheetController?
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var sourceArrayController: NSArrayController!
    
    @IBOutlet weak var libraryManagerView: NSSplitView!
    
        var managedContext = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
    
    @IBAction func addSourceButtonPressed(_ sender: Any) {
        self.addSourceSheet = NewSourceSheetController(windowNibName: "NewSourceSheetController")
        self.window?.beginSheet(self.addSourceSheet!.window!, completionHandler: addSourceModalComplete)
    }
    
    
    @IBAction func removeSourceButtonPressed(_ sender: Any) {
        guard sourceArrayController.selectedObjects.count > 0 else {return}
        self.removeSourceSheet = RemoveSourceSheetController(windowNibName: "RemoveSourceSheetController")
        self.removeSourceSheet?.libraryManagerSourceSelector = self
        self.window?.beginSheet(self.removeSourceSheet!.window!, completionHandler: removeSourceModalComplete)
    }
    
    func removeLibrary() {
        let databaseManager = DatabaseManager()
        databaseManager.removeSource(library: self.currentLibrary!)
    }
    
    
    func removeSourceModalComplete(response: NSModalResponse) {
        print("remove source modal complete called")
        delegate?.reinitializeInterfaceForRemovedSource()
    }
    
    func addSourceModalComplete(response: NSModalResponse) {
        
    }
    
    
    
    func sourceSelectionDidChange(row: Int) {
        print("doingus")
        initializeForLibrary(library: (self.sourceArrayController.arrangedObjects as! [Library])[row])
    }
    
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        sourceSelectionDidChange(row: row)
        return true
    }
    
    func initializeForLibrary(library: Library) {
        if libraryManagerView.subviews.count > 0 {
            libraryManagerView.removeArrangedSubview(libraryManagerView.subviews[0])
        }
        if libraryViews[library] == nil {
            let newView = LibraryManagerViewController(nibName: "LibraryManagerViewController", bundle: nil)
            newView?.delegate = self.delegate
            libraryManagerView.addSubview(newView!.view)
            newView!.initializeForLibrary(library: library)
            self.currentLibrary = library
            libraryViews[library] = newView!
            self.currentLibraryManagerViewController = newView
        } else {
            libraryManagerView.addSubview(libraryViews[library]!.view)
            self.currentLibrary = library
            self.currentLibraryManagerViewController = libraryViews[library]
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        let indexSet = IndexSet(integer: 1)
        self.tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
