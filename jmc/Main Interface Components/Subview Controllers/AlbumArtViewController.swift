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

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.albumArtView.viewController = self
    }
    
    func loadAlbumArtWindow() {
        print("loading album art window")
        self.artWindow = AlbumArtWindowController(windowNibName: "AlbumArtWindowController")
        self.artWindow?.track = self.mainWindow?.currentTrack
        self.artWindow?.showWindow(self)
    }
    
    func toggleHidden(_ artworkToggle: Int) {
        if artworkToggle == NSOnState {
            albumArtBox.isHidden = false
        }
        else {
            albumArtBox.isHidden = true
        }
    }
    

    func initAlbumArt(_ track: Track) {
        if track.album?.primary_art != nil {
            let imageURL = URL(string: track.album!.primary_art!.artwork_location!)!
            let image = NSImage(byReferencing: imageURL)
            if image.isValid {
                self.albumArtView.image = image
            }
        } else {
            if track.library?.finds_artwork == true {
                let didFindPrimaryArt = databaseManager.tryFindPrimaryArtForTrack(track)
                if didFindPrimaryArt {
                    guard track.album?.primary_art != nil else { self.albumArtView.image = nil; return }
                    initAlbumArt(track)
                }
            }
            self.albumArtView.image = nil
        }
    }
}
