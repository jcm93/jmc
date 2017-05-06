//
//  TagEditorWindow.swift
//  minimalTunes
//
//  Created by John Moody on 6/29/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

//tag editor window

import Cocoa
import CoreServices

class TagEditorWindow: NSWindowController, NSTextFieldDelegate, NSWindowDelegate {
    
    lazy var managedContext: NSManagedObjectContext = {
        return (NSApplication.shared().delegate
            as? AppDelegate)?.managedObjectContext }()!
    
    lazy var artistList: [Artist] = {
        let fetch_req = NSFetchRequest<NSFetchRequestResult>(entityName: "Artist")
        do {
            return try (self.managedContext.fetch(fetch_req) as! [Artist])
        } catch {
            print("error: \(error)")
            return [Artist]()
        }
    }()
    
    var mainWindowController: MainWindowController?
    
    @IBOutlet weak var tabView: JMTabView!
    @IBOutlet weak var segControl: NSSegmentedControl!
    
    @IBAction func segControlAction(_ sender: Any) {
        guard let control = sender as? NSSegmentedControl else {
            return
        }
        tabView.selectTabViewItem(at: control.selectedSegment)
    }
    
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
    @IBOutlet weak var writeTagsButton: NSButton!
    @IBOutlet weak var compilationButton: NSButton!
    @IBOutlet weak var commentsField: NSTextField!
    @IBOutlet weak var composerField: NSTextField!
    @IBOutlet weak var releaseDatePicker: NSDatePicker!
    @IBOutlet weak var trackNumOfField: NSTextField!
    @IBOutlet weak var trackNumField: NSTextField!
    @IBOutlet weak var albumArtistField: NSTextField!
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var albumField: NSTextField!
    @IBOutlet weak var artistField: NSTextField!
    
    let fileSizeFormatter = ByteCountFormatter()
    let bitRateFormatter = BitRateFormatter()
    let sampleRateFormatter = SampleRateFormatter()
    let databaseManager = DatabaseManager()
    
    
    //mark artwork view
    @IBOutlet weak var artworkCollectionView: NSCollectionView!
    @IBOutlet weak var imageView: NSImageView!
    var artImages: [NSImage]?
    
    //mark file info view
    @IBOutlet weak var fileInfoTab: NSTabViewItem!
    
    //mark the rest
    var selectedTracks: [Track]?
    dynamic var currentTrack: Track?
    
    func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? {
        return managedContext.undoManager
    }
    
    @IBAction func nameEdited(_ sender: Any) {
        databaseManager.nameEdited(tracks: self.selectedTracks!, value: self.nameField.stringValue)
    }
    
    @IBAction func artistEdited(_ sender: Any) {
        databaseManager.artistEdited(tracks: self.selectedTracks!, value: self.artistField.stringValue)
    }
    
    @IBAction func albumArtistEdited(_ sender: Any) {
        databaseManager.albumArtistEdited(tracks: self.selectedTracks!, value: self.albumArtistField.stringValue)
    }
    
    @IBAction func albumEdited(_ sender: Any) {
        databaseManager.albumEdited(tracks: self.selectedTracks!, value: self.albumField.stringValue)
    }
    
    @IBAction func trackNumEdited(_ sender: Any) {
        databaseManager.trackNumEdited(tracks: self.selectedTracks!, value: self.trackNumField.integerValue)
    }
    
    @IBAction func trackNumOfEdited(_ sender: Any) {
        databaseManager.trackNumOfEdited(tracks: self.selectedTracks!, value: self.trackNumOfField.integerValue)
    }
    
    @IBAction func discNumEdited(_ sender: Any) {
        databaseManager.discNumEdited(tracks: self.selectedTracks!, value: self.discNumField.integerValue)
    }
    
    @IBAction func totalDiscsEdited(_ sender: Any) {
        databaseManager.totalDiscsEdited(tracks: self.selectedTracks!, value: self.discNumOfField.integerValue)
    }
    
