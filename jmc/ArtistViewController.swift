//
//  ArtistViewController.swift
//  jmc
//
//  Created by John Moody on 5/21/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa


class ArtistViewController: NSViewController {
    
    
    @IBOutlet weak var splitView: NSSplitView!
    
    
    var artistListView: ArtistListViewController?
    var albumsView: ArtistViewAlbumViewController?
    
    var cachedViewControllers = [Artist : ArtistViewAlbumViewController]()
    
    func newArtistSelected(artist: Artist) {
        albumsView?.view.removeFromSuperview()
        let newAlbumsView = ArtistViewAlbumViewController(nibName: "ArtistViewAlbumViewController", bundle: nil, artist: artist)
        splitView.addArrangedSubview(newAlbumsView!.view)
        self.albumsView = newAlbumsView
        self.cachedViewControllers[artist] = newAlbumsView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.artistListView = ArtistListViewController(nibName: "ArtistListViewController", bundle: nil, artistViewController: self)
        self.splitView.addArrangedSubview(artistListView!.view)
    }
}
