//
//  ArtistListViewController.swift
//  jmc
//
//  Created by John Moody on 5/22/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class ArtistListViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    var artistArrayController: NSArrayController!
    var artistsToSelect: [Artist]?
    @IBOutlet weak var tableView: ArtistListTableView!
    
    var artistViewController: ArtistViewController!
    @objc var managedContext = (NSApplication.shared.delegate as! AppDelegate).managedObjectContext
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRows = self.tableView.selectedRowIndexes
        artistArrayController.setSelectionIndexes(selectedRows)
        let selectedArtists = artistArrayController.selectedObjects as! [Artist]
        artistViewController!.newArtistsSelected(artists: selectedArtists)
    }
    
    func jumpToArtist(_ artist: Artist) {
        let artists = artistArrayController.arrangedObjects as! [Artist]
        let row = artists.startIndex.distance(to: artists.firstIndex(of: artist)!)
        self.tableView.scrollRowToVisible(row)
    }
    
    func jumpToSelection() {
        self.tableView.scrollRowToVisible(self.tableView.selectedRow)
    }
    
    func reloadData() {
        self.tableView.reloadData()
    }
    
    func initializeForLibrary() {
        self.artistArrayController.filterPredicate = nil
        self.artistArrayController.fetchPredicate = nil
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return (self.artistArrayController.arrangedObjects as! [Artist])[row]
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return (self.artistArrayController.arrangedObjects as! [Artist]).count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return CGFloat(27)
    }
    
    func setFilterPredicate(_ searchFieldContent: String) {
        //naive
        /*let searchTokens = searchFieldContent.components(separatedBy: " ").filter({return $0 != ""})
        var subPredicates = [NSPredicate]()
        for token in searchTokens {
            //not accepted by NSPredicateEditor
            //let newPredicate = NSPredicate(format: "ANY {track.name, track.artist.name, track.album.name, track.composer.name, track.comments, track.genre.name} contains[cd] %@", token)
            //accepted by NSPredicateEditor
            let newPredicate = NSPredicate(format: "tracks.name contains[cd] %@ OR name contains[cd] %@ OR albums.name contains[cd] %@ OR composers.name contains[cd] %@ OR track.genre contains[cd] %@", token, token, token, token, token, token)
            subPredicates.append(newPredicate)
        }
        if subPredicates.count > 0 {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
            self.trackViewArrayController.filterPredicate = predicate
            //currentLibraryViewController?.trackViewArrayController.filterPredicate = predicate
            self.searchString = searchFieldContent
        } else {
            self.trackViewArrayController.filterPredicate = nil
            //currentLibraryViewController?.trackViewArrayController.filterPredicate = nil
            self.searchString = nil
        }*/
    }
    
    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, artistViewController: ArtistViewController) {
        self.artistViewController = artistViewController
        
        super.init(nibName: nibNameOrNil.map { $0 }, bundle: nibBundleOrNil)
        let artists = (self.artistViewController.trackViewArrayController.arrangedObjects as! [TrackView]).map({return $0.track!.artist})
        let uniqueArtists = Set(Array(artists))
        self.artistArrayController = NSArrayController(content: uniqueArtists)
        let artistSortDescriptor = NSSortDescriptor(key: "nameForSorting", ascending: true, selector: "localizedStandardCompare:")
        self.artistArrayController.sortDescriptors = [artistSortDescriptor]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refreshArtistArrayContent() {
        let selectedRows = self.tableView.selectedRowIndexes
        artistArrayController.setSelectionIndexes(selectedRows)
        let selectedArtists = artistArrayController.selectedObjects as! [Artist]
        let artists = (self.artistViewController.trackViewArrayController.arrangedObjects as! [TrackView]).map({return $0.track!.artist})
        let uniqueArtists = Set(Array(artists))
        self.artistArrayController.content = uniqueArtists
        self.tableView.reloadData()
        selectArtists(artists: selectedArtists)
    }
    
    func selectArtists(artists: [Artist]) {
        self.artistsToSelect = artists
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let currentArtistArray = self.artistArrayController.arrangedObjects as? [Artist] {
            if self.artistsToSelect != nil && self.artistsToSelect!.count > 0 {
                let selectionIndexes = self.artistsToSelect!.map({return currentArtistArray.startIndex.distance(to: currentArtistArray.firstIndex(of: $0)!)})
                let newIndexSet = IndexSet(selectionIndexes)
                self.tableView.selectRowIndexes(newIndexSet, byExtendingSelection: false)
                self.tableView.scrollRowToVisible(newIndexSet.first!)
                self.artistsToSelect = [Artist]()
            }
        }
    }
    
}