    @IBAction func composerEdited(_ sender: Any) {
        databaseManager.composerEdited(tracks: self.selectedTracks!, value: self.composerField.stringValue)
    }
    
    @IBAction func genreEdited(_ sender: Any) {
        databaseManager.genreEdited(tracks: self.selectedTracks!, value: self.genreField.stringValue)
    }
    
    @IBAction func compilationChanged(_ sender: Any) {
        databaseManager.compilationChanged(tracks: self.selectedTracks!, value: self.compilationButton.state != 0)
    }
    
    @IBAction func commentsEdited(_ sender: Any) {
        databaseManager.commentsEdited(tracks: self.selectedTracks!, value: self.commentsField.stringValue)
    }
    
    @IBAction func releaseDateChecked(_ sender: AnyObject) {
        if releaseDateCheck.state == NSOnState {
            releaseDatePicker.datePickerElements = .yearMonthDayDatePickerElementFlag
            releaseDatePicker.isEnabled = true
        } else {
            releaseDatePicker.datePickerElements = NSDatePickerElementFlags(rawValue: 0)
            releaseDatePicker.isEnabled = false
        }
    }
    
    @IBAction func datePickerAction(_ sender: AnyObject) {
        
    }
    
    func allEqual<T:Equatable>(_ thing: [T?]) -> Bool {
        let firstElem = thing.first!
        if thing.contains( where: {$0 != firstElem}) == false {
            return true
        }
        else {
            return false
        }
    }
    
