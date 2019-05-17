//
//  ArtistListViewController.swift
//  jmc
//
//  Created by John Moody on 5/22/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class ArtistListViewController: NSViewController, NSTableViewDelegate {

    @IBOutlet var artistArrayController: NSArrayController!
    @IBOutlet weak var tableView: NSTableView!
    
    var artistViewController: ArtistViewController?
    var managedContext = (NSApplication.shared.delegate as! AppDelegate).managedObjectContext
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedArtists = artistArrayController.selectedObjects as! [Artist]
        artistViewController!.newArtistSelected(artist: selectedArtists[0])
    }
    
    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, artistViewController: ArtistViewController) {
        self.artistViewController = artistViewController
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
