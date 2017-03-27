//
//  importProgresBar.swift
//  minimalTunes
//
//  Created by John Moody on 7/11/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

private var my_special_context = 0

class ImportProgressBar: NSWindowController {
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var progressString: NSTextField!
    
    var iTunesParser: iTunesLibraryParser?

    func initialize() {
        iTunesParser?.addObserver(self, forKeyPath: "numSongs", options: .new, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "numImportedSongs", options: .new, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "doneSongs", options: .new, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "numPlaylists", options: .new, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "numImportedPlaylists", options: .new, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "doneSorting", options: .new, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "numSorts", options: .new, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "numDoneSorts", options: .new, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "donePlaylists", options: .new, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "doneEverything", options: .new, context: &my_special_context)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
         if keyPath == "doneSongs" {
            print("finished songs, progressing to sorting")
            self.progressIndicator.doubleValue = 0
            self.progressIndicator.bind("value", to: iTunesParser!, withKeyPath: "numDoneSorts", options: nil)
            self.progressIndicator.bind("maxValue", to: iTunesParser!, withKeyPath: "numSorts", options: nil)
            progressString.stringValue = "Caching sorts..."
        }
        if keyPath == "doneSorting" {
            print("progress bar done with sorting")
            self.progressIndicator.doubleValue = 0
            self.progressIndicator.bind("value", to: iTunesParser!, withKeyPath: "numImportedPlaylists", options: nil)
            self.progressIndicator.bind("maxValue", to: iTunesParser!, withKeyPath: "numPlaylists", options: nil)
            progressString.stringValue = "Importing playlists..."
        }
        if keyPath == "doneEverything" {
            print("progress bar finished")
            progressIndicator.doubleValue = 0
            progressIndicator.isHidden = true
            self.window?.close()
        }
    }
    
    func doStuff(library: Library) {
        print("doing stuff as a progress bar")
        DispatchQueue.main.async {
            self.progressString.stringValue = "Importing songs..."
        }
        self.progressIndicator.bind("value", to: iTunesParser!, withKeyPath: "numImportedSongs", options: nil)
        self.progressIndicator.bind("maxValue", to: iTunesParser!, withKeyPath: "numSongs", options: nil)
        self.iTunesParser?.numImportedSongs = 0
        self.iTunesParser!.makeLibrary(library: library)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    
}
