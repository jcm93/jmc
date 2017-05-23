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
    var artist: Artist
    var albums = [Album]()
    @IBOutlet var albumArrayController: NSArrayController!
    
    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, artist: Artist) {
        self.artist = artist
        self.albums = Array(Set(self.artist.tracks!.flatMap({return ($0 as! Track).album})))
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.make(withIdentifier: "ArtistViewTableCellView", owner: self) as! ArtistViewTableCellView
        view.populateTracksTable((albumArrayController.arrangedObjects as! NSArray)[row] as! Album)
        print("populated a table row")
        return view
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        print("returning album count")
        return albums.count
    }
    
    /*func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        <#code#>
    }*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.albumArrayController.content = self.albums
    }
    
}
