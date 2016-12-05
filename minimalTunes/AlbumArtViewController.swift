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
    
    var fileHandler = YeOldeFileHandler()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    
    func toggleHidden(artworkToggle: Int) {
        if artworkToggle == NSOnState {
            albumArtBox.hidden = false
        }
        else {
            albumArtBox.hidden = true
        }
    }

    func initAlbumArt(track: Track) {
        if track.is_network == true {
            //todo: implement this
            return
        }
        if track.album != nil && track.album!.primary_art != nil {
            print("gonna get sum album art")
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let art = track.album!.primary_art
                let path = art?.artwork_location!
                let url = NSURL(string: path!)
                let image = NSImage(contentsOfURL: url!)
                dispatch_async(dispatch_get_main_queue()) {
                    self.albumArtView.image = image
                }
            }
        }
        else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                var artworkFound = false
                if NSUserDefaults.standardUserDefaults().boolForKey(DEFAULTS_CHECK_EMBEDDED_ARTWORK_STRING) == true {
                    print("checking mp3 for embedded art")
                    let artwork = self.fileHandler.getArtworkFromFile(track.location!)
                    if artwork != nil {
                        let albumDirectoryURL = NSURL(string: track.location!)!.URLByDeletingLastPathComponent!
                        if addPrimaryArtForTrack(track, art: artwork!, albumDirectoryURL: albumDirectoryURL) != nil {
                            dispatch_async(dispatch_get_main_queue()) {
                                do {try managedContext.save()}catch {print(error)}
                                self.initAlbumArt(track)
                            }
                            artworkFound = true
                        }
                    }
                }
                if NSUserDefaults.standardUserDefaults().boolForKey(DEFAULTS_CHECK_ALBUM_DIRECTORY_FOR_ART_STRING) == true {
                    let imageURL = self.fileHandler.searchAlbumDirectoryForArt(track)
                    if imageURL != nil {
                        let artwork = NSData(contentsOfURL: imageURL!)
                        if artwork != nil {
                            let albumDirectoryURL = NSURL(string: track.location!)!.URLByDeletingLastPathComponent!
                            if addPrimaryArtForTrack(track, art: artwork!, albumDirectoryURL: albumDirectoryURL) != nil {
                                dispatch_async(dispatch_get_main_queue()) {
                                    do {try managedContext.save()}catch {print(error)}
                                    self.initAlbumArt(track)
                                }
                                artworkFound = true
                            }
                        }
                    }
                }
                if artworkFound == false {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.albumArtView.image = nil
                    }
                }
            }
        }
    }

}
