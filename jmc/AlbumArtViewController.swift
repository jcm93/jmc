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
    
    var fileHandler = DatabaseManager()
    dynamic var albumArtworkAdded = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func doStupidTogglingForObservers() {
        if albumArtworkAdded == true {
            albumArtworkAdded = false
        } else {
            albumArtworkAdded = true
        }
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
        if track.is_network == true {
            //todo: implement this
            return
        }
        if track.album == nil {
            self.albumArtView.image = nil
            return
        }
        if track.album != nil && track.album!.primary_art != nil {
            print("gonna get sum album art")
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
                let art = track.album!.primary_art
                let path = art?.artwork_location!
                let url = URL(string: path!)
                let image = NSImage(contentsOf: url!)
                DispatchQueue.main.async {
                    self.albumArtView.image = image
                }
            }
            doStupidTogglingForObservers()
        }
        else {
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
                if UserDefaults.standard.bool(forKey: DEFAULTS_CHECK_EMBEDDED_ARTWORK_STRING) == true {
                    print("checking mp3 for embedded art")
                    let artwork = self.fileHandler.getArtworkFromFile(track.location!)
                    if artwork != nil {
                        DispatchQueue.main.async {
                            if self.fileHandler.addPrimaryArtForTrack(track, art: artwork!) != nil {
                                do {try managedContext.save()}catch {print(error)}
                                self.initAlbumArt(track)
                                self.doStupidTogglingForObservers()
                            } else {
                                self.albumArtView.image = nil
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.albumArtView.image = nil
                        }
                    }
                }
            }
            if UserDefaults.standard.bool(forKey: DEFAULTS_CHECK_ALBUM_DIRECTORY_FOR_ART_STRING) == true {
                let imageURL = self.fileHandler.searchAlbumDirectoryForArt(track)
                if imageURL != nil {
                    let artwork = try? Data(contentsOf: imageURL!)
                    if artwork != nil {
                        DispatchQueue.main.async {
                            if self.fileHandler.addPrimaryArtForTrack(track, art: artwork!) != nil {
                                do {try managedContext.save()}catch {print(error)}
                                self.initAlbumArt(track)
                                self.doStupidTogglingForObservers()
                            } else {
                                self.albumArtView.image = nil
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.albumArtView.image = nil
                        }
                    }
                }
            }
        }
    }
}
