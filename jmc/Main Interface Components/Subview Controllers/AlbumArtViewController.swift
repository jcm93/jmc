//
//  AlbumArtViewController.swift
//  minimalTunes
//
//  Created by John Moody on 12/1/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class AlbumArtViewController: NSViewController {

    @IBOutlet var albumArtBox: NSBox!
    @IBOutlet weak var albumArtView: DragAndDropImageView!
    
    var artWindow: AlbumArtWindowController?
    var mainWindow: MainWindowController?
    var databaseManager = DatabaseManager()
    var currentTrack: Track?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.albumArtView.viewController = self
    }
    
    func loadAlbumArtWindow() {
        print("loading album art window")
        self.artWindow = AlbumArtWindowController(windowNibName: "AlbumArtWindowController")
        self.artWindow?.track = self.mainWindow?.currentTrack
        self.mainWindow?.window?.addChildWindow(self.artWindow!.window!, ordered: .above)
    }
    
    func toggleHidden(_ artworkToggle: Int) {
        if artworkToggle == NSOnState {
            albumArtBox.isHidden = false
        }
        else {
            albumArtBox.isHidden = true
        }
    }
    
    func artCallback(track: Track, found: Bool) {
        //might be called from background thread
        guard track == self.currentTrack else { return }
        DispatchQueue.main.async {
            if !found {
                self.albumArtView.image = nil
            } else {
                guard track.album?.primary_art != nil else { self.albumArtView.image = nil; return }
                self.initAlbumArt(track)
            }
        }
    }
    
    func initAlbumArt(_ track: Track) {
        self.currentTrack = track
        if track.album?.primary_art != nil {
            let imageURL = URL(string: track.album!.primary_art!.artwork_location!)!
            let image = NSImage(byReferencing: imageURL)
            if image.isValid {
                self.albumArtView.image = image
            }
        } else {
            if track.library?.finds_artwork == true {
                DispatchQueue.global(qos: .default).async {
                    self.databaseManager.tryFindPrimaryArtForTrack(track, callback: self.artCallback)
                }
            } else {
                self.albumArtView.image = nil
            }
        }
    }
}
