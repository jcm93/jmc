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
        iTunesParser?.addObserver(self, forKeyPath: "numSongs", options: .New, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "numImportedSongs", options: .New, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "doneSongs", options: .New, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "numPlaylists", options: .New, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "numImportedPlaylists", options: .New, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "doneSorting", options: .New, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "numSorts", options: .New, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "numDoneSorts", options: .New, context: &my_special_context)
        iTunesParser?.addObserver(self, forKeyPath: "donePlaylists", options: .New, context: &my_special_context)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
         if keyPath == "doneSongs" {
            print("finished songs, progressing to sorting")
            self.progressIndicator.doubleValue = 0
            self.progressIndicator.bind("value", toObject: iTunesParser!, withKeyPath: "numDoneSorts", options: nil)
            self.progressIndicator.bind("maxValue", toObject: iTunesParser!, withKeyPath: "numSorts", options: nil)
            progressString.stringValue = "Caching sorts..."
        }
        if keyPath == "doneSorts" {
            self.progressIndicator.doubleValue = 0
            self.progressIndicator.bind("value", toObject: iTunesParser!, withKeyPath: "numImportedPlaylists", options: nil)
            self.progressIndicator.bind("maxValue", toObject: iTunesParser!, withKeyPath: "numPlaylists", options: nil)
            progressString.stringValue = "Importing playlists..."
        }
        if keyPath == "doneEverything" {
            print("progress bar here")
            self.window?.close()
        }
    }
    
    func doStuff() {
        print("doing stuff as a progress bar")
        dispatch_async(dispatch_get_main_queue()) {
            self.progressString.stringValue = "Importing songs..."
        }
        self.progressIndicator.bind("value", toObject: iTunesParser!, withKeyPath: "numImportedSongs", options: nil)
        self.progressIndicator.bind("maxValue", toObject: iTunesParser!, withKeyPath: "numSongs", options: nil)
        self.iTunesParser?.numImportedSongs = 0
        self.iTunesParser!.makeLibrary()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    
}
