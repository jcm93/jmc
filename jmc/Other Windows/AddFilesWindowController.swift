//
//  AddFilesWindowController.swift
//  jmc
//
//  Created by John Moody on 2/25/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class AddFilesWindowController: NSWindowController {
    
    @IBOutlet var filesTextView: NSTextView!
    @IBOutlet weak var sourceSelectorPopUpButton: NSPopUpButton!
    @IBOutlet weak var okButton: NSButton!
    
    let databaseManager = DatabaseManager()
    var urls: [URL]?
    
    @IBAction func okButtonPressed(_ sender: Any) {
        if let libraryName = sourceSelectorPopUpButton.selectedItem?.title, let library = getLibrary(withName: libraryName) {
            let errors = databaseManager.addTracksFromURLs(self.urls!, to: library[0], visualUpdateHandler: nil, callback: nil  )
            print(errors)
        } else {
            //some kind of error dialog, or soemthing
        }
    }
    
    @IBAction func browseButtonPressed(_ sender: Any) {
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        myFileDialog.allowsMultipleSelection = true
        myFileDialog.allowedFileTypes = VALID_FILE_TYPES
        myFileDialog.canChooseDirectories = true
        let modalResult = myFileDialog.runModal()
        if modalResult == NSFileHandlingPanelOKButton {
            let directoryCrawlResult = databaseManager.getMediaURLsInDirectoryURLs(myFileDialog.urls)
            self.urls = directoryCrawlResult.0
            for url in urls! {
                filesTextView.string?.append("\(url.path)\n")
            }
            okButton.isEnabled = true
        } else {
            okButton.isEnabled = false
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        okButton.isEnabled = false
        let libraries = getAllLibraries()
        let libraryNames = libraries!.map({return $0.name!})
        sourceSelectorPopUpButton.addItems(withTitles: libraryNames)
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
