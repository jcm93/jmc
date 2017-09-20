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
        return (NSApplication.shared.delegate
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
    @IBOutlet weak var trackNumOfField: NSTextField!
    @IBOutlet weak var trackNumField: NSTextField!
    @IBOutlet weak var albumArtistField: NSTextField!
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var albumField: NSTextField!
    @IBOutlet weak var artistField: NSTextField!
    @IBOutlet weak var yearField: NSTextField!
    @IBOutlet weak var monthCheck: NSButton!
    @IBOutlet weak var dayCheck: NSButton!
    @IBOutlet weak var monthField: NSPopUpButton!
    @IBOutlet weak var dayField: NSPopUpButton!
    
    let fileSizeFormatter = ByteCountFormatter()
    let bitRateFormatter = BitRateFormatter()
    let sampleRateFormatter = SampleRateFormatter()
    let databaseManager = DatabaseManager()
    let kMultipleThingsString = "Multiple"
    
    var nameIfAllEqual: String?
    var artistNameIfAllEqual: String?
    var albumNameIfAllEqual: String?
    var albumArtistNameIfAllEqual: String?
    var composerNameIfAllEqual: String?
    var genreNameIfAllEqual: String?
    var commentsIfAllEqual: String?
    var sortNameIfAllEqual: String?
    var sortArtistIfAllEqual: String?
    var sortAlbumIfAllEqual: String?
    var sortAlbumArtistIfAllEqual: String?
    var sortComposerIfAllEqual: String?
    var flacMDItem: FlacDecoder?
    var releaseDateComponents: DateComponents?
    var componentSet = Set([Calendar.Component.day, Calendar.Component.weekday, Calendar.Component.year, Calendar.Component.month])
    var albumFilesViewController: AlbumFilesViewController?
    
    
    //mark artwork view
    var artImages: [NSImage]?
    
    //mark file info view
    @IBOutlet weak var fileInfoTab: NSTabViewItem!
    
    //mark the rest
    var selectedTracks: [Track]?
    @objc dynamic var currentTrack: Track?
    
    func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? {
        return managedContext.undoManager
    }
    
    @IBAction func nameEdited(_ sender: Any) {
        if self.nameField.stringValue == nameIfAllEqual { return }
        if self.nameField.stringValue == "" && self.nameIfAllEqual == nil { return }
        databaseManager.nameEdited(tracks: self.selectedTracks!, value: self.nameField.stringValue)
        self.nameIfAllEqual = self.nameField.stringValue
        mainWindowController?.refreshCurrentSortOrder()
    }
    
    @IBAction func artistEdited(_ sender: Any) {
        if self.artistField.stringValue == artistNameIfAllEqual { return }
        if self.artistField.stringValue == "" && self.artistNameIfAllEqual == nil { return }
        databaseManager.artistEdited(tracks: self.selectedTracks!, value: self.artistField.stringValue)
        self.artistNameIfAllEqual = self.artistField.stringValue
        mainWindowController?.refreshCurrentSortOrder()
    }
    
    @IBAction func albumArtistEdited(_ sender: Any) {
        if self.albumArtistField.stringValue == albumArtistNameIfAllEqual { return }
        if self.albumArtistField.stringValue == "" && self.albumArtistNameIfAllEqual == nil { return }
        databaseManager.albumArtistEdited(tracks: self.selectedTracks!, value: self.albumArtistField.stringValue)
        self.albumArtistNameIfAllEqual = self.albumArtistField.stringValue
        mainWindowController?.refreshCurrentSortOrder()
    }
    
    @IBAction func albumEdited(_ sender: Any) {
        if self.albumField.stringValue == albumNameIfAllEqual { return }
        if self.albumField.stringValue == "" && self.albumNameIfAllEqual == nil { return }
        databaseManager.albumEdited(tracks: self.selectedTracks!, value: self.albumField.stringValue)
        self.albumNameIfAllEqual = self.albumField.stringValue
        mainWindowController?.refreshCurrentSortOrder()
    }
    
    @IBAction func trackNumEdited(_ sender: Any) {
        databaseManager.trackNumEdited(tracks: self.selectedTracks!, value: self.trackNumField.integerValue)
        mainWindowController?.refreshCurrentSortOrder()
    }
    
    @IBAction func trackNumOfEdited(_ sender: Any) {
        databaseManager.trackNumOfEdited(tracks: self.selectedTracks!, value: self.trackNumOfField.integerValue)
        mainWindowController?.refreshCurrentSortOrder()
    }
    
    @IBAction func discNumEdited(_ sender: Any) {
        databaseManager.discNumEdited(tracks: self.selectedTracks!, value: self.discNumField.integerValue)
        mainWindowController?.refreshCurrentSortOrder()
    }
    
    @IBAction func totalDiscsEdited(_ sender: Any) {
        databaseManager.totalDiscsEdited(tracks: self.selectedTracks!, value: self.discNumOfField.integerValue)
        mainWindowController?.refreshCurrentSortOrder()
    }
    
    @IBAction func composerEdited(_ sender: Any) {
        if self.composerField.stringValue == composerNameIfAllEqual { return }
        if self.composerField.stringValue == "" && self.composerNameIfAllEqual == nil { return }
        databaseManager.composerEdited(tracks: self.selectedTracks!, value: self.composerField.stringValue)
        self.composerNameIfAllEqual = self.composerField.stringValue
        mainWindowController?.refreshCurrentSortOrder()
    }
    
    @IBAction func genreEdited(_ sender: Any) {
        if self.genreField.stringValue == genreNameIfAllEqual { return }
        if self.genreField.stringValue == "" && self.genreNameIfAllEqual == nil { return }
        databaseManager.genreEdited(tracks: self.selectedTracks!, value: self.genreField.stringValue)
        self.genreNameIfAllEqual = self.genreField.stringValue
        mainWindowController?.refreshCurrentSortOrder()
    }
    
    @IBAction func compilationChanged(_ sender: Any) {
        databaseManager.compilationChanged(tracks: self.selectedTracks!, value: self.compilationButton.state.rawValue != 0)
        mainWindowController?.refreshCurrentSortOrder()
    }
    
    @IBAction func commentsEdited(_ sender: Any) {
        if self.commentsField.stringValue == commentsIfAllEqual { return }
        if self.commentsField.stringValue == "" && self.commentsIfAllEqual == nil { return }
        databaseManager.commentsEdited(tracks: self.selectedTracks!, value: self.commentsField.stringValue)
        self.commentsIfAllEqual = self.commentsField.stringValue
        mainWindowController?.refreshCurrentSortOrder()
    }
    
    @IBAction func monthChecked(_ sender: Any) {
        if monthCheck.state == NSControl.StateValue.on {
            let month = Int(self.monthField.selectedItem!.title)
            self.releaseDateComponents?.month = month
            let days = Calendar.current.range(of: .day, in: .month, for: self.releaseDateComponents!.date!)!
            self.dayField.menu?.removeAllItems()
            for day in days.lowerBound..<days.upperBound {
                self.dayField.menu?.addItem(withTitle: String(day), action: nil, keyEquivalent: "")
            }
        } else {
            dayCheck.state = NSControl.StateValue.off
        }
        datePickerAction(self)
    }
    
    
    
    @IBAction func datePickerAction(_ sender: AnyObject) {
        if self.releaseDateCheck.state == NSControl.StateValue.on {
            if self.releaseDateComponents == nil {
                self.releaseDateComponents = DateComponents()
                self.releaseDateComponents?.calendar = Calendar.current
            }
            if let year = Int(self.yearField.stringValue) {
                self.releaseDateComponents?.year = year
                if monthCheck.state == NSControl.StateValue.on {
                    if let month = Int(monthField.selectedItem!.title) {
                        self.releaseDateComponents?.month = month
                        if dayCheck.state == NSControl.StateValue.on {
                            let day = Int(dayField.selectedItem!.title)!
                            self.releaseDateComponents?.day = day
                        } else {
                            self.releaseDateComponents?.day = nil
                            self.releaseDateComponents?.weekday = nil
                        }
                    }
                } else {
                    self.releaseDateComponents?.month = nil
                }
            }
        } else {
            self.releaseDateComponents?.year = nil
            self.monthCheck.state = NSControl.StateValue.off
            self.dayCheck.state = NSControl.StateValue.off
        }
        if self.releaseDateComponents?.date != nil && self.releaseDateComponents?.year != nil {
            let newJMDate = JMDate(year: self.releaseDateComponents!.year!, month: self.releaseDateComponents?.month, day: self.releaseDateComponents?.day)
            databaseManager.releaseDateEdited(tracks: self.selectedTracks!, value: newJMDate)
        }
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
        let names = Set(selectedTracks!.map( { return $0.name! } ))
        if names.count == 1 {
            nameField.stringValue = names.first!
            self.nameIfAllEqual = names.first!
            sortingNameField.stringValue = names.first!
        } else {
            nameField.placeholderString = kMultipleThingsString
        }
        let artist_names = selectedTracks!.map( { return $0.artist?.name } )
        if allEqual(artist_names) == true {
            if artist_names[0] != nil {
                artist = artist_names[0]!
                artistField.stringValue = artist_names[0]!
                artistNameIfAllEqual = artist
                sortingArtistField.stringValue = artist_names[0]!
            }
        } else {
            artistField.placeholderString = kMultipleThingsString
        }
        let album_names = selectedTracks!.map( { return $0.album?.name } )
        if allEqual(album_names) == true {
            if album_names[0] != nil {
                album = album_names[0]!
                albumField.stringValue = album_names[0]!
                albumNameIfAllEqual = album
                sortingAlbumField.stringValue = album_names[0]!
            }
            populateArtwork()
        } else {
            if album_names.count > 1 {
                albumField.placeholderString = kMultipleThingsString
            }
        }
        let album_artist_names = selectedTracks!.map( { return $0.album?.album_artist?.name } )
        if allEqual(album_artist_names) == true {
            if album_artist_names[0] != nil {
                albumArtist = album_artist_names[0]!
                albumArtistField.stringValue = album_artist_names[0]!
                albumArtistNameIfAllEqual = albumArtist
                sortingAlbumArtistField.stringValue = album_artist_names[0]!
            }
        } else {
            if album_artist_names.count > 1 {
                albumArtistField.placeholderString = kMultipleThingsString
            }
        }
        let comments = selectedTracks!.map( { return $0.comments } )
        if allEqual(comments) == true {
            if comments[0] != nil {
                commentsField.stringValue = comments[0]!
                commentsIfAllEqual = comments[0]!
            }
        } else {
            if comments.count > 1 {
                commentsField.placeholderString = kMultipleThingsString
            }
        }
        let composers = selectedTracks!.map( { return $0.composer?.name } )
        if allEqual(composers) == true {
            if composers[0] != nil {
                composerField.stringValue = composers[0]!
                sortingComposerField.stringValue = composers[0]!
                composer = composers[0]!
                composerNameIfAllEqual = composer
            }
        } else {
            if composers.count > 1 {
                composerField.placeholderString = kMultipleThingsString
            }
        }
        let release_dates = selectedTracks!.map({ return $0.album?.release_date })
        if allEqual(release_dates) == true {
            if release_dates[0] != nil {
                let jmDate = release_dates[0]!
                releaseDateCheck.state = NSControl.StateValue.on
                self.releaseDateComponents = Calendar.current.dateComponents(self.componentSet, from: release_dates[0]!.date as Date)
                self.releaseDateComponents?.calendar = Calendar.current
                self.releaseDateComponents?.weekday = nil
                self.yearField.stringValue = String(self.releaseDateComponents!.year!)
                if jmDate.hasMonth == true {
                    let month = self.releaseDateComponents!.month!
                    self.monthCheck.state = NSControl.StateValue.on
                    self.monthField.selectItem(at: month - 1)
                    let days = Calendar.current.range(of: .day, in: .month, for: self.releaseDateComponents!.date!)!
                    self.dayField.menu?.removeAllItems()
                    for day in days.lowerBound..<days.upperBound {
                        self.dayField.menu?.addItem(withTitle: String(day), action: nil, keyEquivalent: "")
                    }
                    if jmDate.hasDay {
                        let day = releaseDateComponents!.day!
                        self.dayCheck.state = NSControl.StateValue.on
                        self.dayField.selectItem(at: day - 1)
                    }
                }
            } else {
                releaseDateCheck.state = NSControl.StateValue.off
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
        } else {
            if genres.count > 1 {
                genreField.placeholderString = kMultipleThingsString
            }
        }
        let is_compilations = selectedTracks!.map({return $0.album?.is_compilation})
        if allEqual(is_compilations) {
            if is_compilations[0] != nil {
                compilationButton.state = is_compilations[0]! == NSNumber(value: true as Bool) ? NSControl.StateValue.on : NSControl.StateValue.off
            }
        }
        let ratings = selectedTracks!.map({return $0.rating})
        let sortNames = selectedTracks!.flatMap({return $0.sort_name})
        let sortNamesSet = Set(sortNames)
        if sortNamesSet.count == 1 && sortNames.count == selectedTracks?.count {
            sortingNameSortAsField.stringValue = sortNames.first!
            sortNameIfAllEqual = sortNames.first!
        } else {
            if sortNames.count > 1 {
                sortingNameSortAsField.placeholderString = kMultipleThingsString
            }
        }
        let sortAlbums = selectedTracks!.flatMap({return $0.sort_album})
        let sortAlbumsSet = Set(sortAlbums)
        if sortAlbumsSet.count == 1 && sortAlbums.count == selectedTracks?.count {
            sortingAlbumSortAsField.stringValue = sortAlbums.first!
            sortAlbumIfAllEqual = sortAlbums.first!
        } else {
            if sortAlbums.count > 1 {
                sortingAlbumSortAsField.placeholderString = kMultipleThingsString
            }
        }
        let sortArtists = selectedTracks!.flatMap({return $0.sort_artist})
        let sortArtistsSet = Set(sortArtists)
        if sortArtistsSet.count == 1 && sortArtists.count == selectedTracks?.count {
            sortingArtistSortAsField.stringValue = sortArtists.first!
            sortArtistIfAllEqual = sortArtists.first!
        } else {
            if sortArtists.count > 1 {
                sortingArtistSortAsField.placeholderString = kMultipleThingsString
            }
        }
        let sortAlbumArtists = selectedTracks!.flatMap({return $0.sort_album_artist})
        let sortAlbumArtistsSet = Set(sortAlbumArtists)
        if sortAlbumArtistsSet.count == 1 && sortAlbumArtists.count == selectedTracks?.count {
            sortingAlbumArtistSortAsField.stringValue = sortAlbumArtists.first!
            sortAlbumArtistIfAllEqual = sortAlbumArtists.first!
        } else {
            if sortAlbumArtists.count > 1 {
                sortingAlbumArtistSortAsField.placeholderString = kMultipleThingsString
            }
        }
        let sortComposers = selectedTracks!.flatMap({return $0.sort_composer})
        let sortComposersSet = Set(sortComposers)
        if sortComposersSet.count == 1 && sortComposers.count == selectedTracks?.count{
            sortingComposerSortAsField.stringValue = sortComposers.first!
            sortComposerIfAllEqual = sortComposers.first!
        } else {
            if sortComposers.count > 1 {
                sortingComposerSortAsField.placeholderString = kMultipleThingsString
            }
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
            segControl.setEnabled(false, forSegment: 2)
            segControl.setWidth(0.00001, forSegment: 2)
            tabView.removeTabViewItem(fileInfoTab)
        } else {
            currentTrack = selectedTracks![0]
            populateFileInfo()
        }
        populateFields()
    }
    
    //mark artwork view
    @IBOutlet weak var artworkTargetView: NSView!
    
    func populateArtwork() {
        guard let album = selectedTracks![0].album else { return }
        //change some layout stuff
        self.albumFilesViewController = AlbumFilesViewController(nibName: NSNib.Name(rawValue: "AlbumFilesViewController"), bundle: nil)
        self.albumFilesViewController?.track = selectedTracks![0]
        self.artworkTargetView.addSubview(self.albumFilesViewController!.view)
        self.albumFilesViewController!.view.leadingAnchor.constraint(equalTo: self.artworkTargetView.leadingAnchor).isActive = true
        self.albumFilesViewController!.view.trailingAnchor.constraint(equalTo: self.artworkTargetView.trailingAnchor).isActive = true
        self.albumFilesViewController!.view.topAnchor.constraint(equalTo: self.artworkTargetView.topAnchor).isActive = true
        self.albumFilesViewController!.view.bottomAnchor.constraint(equalTo: self.artworkTargetView.bottomAnchor).isActive = true
        let heightConstraint = self.albumFilesViewController?.otherArtBox.constraints.filter({return $0.firstAttribute == .height})
        NSLayoutConstraint.deactivate(heightConstraint!)
        let newConstraint = NSLayoutConstraint(item: self.albumFilesViewController?.otherArtBox, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 90.0)
        NSLayoutConstraint.activate([newConstraint])
        let flowLayout = self.albumFilesViewController?.collectionView.collectionViewLayout as! NSCollectionViewFlowLayout
        flowLayout.itemSize = NSSize(width: 50.0, height: 60.0)
        self.albumFilesViewController?.initializesPrimaryImageConstraint = false
        for constraint in self.albumFilesViewController!.imageView.constraints.filter({return $0.firstAttribute == .height && $0.secondAttribute == .width}) {
            constraint.isActive = false
        }
        self.albumFilesViewController?.otherArtBox.borderType = .bezelBorder
        
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
        let url = NSURL(string: self.currentTrack!.location!)!
        self.locationPathControl.url = url as URL
        
        let mdItem = MDItemCreateWithURL(kCFAllocatorDefault, url)
        if url.pathExtension?.lowercased() == "flac" {
            self.flacMDItem = FlacDecoder(file: url as URL, audioModule: nil)
            flacMDItem?.initForMetadata()
        }
        let kind = MDItemCopyAttribute(mdItem, kMDItemKind) as? String
        kindLabel.stringValue = kind!
        let duration = MDItemCopyAttribute(mdItem, kMDItemDurationSeconds) as? Int ?? (Int(flacMDItem!.totalFrames / flacMDItem!.sampleRate!))
        durationLabel.stringValue = getTimeAsString(Double(duration))!
        let size = MDItemCopyAttribute(mdItem, kMDItemFSSize) as! Int
        sizeLabel.stringValue = fileSizeFormatter.string(fromByteCount: Int64(size))
        let bitRateCheck = (MDItemCopyAttribute(mdItem, kMDItemAudioBitRate) as? Int ?? (((size ) * 8) / 1000) / duration) / 1000
        bitRateLabel.stringValue = bitRateFormatter.string(for: bitRateCheck)!
        let sampleRateCheck = MDItemCopyAttribute(mdItem, kMDItemAudioSampleRate) as? Int ?? Int(flacMDItem!.sampleRate!)
        sampleRateLabel.stringValue = sampleRateFormatter.string(for: sampleRateCheck)!
        let channels = MDItemCopyAttribute(mdItem, kMDItemAudioChannelCount) as? Int ?? Int(flacMDItem!.channels!)
        channelsLabel.stringValue = String(describing: channels)
        let encoder = MDItemCopyAttribute(mdItem, kMDItemAudioEncodingApplication) as? String
        encoderLabel.stringValue = encoder != nil ? encoder! : "No encoder information available."
        let dateModified = MDItemCopyAttribute(mdItem, kMDItemContentModificationDate) as? NSDate
        dateModifiedLabel.stringValue = dateModified != nil ? dateModified!.description : ""
        let dateAdded = MDItemCopyAttribute(mdItem, kMDItemDateAdded) as? NSDate
        dateAddedLabel.stringValue = dateAdded != nil ? dateAdded!.description : ""
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
    
    @IBAction func previousTrackPressed(_ sender: Any) {
        
    }
    
    @IBAction func nextTrackPressed(_ sender: Any) {
        
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        initForSelection()
        tabView.drawsBackground = false
        self.window?.titlebarAppearsTransparent = true
        self.window!.titleVisibility = .hidden
        self.window?.isMovableByWindowBackground = true
    }
    
}
