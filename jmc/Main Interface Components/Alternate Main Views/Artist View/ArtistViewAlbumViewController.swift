//
//  ArtistViewAlbumViewController.swift
//  jmc
//
//  Created by John Moody on 5/22/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class ArtistViewAlbumViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var albumArtworkView: NSImageView!
    var artist: Artist
    @objc var albums = [Album]()
    var views = [Int : ArtistViewTableCellView]()
    @IBOutlet var albumArrayController: NSArrayController!
    
    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, artist: Artist) {
        self.artist = artist
        self.albums = Array(Set(self.artist.tracks!.compactMap({return ($0 as! Track).album})))
        super.init(nibName: nibNameOrNil.map { $0 }, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ArtistViewTableCellView"), owner: self) as! ArtistViewTableCellView
        view.populateTracksTable((albumArrayController.arrangedObjects as! NSArray)[row] as! Album)
        //self.views[row] = view
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
        let numTracks = self.albums[row].tracks?.count ?? 300
        let prospectiveHeight = CGFloat(numTracks * 25)
        return prospectiveHeight > 300 ? prospectiveHeight : 300
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.albumArrayController.content = self.albums
        self.tableView.deselectAll(nil)
    }
    
}
