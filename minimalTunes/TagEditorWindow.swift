//
//  TagEditorWindow.swift
//  minimalTunes
//
//  Created by John Moody on 6/29/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

//tag editor window

import Cocoa

class TagEditorWindow: NSWindowController, NSCollectionViewDelegate, NSCollectionViewDataSource {
    
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
    
    @IBOutlet weak var tabView: NSTabView!
    
    //mark tag view
    @IBOutlet weak var discNumOfField: NSTextField!
    @IBOutlet weak var discNumField: NSTextField!
    @IBOutlet weak var genreField: NSTextField!
    @IBOutlet weak var releaseDateCheck: NSButton!
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
    
    
    //mark artwork view
    @IBOutlet weak var artworkCollectionView: NSCollectionView!
    @IBOutlet weak var imageView: NSImageView!
    var artImages: [NSImage]?
    
    //mark file info view
    @IBOutlet weak var fileInfoTab: NSTabViewItem!
    
    //mark the rest
    var selectedTracks: [Track]?
    var currentTrack: Track?
    
    func commitEdits() {
        print("committing edits")
        let fileHandler = DatabaseManager()
        //comments, composer, release date, track num, album artist, name, album, artist, disc number, 
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
        if albumArtistField.stringValue.isEmpty == false {
            editAlbumArtist(selectedTracks, albumArtistName: albumArtistField.stringValue)
        }
        if composerField.stringValue.isEmpty == false {
            editComposer(selectedTracks, composerName: composerField.stringValue)
        }
        if genreField.stringValue.isEmpty == false {
            editGenre(selectedTracks, genreName: genreField.stringValue)
        }
        if trackNumField.stringValue.isEmpty == false {
            editTrackNum(selectedTracks, num: Int(trackNumField.stringValue)!)
        }
        if trackNumOfField.stringValue.isEmpty == false {
            editTrackNumOf(selectedTracks, num: Int(trackNumOfField.stringValue)!)
        }
        if discNumField.stringValue.isEmpty == false {
            editDiscNum(selectedTracks, num: Int(discNumField.stringValue)!)
        }
        if discNumOfField.stringValue.isEmpty == false {
            editDiscNumOf(selectedTracks, num: Int(discNumOfField.stringValue)!)
        }
        if commentsField.stringValue.isEmpty == false {
            editComments(selectedTracks, comments: commentsField.stringValue)
        }
        if ratingField.stringValue.isEmpty == false {
            editRating(selectedTracks, rating: Int(ratingField.stringValue)!)
        }
        print(selectedTracks)
        for order in mainWindowController!.cachedOrders! {
            reorderForTracks(self.selectedTracks!, cachedOrder: order)
        }
        for track in selectedTracks! {
            fileHandler.moveFileAfterEdit(track)
        }
    }
    
    @IBAction func confirmPressed(sender: AnyObject) {
        commitEdits()
        self.window?.close()
        self.mainWindowController?.currentTableViewController?.trackViewArrayController.rearrangeObjects()
    }
    
    @IBAction func releaseDateChecked(sender: AnyObject) {
        if releaseDateCheck.state == NSOnState {
            releaseDatePicker.datePickerElements = .YearMonthDayDatePickerElementFlag
            releaseDatePicker.enabled = true
        } else {
            releaseDatePicker.datePickerElements = NSDatePickerElementFlags(rawValue: 0)
            releaseDatePicker.enabled = false
        }
    }
    
