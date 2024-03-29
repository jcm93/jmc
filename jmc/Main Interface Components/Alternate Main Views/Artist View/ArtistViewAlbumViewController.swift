//
//  ArtistViewAlbumViewController.swift
//  jmc
//
//  Created by John Moody on 5/22/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa
import CoreMedia

class ArtistViewAlbumViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var tableView: ArtistListTableView!
    @IBOutlet weak var albumArtworkView: NSImageView!
    var artists: [Artist]
    @objc var albums = [Album]()
    var views = [Int : ArtistViewAlbumDataStore]()
    var albumTracksDictionary: [Album : [TrackView]] = [Album : [TrackView]]()
    @IBOutlet var albumArrayController: NSArrayController!
    var artistViewController: ArtistViewController
    var tracks: [TrackView]
    var toBeSelected: [TrackView]?
    var selectionHandler = ArtistViewTrackSelectionDelegate()
    
    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, artists: [Artist], artistViewController: ArtistViewController) {
        self.artistViewController = artistViewController
        self.artists = artists
        let filteredPlaylistTracks = Set(self.artistViewController.trackViewArrayController.arrangedObjects as! [TrackView])
        let artistTracks = Set(artists.flatMap({return ($0.tracks as! Set<Track>).map({return $0.view!})}))
        self.tracks = Array(filteredPlaylistTracks.intersection(artistTracks)).sorted(by: {return $0.album_artist_order!.isLessThan($1.album_artist_order!)})
        //self.tracks = artists.flatMap({return ($0.tracks as! Set<Track>).map({return $0.view!})}).sorted(by: {return $0.album_artist_order!.isLessThan($1.album_artist_order!)})
        //self.tracks = (self.artistViewController.trackViewArrayController.arrangedObjects as! [TrackView]).filter({return artists.contains($0.track!.artist!)}).sorted(by: {return $0.album_artist_order!.isLessThan($1.album_artist_order!)})
        var albumSet = Set<Album>()
        tracks.forEach({
            let album = $0.track!.album!
            if let existingAlbum = albumSet.first(where: {$0.name == album.name}) {
                $0.track?.album = existingAlbum
            } else {
                albumSet.insert(album)
            }
        })
        self.albums = Array(albumSet).sorted(by: {return ($0.name ?? "") < ($1.name ?? "")})
        super.init(nibName: nibNameOrNil.map { $0 }, bundle: nibBundleOrNil)
    }
    
    func refreshTable() {
        self.tracks = (self.artistViewController.trackViewArrayController.arrangedObjects as! [TrackView]).filter({return artists.contains($0.track!.artist!)}).sorted(by: {$0.album_artist_order!.isLessThan($1.album_artist_order!)})
        self.albums = Array(Set(self.tracks.map({return $0.track!.album!})))
        self.reloadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ArtistViewTableCellView"), owner: self) as! ArtistViewTableCellView
        let album = (albumArrayController.arrangedObjects as! NSArray)[row] as! Album
        view.album = album
        view.artistViewController = self.artistViewController
        if let dataStore = self.views[row] {
            //view.trackListTableViewDelegate.tracksArrayController.setSelectionIndexes(dataStore.selectionIndexes)
            view.dataStore = dataStore
        } else {
            let newDataStore = ArtistViewAlbumDataStore()
            newDataStore.album = album
            newDataStore.row = row
            self.views[row] = newDataStore
            view.dataStore = newDataStore
        }
        view.populateTracksTable(album: album, tracks: self.tracks.filter({$0.track!.album! == album}), artistViewController: self.artistViewController)
        //manage selection
        return view
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        print("returning album count")
        return albums.count
    }
    
    func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        return IndexSet()
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let album = self.albums[row]
        let numTracks = self.tracks.filter({$0.track?.album == album}).count
        let prospectiveHeight = CGFloat(numTracks * 24) + 100
        return prospectiveHeight > 400 ? prospectiveHeight : 400
    }
    
    func getTrackWithNoContext(_ shuffleState: Int) -> Track? {
        return nil
    }
    
    func scrollToNewTrack() {
        let track = self.artistViewController.mainWindowController!.currentTrack!
        //let albumCell = self.views.values.first(where: {$0.album!.tracks!.contains(track)})
        //let rowIndex = self.views.first(where: {$0.value == albumCell})!.key
        //self.tableView.scrollRowToVisible(rowIndex)
    }
    
    func jumpToSelection() {
        self.tableView.scrollRowToVisible(self.tableView.selectedRow)
    }
    
    func reloadData() {
        self.tableView.reloadData()
    }
    
    func initializeForLibrary() {
        self.albumArrayController.filterPredicate = nil
        self.albumArrayController.fetchPredicate = nil
    }
    
    func getCurrentShownTrackViews() -> [TrackView] {
        //return self.views.flatMap({return ($0.value.trackListTableViewDelegate.tracksArrayController.arrangedObjects as! [TrackView])})
        return [TrackView]()
    }
    
    func getUpcomingIDsForPlayEvent(_ shuffleState: Int, id: Int, row: Int) -> Int {
        let trackArray = self.tracks.map({return $0.track!})
        //let trackArray = self.views.flatMap({return ($0.value.trackListTableViewDelegate.tracksArrayController.arrangedObjects as! [TrackView]).compactMap({return $0.track})})
        let idArray = trackArray.map({return Int($0.id!)})
        if shuffleState == NSControl.StateValue.on.rawValue {
            //if the array is already shuffled, but we're picking a new track
            let currentShuffleArray = self.artistViewController.item!.artistPlayOrderObject!.shuffledPlayOrder!
            let indexToSwap = currentShuffleArray.firstIndex(of: id)!
            let beginningOfArray = currentShuffleArray[0..<indexToSwap]
            let endOfArray = currentShuffleArray[indexToSwap..<currentShuffleArray.count]
            let newArraySliceConcatenation = endOfArray + beginningOfArray
            self.artistViewController.item?.artistPlayOrderObject?.shuffledPlayOrder = Array(newArraySliceConcatenation)
            if self.artistViewController.item!.artistPlayOrderObject!.currentPlayOrder! != self.artistViewController.item!.artistPlayOrderObject!.shuffledPlayOrder! {
                let idSet = Set(idArray)
                self.artistViewController.item?.artistPlayOrderObject?.currentPlayOrder = self.artistViewController.item!.artistPlayOrderObject!.shuffledPlayOrder!.filter({idSet.contains($0)})
            } else {
                self.artistViewController.item?.artistPlayOrderObject?.currentPlayOrder = self.artistViewController.item!.artistPlayOrderObject!.shuffledPlayOrder!
            }
            return 0
        } else {
            self.artistViewController.item?.artistPlayOrderObject?.currentPlayOrder = idArray
            if row > -1 {
                return row
            } else {
                return idArray.firstIndex(of: id)!
            }
        }
        /*let idArray = (trackViewArrayController.arrangedObjects as! [TrackView]).map({return Int($0.track!.id!)})
        if shuffleState == NSControl.StateValue.on.rawValue {
            //secretly adjust the shuffled array such that it behaves mysteriously like a ring buffer. ssshhhh
            let currentShuffleArray = self.item!.playOrderObject!.shuffledPlayOrder!
            let indexToSwap = currentShuffleArray.firstIndex(of: id)!
            let beginningOfArray = currentShuffleArray[0..<indexToSwap]
            let endOfArray = currentShuffleArray[indexToSwap..<currentShuffleArray.count]
            let newArraySliceConcatenation = endOfArray + beginningOfArray
            self.item?.playOrderObject?.shuffledPlayOrder = Array(newArraySliceConcatenation)
            if self.item!.playOrderObject!.currentPlayOrder! != self.item!.playOrderObject!.shuffledPlayOrder! {
                let idSet = Set(idArray)
                self.item?.playOrderObject?.currentPlayOrder = self.item!.playOrderObject!.shuffledPlayOrder!.filter({idSet.contains($0)})
            } else {
                self.item?.playOrderObject?.currentPlayOrder = self.item!.playOrderObject!.shuffledPlayOrder!
            }
            return 0
        } else {
            self.item?.playOrderObject?.currentPlayOrder = idArray
            if row > -1 {
                return row
            } else {
                return idArray.firstIndex(of: id)!
            }
        }*/
    }
    
    func getSelectedTrackViews() -> [TrackView] {
        let selectedTrackViews = self.views.values.flatMap({ dataStore -> [Track] in
            let tracks = dataStore.album.tracks as! Set<Track>
            let tracksArray = Array(tracks).sorted(by: {$0.view!.album_artist_order!.isLessThan($1.view!.album_artist_order)})
            let selectedTracksFromAlbum = dataStore.selectionIndexes.map({ index -> Track in
                return tracksArray[index]
            })
            return selectedTracksFromAlbum
        }).map({return $0.view!})
        return selectedTrackViews
        /*var result = [TrackView]()
        var count = 0
        for _ in self.views {
            let selection = self.views[count]!
            //result += selection.getSelectedObjects()
            count += 1
        }
        return result*/
    }
    
    func selectTrackViews(_ trackViews: [TrackView]) {
        self.toBeSelected = trackViews
    }
    
    func reloadNowPlayingForTrack(_ track: Track) {
        //let albumCell = self.views.values.first(where: {$0.album!.tracks!.contains(track)})
        //albumCell?.reloadNowPlayingForTrack(track)
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.albumArrayController.content = self.albums
        self.tableView.mainWindowController = self.artistViewController.mainWindowController
        self.selectionHandler.parent = self
        //self.artistViewController.artistListView.tableView.mainWindowController = self.artistViewController.mainWindowController
        if #available(macOS 12.0, *) {
            //(self.artistViewController.mainWindowController?.avPlayerAudioModule.appleMusicTrackIdentifier as! AppleMusicTrackIdentifier).initializeLibrary()
         }
    }
    
}
