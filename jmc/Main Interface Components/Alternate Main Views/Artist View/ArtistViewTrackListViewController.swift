//
//  ArtistViewTrackListViewController.swift
//  jmc
//
//  Created by John Moody on 5/22/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class ArtistViewTrackListViewController: NSViewController {
    
    var album: Album
    var trackArray = [Track]()
    @IBOutlet weak var tableView: NSTableView!
    
    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, album: Album) {
        self.album = album
        self.trackArray = (self.album.tracks!.allObjects as! [Track]).sorted(by: {(t1: Track, t2: Track) -> Bool in
            let firstValue = t1.track_num?.intValue ?? 0
            let secondValue = t2.track_num?.intValue ?? 0
            return firstValue < secondValue
            })
        super.init(nibName: nibNameOrNil.map { $0 }, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