    @IBAction func datePickerAction(sender: AnyObject) {
        
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
            populateArtwork()
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
                releaseDateCheck.state = NSOnState
            } else {
                releaseDateCheck.state = NSOffState
                releaseDatePicker.datePickerElements = NSDatePickerElementFlags(rawValue: 0)
                releaseDatePicker.enabled = false
            }
        }
        let track_nums = selectedTracks!.map({return $0.track_num})
        if allEqual(track_nums) {
            if track_nums[0] != nil && track_nums[0] != 0 {
                trackNumField.stringValue = String(track_nums[0]!)
            }
        }
        let track_num_ofs = selectedTracks!.map({return $0.album?.track_count})
        if allEqual(track_num_ofs) {
            if track_num_ofs[0] != nil && track_num_ofs[0] != 0 {
                trackNumOfField.stringValue = String(track_num_ofs[0]!)
            }
        }
        let disc_nums = selectedTracks!.map({return $0.disc_number})
        if allEqual(disc_nums) {
            if disc_nums[0] != nil && disc_nums[0] != 0 {
                discNumField.stringValue = String(disc_nums[0]!)
            }
        }
        let disc_counts = selectedTracks!.map({return $0.album?.disc_count})
        if allEqual(disc_counts) {
            if disc_counts[0] != nil && disc_counts[0] != 0 {
                discNumOfField.stringValue = String(disc_counts[0]!)
            }
        }
        let genres = selectedTracks!.map({return $0.genre?.name})
        if allEqual(genres) {
            if genres[0] != nil {
                genreField.stringValue = genres[0]!
            }
        }
        let is_compilations = selectedTracks!.map({return $0.album?.is_compilation})
        if allEqual(is_compilations) {
            if is_compilations[0] != nil {
                compilationButton.state = is_compilations[0]! == NSNumber(bool: true) ? NSOnState : NSOffState
            }
        }
        let ratings = selectedTracks!.map({return $0.rating})
        if allEqual(ratings) {
            if ratings[0] != nil && ratings[0] != 0 {
                ratingField.stringValue = String(ratings[0]!)
            }
        }
        let present_properties = Set(selectedTracks!.map({return $0.user_defined_properties!}).flatMap({$0}))
        for property in present_properties {
            
        }
        
        
        
        
    }
    @IBAction func previousTrackAction(sender: AnyObject) {
        
    }
    
    @IBAction func nextTrackAction(sender: AnyObject) {
        
    }
    func initForSelection() {
        if selectedTracks!.count > 1 {
            nextTrackButton.hidden = true
            previousTrackButton.hidden = true
            tabView.removeTabViewItem(fileInfoTab)
        }
        populateFields()
    }
    
    //mark artwork view
    
    func populateArtwork() {
        let album = selectedTracks![0].album
        guard album != nil else {return}
        if album!.primary_art != nil {
            let artURL = NSURL(string: album!.primary_art!.artwork_location!)
            self.imageView.image = NSImage(contentsOfURL: artURL!)
        }
        if album?.other_art != nil {
            let artURLs: [NSURL] = album!.other_art!.art!.map({return NSURL(string: ($0 as! AlbumArtwork).artwork_location!)!})
            self.artImages = artURLs.map({return NSImage(contentsOfURL: $0)!})
        }
        print("registering for dragged types")
        artworkCollectionView.registerForDraggedTypes([NSPasteboardTypePNG, NSPasteboardTypeTIFF, NSFilenamesPboardType, "public.file-url", "Apple URL pasteboard type", "com.apple.finder.node", NSURLPboardType])
        artworkCollectionView.dataSource = self
        artworkCollectionView.delegate = self
        artworkCollectionView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: true)
        artworkCollectionView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: false)
    }
    
    func collectionView(collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        print("nr items in collection view called")
        return artImages!.count
    }
    
    func collectionView(collectionView: NSCollectionView, itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath) -> NSCollectionViewItem {
        print("collection view data thing called")
        let index = indexPath.item
        let thingy = collectionView.makeItemWithIdentifier("poop", forIndexPath: indexPath) as! NSCollectionViewItem
        thingy.imageView?.image = artImages![index]
        return thingy
    }
    
    func collectionView(collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath?>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionViewDropOperation>) -> NSDragOperation {
        print("validating drop on collection view")
        print(draggingInfo.draggingPasteboard().types)
        return .Every
    }
    
    func collectionView(collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, index: Int, dropOperation: NSCollectionViewDropOperation) -> Bool {
        print("accepting drop on collection view")
        if let board = draggingInfo.draggingPasteboard().propertyListForType("NSFilenamesPboardType") as? NSArray, imagePath = board[0] as? String {
            let artURL = NSURL(fileURLWithPath: imagePath)
            let artImage = NSImage(contentsOfURL: artURL)
            if artImage != nil {
                let album = selectedTracks![0].album
                guard album != nil else {return false}
                let albumDirectoryURL = NSURL(string: selectedTracks![0].location!)?.URLByDeletingLastPathComponent
                let albumArtwork = NSEntityDescription.insertNewObjectForEntityForName("AlbumArtwork", inManagedObjectContext: managedContext) as! AlbumArtwork
                albumArtwork.image_hash = artImage?.TIFFRepresentation!.hashValue
                let filename = "\(albumArtwork.image_hash).png"
                let artworkURL = albumDirectoryURL?.URLByAppendingPathComponent(filename)
                let artBitmap = NSBitmapImageRep(data: artImage!.TIFFRepresentation!)
                let artPNG = artBitmap?.representationUsingType(.NSPNGFileType, properties: [:])
                albumArtwork.artwork_location = artworkURL?.absoluteString
                do {
                    try artPNG?.writeToURL(artworkURL!, options: NSDataWritingOptions.AtomicWrite)
                } catch {
                    print(error)
                }
                if album?.primary_art == nil {
                    albumArtwork.primary_album = album
                } else if album?.other_art == nil {
                    let otherArtCollection = NSEntityDescription.insertNewObjectForEntityForName("AlbumArtworkCollection", inManagedObjectContext: managedContext) as! AlbumArtworkCollection
                    otherArtCollection.album = album
                    otherArtCollection.addArtObject(albumArtwork)
                } else if album?.other_art != nil {
                    let collection = album?.other_art
                    collection?.addArtObject(albumArtwork)
                }
                self.artImages?.append(artImage!)
            }
        }
        return true
    }
    //mark file info
    //mark playback
    //mark sorting

    override func windowDidLoad() {
        initForSelection()
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
