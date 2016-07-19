//
//  TagEditorWindow.swift
//  minimalTunes
//
//  Created by John Moody on 6/29/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

//tag editor window

import Cocoa

class TagEditorWindow: NSWindowController {
    
    lazy var managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    
    lazy var artistList: [Artist] = {
        let fetch_req = NSFetchRequest(entityName: "Artist")
        do {
            return try (self.managedContext.executeFetchRequest(fetch_req) as! [Artist])
        } catch {
            print("error: \(error)")
            return [Artist]()
        }
    }()
    
    var mainWindowController: MainWindowController?
    
    
    //mark tag view
    @IBOutlet weak var tagsView: NSView!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var confirmButton: NSButton!
    @IBOutlet weak var previousTrackButton: NSButton!
    @IBOutlet weak var nextTrackButton: NSButton!
    @IBOutlet weak var addCustomFieldButton: NSButton!
    @IBOutlet weak var writeTagsButton: NSButton!
    @IBOutlet weak var compilationButton: NSButton!
    @IBOutlet weak var ratingField: NSTextField!
    @IBOutlet weak var commentsField: NSTextField!
    @IBOutlet weak var composerField: NSTextField!
    @IBOutlet weak var releaseDatePicker: NSDatePicker!
    @IBOutlet weak var trackNumOfField: NSTextField!
    @IBOutlet weak var trackNumField: NSTextField!
    @IBOutlet weak var albumArtistField: NSTextField!
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var albumField: NSTextField!
    @IBOutlet weak var artistField: NSTextField!
    
    var selectedTracks: [Track]?
    
    func commitEdits() {
        print("committing edits")
        //comments, composer, release date, track num, album artist, name, album, artist
        for track in selectedTracks! {
            if nameField.stringValue.isEmpty == false {
                track.name = nameField.stringValue
            }
        }
        if artistField.stringValue.isEmpty == false {
            editArtist(selectedTracks, artistName: artistField.stringValue)
        }
        if albumField.stringValue.isEmpty == false {
            editAlbum(selectedTracks, albumName: albumField.stringValue)
        }
        print(selectedTracks)
        for order in mainWindowController!.cachedOrders {
            reorderForTracks(self.selectedTracks!, cachedOrder: order)
        }
        self.mainWindowController?.currentArrayController?.rearrangeObjects()
        self.mainWindowController?.currentTableView?.reloadData()
        
        
    }
    
    @IBAction func confirmPressed(sender: AnyObject) {
        commitEdits()
        self.window?.close()
    }
    
    func allEqual<T:Equatable>(thing: [T?]) -> Bool {
        let firstElem = thing.first!
        if thing.contains( {$0 != firstElem}) == false {
            return true
        }
        else {
            return false
        }
    }
    
    func populateFields() {
        print(selectedTracks)
        let names = selectedTracks!.map( { return $0.name } )
        if allEqual(names) == true {
            if names[0] != nil {
                nameField.stringValue = names[0]!
            }
        }
        let artist_names = selectedTracks!.map( { return $0.artist?.name } )
        if allEqual(artist_names) == true {
            if artist_names[0] != nil {
                artistField.stringValue = artist_names[0]!
            }
        }
        let album_names = selectedTracks!.map( { return $0.album?.name } )
        if allEqual(album_names) == true {
            if album_names[0] != nil {
                albumField.stringValue = album_names[0]!
            }
        }
        let album_artist_names = selectedTracks!.map( { return $0.album?.album_artist?.name } )
        if allEqual(album_artist_names) == true {
            if album_artist_names[0] != nil {
                albumArtistField.stringValue = album_artist_names[0]!
            }
        }
        let comments = selectedTracks!.map( { return $0.comments } )
        if allEqual(comments) == true {
            if comments[0] != nil {
                commentsField.stringValue = comments[0]!
            }
        }
        let composers = selectedTracks!.map( { return $0.composer?.name } )
        if allEqual(composers) == true {
            if composers[0] != nil {
                composerField.stringValue = composers[0]!
            }
        }
        let release_dates = selectedTracks!.map({ return $0.album?.release_date })
        if allEqual(release_dates) == true {
            if release_dates[0] != nil {
                releaseDatePicker.dateValue = release_dates[0]!
            }
        }
    }
    
    func initForSelection() {
        if selectedTracks!.count > 1 {
            nextTrackButton.hidden = true
            previousTrackButton.hidden = true
        }
        populateFields()
    }
    
    //mark artwork view
    //mark file info
    //mark playback
    //mark sorting

    override func windowDidLoad() {
        initForSelection()
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