    func populateFields() {
        var artist: String?
        var album: String?
        var albumArtist: String?
        var composer: String?
        let names = selectedTracks!.map( { return $0.name } )
        if allEqual(names) == true {
            if names[0] != nil {
                nameField.stringValue = names[0]!
                sortingNameField.stringValue = names[0]!
            }
        }
        let artist_names = selectedTracks!.map( { return $0.artist?.name } )
        if allEqual(artist_names) == true {
            if artist_names[0] != nil {
                artist = artist_names[0]!
                artistField.stringValue = artist_names[0]!
                sortingArtistField.stringValue = artist_names[0]!
            }
        }
        let album_names = selectedTracks!.map( { return $0.album?.name } )
        if allEqual(album_names) == true {
            if album_names[0] != nil {
                album = album_names[0]!
                albumField.stringValue = album_names[0]!
                sortingAlbumField.stringValue = album_names[0]!
            }
            populateArtwork()
        }
        let album_artist_names = selectedTracks!.map( { return $0.album?.album_artist?.name } )
        if allEqual(album_artist_names) == true {
            if album_artist_names[0] != nil {
                albumArtist = album_artist_names[0]!
                albumArtistField.stringValue = album_artist_names[0]!
                sortingAlbumArtistField.stringValue = album_artist_names[0]!
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
                sortingComposerField.stringValue = composers[0]!
                composer = composers[0]!
            }
        }
        let release_dates = selectedTracks!.map({ return $0.album?.release_date })
        if allEqual(release_dates) == true {
            if release_dates[0] != nil {
                releaseDatePicker.dateValue = release_dates[0]! as Date
                releaseDateCheck.state = NSOnState
            } else {
                releaseDateCheck.state = NSOffState
                releaseDatePicker.datePickerElements = NSDatePickerElementFlags(rawValue: 0)
                releaseDatePicker.isEnabled = false
            }
        }
        let track_nums = selectedTracks!.map({return $0.track_num})
        if allEqual(track_nums) {
            if track_nums[0] != nil && track_nums[0] != 0 {
                trackNumField.stringValue = String(describing: track_nums[0]!)
            }
        }
        let track_num_ofs = selectedTracks!.map({return $0.album?.track_count})
        if allEqual(track_num_ofs) {
            if track_num_ofs[0] != nil && track_num_ofs[0] != 0 {
                trackNumOfField.stringValue = String(describing: track_num_ofs[0]!)
            }
        }
        let disc_nums = selectedTracks!.map({return $0.disc_number})
        if allEqual(disc_nums) {
            if disc_nums[0] != nil && disc_nums[0] != 0 {
                discNumField.stringValue = String(describing: disc_nums[0]!)
            }
        }
        let disc_counts = selectedTracks!.map({return $0.album?.disc_count})
        if allEqual(disc_counts) {
            if disc_counts[0] != nil && disc_counts[0] != 0 {
                discNumOfField.stringValue = String(describing: disc_counts[0]!)
            }
        }
        let genres = selectedTracks!.map({return $0.genre})
        if allEqual(genres) {
            if genres[0] != nil {
                genreField.stringValue = genres[0]!
            }
        }
        let is_compilations = selectedTracks!.map({return $0.album?.is_compilation})
        if allEqual(is_compilations) {
            if is_compilations[0] != nil {
                compilationButton.state = is_compilations[0]! == NSNumber(value: true as Bool) ? NSOnState : NSOffState
            }
        }
        let ratings = selectedTracks!.map({return $0.rating})
        let sortNames = selectedTracks!.flatMap({return $0.sort_name})
        let sortNamesSet = Set(sortNames)
        if sortNamesSet.count == 1 && sortNames.count == selectedTracks?.count {
            sortingNameSortAsField.stringValue = sortNames.first!
        }
        let sortAlbums = selectedTracks!.flatMap({return $0.sort_album})
        let sortAlbumsSet = Set(sortAlbums)
        if sortAlbumsSet.count == 1 && sortAlbums.count == selectedTracks?.count {
            sortingAlbumSortAsField.stringValue = sortAlbums.first!
        }
        let sortArtists = selectedTracks!.flatMap({return $0.sort_artist})
        let sortArtistsSet = Set(sortArtists)
        if sortArtistsSet.count == 1 && sortArtists.count == selectedTracks?.count {
            sortingArtistSortAsField.stringValue = sortArtists.first!
        }
        let sortAlbumArtists = selectedTracks!.flatMap({return $0.sort_album_artist})
        let sortAlbumArtistsSet = Set(sortAlbumArtists)
        if sortAlbumArtistsSet.count == 1 && sortAlbumArtists.count == selectedTracks?.count {
            sortingAlbumArtistSortAsField.stringValue = sortAlbumArtists.first!
        }
        let sortComposers = selectedTracks!.flatMap({return $0.sort_composer})
        let sortComposersSet = Set(sortComposers)
        if sortComposersSet.count == 1 && sortComposers.count == selectedTracks?.count{
            sortingComposerSortAsField.stringValue = sortComposers.first!
        }
        var titleString = ""
        if albumArtist != nil {
            if artist != nil {
                titleString.append(artist!)
                if album != nil {
                    titleString.append(" - \(album!)")
                }
            } else {
                if album != nil {
                    titleString = album!
                }
            }
            if titleString != "" {
                self.window?.title = titleString
            } else {
                self.window?.title = "Edit Info"
            }
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.window?.close()
    }
    
    @IBAction func previousTrackAction(_ sender: AnyObject) {
        
    }
    
    @IBAction func nextTrackAction(_ sender: AnyObject) {
        
    }
    
    func initForSelection() {
        if selectedTracks!.count > 1 {
            nextTrackButton.isHidden = true
            previousTrackButton.isHidden = true
            tabView.removeTabViewItem(fileInfoTab)
        } else {
            currentTrack = selectedTracks![0]
            populateFileInfo()
        }
        populateFields()
    }
    
    //mark artwork view
    
    func populateArtwork() {
        let album = selectedTracks![0].album
        guard album != nil else {return}
        if album!.primary_art != nil {
            let artURL = URL(string: album!.primary_art!.artwork_location!)
            self.imageView.image = NSImage(contentsOf: artURL!)
        }
        if album?.other_art != nil {
            let artURLs: [URL] = album!.other_art!.art!.map({return URL(string: ($0 as! AlbumArtwork).artwork_location!)!})
            self.artImages = artURLs.map({return NSImage(contentsOf: $0)!})
        }
        print("registering for dragged types")
    }
    
    //mark file info
    @IBOutlet weak var kindLabel: NSTextField!
    @IBOutlet weak var durationLabel: NSTextField!
    @IBOutlet weak var sizeLabel: NSTextField!
    @IBOutlet weak var bitRateLabel: NSTextField!
    @IBOutlet weak var sampleRateLabel: NSTextField!
    @IBOutlet weak var id3Label: NSTextField!
    @IBOutlet weak var channelsLabel: NSTextField!
    @IBOutlet weak var formatLabel: NSTextField!
    @IBOutlet weak var encoderLabel: NSTextField!
    @IBOutlet weak var dateModifiedLabel: NSTextField!
    @IBOutlet weak var dateAddedLabel: NSTextField!
    @IBOutlet weak var locationPathControl: NSPathControl!
    
    func populateFileInfo() {
        //todo correct tags if inconsistent
        let mdItem = MDItemCreateWithURL(kCFAllocatorDefault, NSURL(string: self.currentTrack!.location!))
        let kind = MDItemCopyAttribute(mdItem, kMDItemKind) as? String
        kindLabel.stringValue = kind!
        let duration = MDItemCopyAttribute(mdItem, kMDItemDurationSeconds) as! Int
        durationLabel.stringValue = getTimeAsString(Double(duration))!
        let size = MDItemCopyAttribute(mdItem, kMDItemFSSize) as! Int
        sizeLabel.stringValue = fileSizeFormatter.string(fromByteCount: Int64(size))
        let bitRateCheck = MDItemCopyAttribute(mdItem, kMDItemAudioBitRate) as? Int
        bitRateLabel.stringValue = bitRateFormatter.string(for: bitRateCheck)!
        let sampleRateCheck = MDItemCopyAttribute(mdItem, kMDItemAudioSampleRate) as? Int
        sampleRateLabel.stringValue = sampleRateFormatter.string(for: sampleRateCheck)!
        let channels = MDItemCopyAttribute(mdItem, kMDItemAudioChannelCount) as! Int
        channelsLabel.stringValue = String(describing: channels)
        let encoder = MDItemCopyAttribute(mdItem, kMDItemAudioEncodingApplication) as? String
        encoderLabel.stringValue = encoder != nil ? encoder! : "No encoder information available."
        let dateModified = MDItemCopyAttribute(mdItem, kMDItemContentModificationDate) as? NSDate
        dateModifiedLabel.stringValue = dateModified != nil ? dateModified!.description : ""
        let dateAdded = MDItemCopyAttribute(mdItem, kMDItemDateAdded) as? NSDate
        dateAddedLabel.stringValue = dateAdded != nil ? dateAdded!.description as! String : ""
    }
    //mark playback
    //mark sorting
    @IBOutlet weak var sortingNameField: NSTextField!
    @IBOutlet weak var sortingNameSortAsField: NSTextField!
    @IBOutlet weak var sortingAlbumField: NSTextField!
    @IBOutlet weak var sortingAlbumSortAsField: NSTextField!
    @IBOutlet weak var sortingArtistField: NSTextField!
    @IBOutlet weak var sortingArtistSortAsField: NSTextField!
    @IBOutlet weak var sortingAlbumArtistField: NSTextField!
    @IBOutlet weak var sortingAlbumArtistSortAsField: NSTextField!
    @IBOutlet weak var sortingComposerField: NSTextField!
    @IBOutlet weak var sortingComposerSortAsField: NSTextField!
    

    override func windowDidLoad() {
        super.windowDidLoad()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        initForSelection()
        tabView.drawsBackground = false
        self.window?.titlebarAppearsTransparent = true
        self.window!.titleVisibility = .hidden
    }
    
}
