//
//  LibraryManagerSourceSelector.swift
//  jmc
//
//  Created by John Moody on 3/7/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class LibraryManagerSourceSelector: NSWindowController, NSTableViewDelegate {
    
    var verifyLocationsSheet: LocationVerifierSheetController?
    var mediaScannerSheet: MediaScannerSheet?
    var currentLibrary: Library?
    var currentLibraryManagerViewController: LibraryManagerViewController?
    var libraryViews = [Library : LibraryManagerViewController]()
    var delegate: AppDelegate?
    var watchFolderSheet: AddWatchFolderSheetController?
    var changeFolderSheet: ChangePrimaryFolderSheetController?
    var consolidateSheet: ConsolidateLibrarySheetController?
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var sourceArrayController: NSArrayController!
    
    @IBOutlet weak var libraryManagerView: NSSplitView!
    
    var managedContext = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
    
    
    
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
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        initializeForLibrary(library: globalRootLibrary!)
    }
    
}
