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
    var currentLibrary: Library?
    var libraryViews = [Library : LibraryManagerViewController]()

    @IBOutlet var sourceArrayController: NSArrayController!
    
    @IBOutlet weak var libraryManagerView: NSSplitView!
    
        var managedContext = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
    
    @IBAction func addSourceButtonPressed(_ sender: Any) {
        self.addSourceSheet = NewSourceSheetController(windowNibName: "NewSourceSheetController")
        self.window?.beginSheet(self.addSourceSheet!.window!, completionHandler: addSourceModalComplete)
    }
    
    func addSourceModalComplete(response: NSModalResponse) {
        
    }
    
    
    
    func sourceSelectionDidChange() {
        print("doingus")
        initializeForLibrary(library: self.sourceArrayController.selectedObjects[0] as! Library)
    }
    
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        sourceSelectionDidChange()
        return true
    }
    
    func initializeForLibrary(library: Library) {
        libraryManagerView.subviews = [NSView]()
        let newView = LibraryManagerViewController(nibName: "LibraryManagerViewController", bundle: nil)
        libraryManagerView.addSubview(newView!.view)
        newView?.initializeForLibrary(library: library)
        self.currentLibrary = library
        libraryViews[library] = newView!
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
