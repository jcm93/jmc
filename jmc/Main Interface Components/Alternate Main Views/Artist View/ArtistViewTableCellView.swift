//
//  ArtistViewTableCellView.swift
//  jmc
//
//  Created by John Moody on 5/22/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class ArtistViewTableCellView: NSTableRowView {
    
    @IBOutlet var artistImageView: NSImageView!
    @IBOutlet var albumNameLabel: NSTextField!
    @IBOutlet var albumInfoLabel: NSTextField!
    @IBOutlet weak var tracksTableView: ArtistViewTracksTableView!
    var trackListTableViewDelegate: ArtistViewAlbumTrackListTableViewDelegate!
    var numberFormatter = NumberFormatter()
    var dateFormatter = DateComponentsFormatter()
    var sizeFormatter = ByteCountFormatter()
    var infoString = ""
    var artistViewController: ArtistViewController!
    var rightMouseDownTarget: [Track]?
    //var tracksArrayController: NSArrayController!
    //var tracksViewController: ArtistViewTrackListViewController?
    var toBeSelected: [TrackView]?
    
    
    var album: Album?
    
    func refreshArtView(track: Track, found: Bool, background: Bool) {
        if background {
            do {
                try backgroundContext.save()
            } catch {
                print("error saving background context")
            }
        }
        DispatchQueue.main.async {
            if found {
                if let loc = self.album?.primary_art?.location {
                    if let url = URL(string: loc) {
                        if let image = NSImage(contentsOf: url) {
                            self.artistImageView.image = image
                            self.resizeImageViewForArt()
                        }
                    }
                }
            } else {
                self.artistImageView.image = nil
                self.resizeImageViewForArt()
            }
        }
    }
    
    func resizeImageViewForArt() {
        let widthConstraint = artistImageView!.constraints.filter({$0.firstAttribute == .width})
        let heightConstraint = artistImageView!.constraints.filter({$0.firstAttribute == .height})
        NSLayoutConstraint.deactivate(widthConstraint)
        NSLayoutConstraint.deactivate(heightConstraint)
        var newConstraints = [NSLayoutConstraint]()
        if let image = self.artistImageView?.image {
            let aspectRatio = image.size.width / image.size.height
            if image.size.height > image.size.width {
                let newHeightConstraint = NSLayoutConstraint(item: self.artistImageView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 300.0)
                let newWidth = 300.0 * aspectRatio
                let newWidthConstraint = NSLayoutConstraint(item: self.artistImageView!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: newWidth)
                newConstraints = [newHeightConstraint, newWidthConstraint]
            } else {
                let newWidthConstraint = NSLayoutConstraint(item: self.artistImageView!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 300.0)
                let newHeight = 300.0 * (1.0 / aspectRatio)
                let newHeightConstraint = NSLayoutConstraint(item: self.artistImageView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: newHeight)
                newConstraints = [newWidthConstraint, newHeightConstraint]
            }
            NSLayoutConstraint.activate(newConstraints)
        } else {
            let newHeightConstraint = NSLayoutConstraint(item: self.artistImageView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 300.0)
            let newWidthConstraint = NSLayoutConstraint(item: self.artistImageView!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 300.0)
            newConstraints = [newWidthConstraint, newHeightConstraint]
            NSLayoutConstraint.activate(newConstraints)
        }
    }
    
    func populateTracksTable(album: Album, tracks: [TrackView], artistViewController: ArtistViewController) {
        self.dateFormatter.unitsStyle = .full
        self.album = album
        self.artistViewController = artistViewController
        self.trackListTableViewDelegate = ArtistViewAlbumTrackListTableViewDelegate(album: album, tracks: tracks, parent: self)
        self.tracksTableView.delegate = self.trackListTableViewDelegate
        self.tracksTableView.dataSource = self.trackListTableViewDelegate
        self.tracksTableView.artistViewTableCellView = self
        self.tracksTableView.doubleAction = #selector(doubleAction)
        
        
        //self.tracksViewController = ArtistViewTrackListViewController(nibName: "ArtistViewTrackListViewController", bundle: nil, album: self.album!)
        //self.tracksView.addSubview(tracksViewController!.view)
        //Swift.print(self.tracksViewController!.trackArray.count)
        if album.primary_art != nil {
            print("odnglkew")
        }
        if let loc = album.primary_art?.location {
            if let url = URL(string: loc) {
                if let image = NSImage(contentsOf: url) {
                    self.artistImageView.image = image
                    //resizeImageViewForArt()
                }
            }
        } else {
            let foregroundObjectID = (album.tracks!.anyObject() as! Track).objectID
            backgroundContext.perform {
                let bgTrack = backgroundContext.object(with: foregroundObjectID) as! Track
                self.artistViewController.databaseManager.tryFindPrimaryArtForTrack(bgTrack, callback: self.refreshArtView, background: true)
            }
        }
        //let currentConstraint = self.tracksView.constraints.filter({return $0.firstAttribute == .height})
        //NSLayoutConstraint.deactivate(currentConstraint)
        //let constraint = NSLayoutConstraint(item: self.tracksView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(self.tracksViewController!.trackArray.count + 1) * self.tracksViewController!.tableView.rowHeight)
        //NSLayoutConstraint.activate([constraint])
        self.albumNameLabel.stringValue = self.album!.name!
        self.artistImageView.wantsLayer = true
        self.artistImageView.layer?.cornerRadius = 10
        //self.tracksViewController!.view.frame = self.tracksView.bounds
        let trackArray = self.album!.tracks!.allObjects as! [Track]
        
        let numItems = trackArray.count as NSNumber
        let totalSize = trackArray.lazy.map({return ($0.size?.int64Value)}).reduce(0, {$0 + ($1 != nil ? $1! : 0)})
        let totalTime = trackArray.lazy.map({return ($0.time?.doubleValue)}).reduce(0, {$0 + ($1 != nil ? $1! : 0)})
        let numString = self.numberFormatter.string(from: numItems)
        let sizeString = self.sizeFormatter.string(fromByteCount: totalSize)
        let timeString = self.dateFormatter.string(from: totalTime/1000)
        let infoString = "\(numString!) items; \(timeString!); \(sizeString)"
        self.albumInfoLabel.stringValue = infoString
        
        
    }
    
    func getSelectedObjects() -> [TrackView] {
        let selection = self.tracksTableView.selectedRowIndexes
        let albumTracks = self.trackListTableViewDelegate.tracks as NSArray
        let selectedTracks = albumTracks.objects(at: selection) as! [TrackView]
        return selectedTracks
    }
    
    func selectTrackViews() {
        //self.trackListTableViewDelegate.selectTrackViews(self.toBeSelected!)
        //self.tracksTableView.selectRowIndexes(self.trackListTableViewDelegate.tracksArrayController.selectionIndexes, byExtendingSelection: false)
        //self.tracksTableView.layout()
    }
    
    func interpretSpacebarEvent() {
        self.artistViewController.interpretSpacebarEvent()
    }
    
    @objc func doubleAction() {
        guard self.tracksTableView!.selectedRow >= 0 && self.tracksTableView!.clickedRow >= 0 else {
            return
        }
        let item = (self.trackListTableViewDelegate.tracksArrayController.arrangedObjects as! [TrackView])[self.tracksTableView.selectedRow].track
        self.artistViewController.playSong(item!, row: self.tracksTableView!.selectedRow)
    }
    
    func interpretDeleteEvent() {
        
    }
    
    func interpretEnterEvent() {
        guard self.tracksTableView!.selectedRow >= 0 else {
            return
        }
        let item = (self.trackListTableViewDelegate.tracksArrayController.arrangedObjects as! [TrackView])[self.tracksTableView.selectedRow].track
        self.artistViewController.playSong(item!, row: self.tracksTableView!.selectedRow)
    }
    
    func determineRightMouseDownTarget() {
        
    }
    
    func reloadNowPlayingForTrack(_ track: Track) {
        guard let row = (self.trackListTableViewDelegate.tracksArrayController.arrangedObjects as! [TrackView]).firstIndex(of: track.view!) else { return }
        //let currentTrackRow = row
        let tableRowIndexSet = IndexSet(integer: row)
        let tableColumnIndexSet = IndexSet([1])
        self.tracksTableView.reloadData(forRowIndexes: tableRowIndexSet, columnIndexes: tableColumnIndexSet)
        
        
        /*if let row = (trackViewArrayController.arrangedObjects as! [TrackView]).firstIndex(of: track.view!) {
            self.currentTrackRow = row
            let tableRowIndexSet = IndexSet(integer: row)
            let indexOfPlaysColumn = self.tableView.column(withIdentifier: NSUserInterfaceItemIdentifier.init("play_count"))
            let indexOfSkipsColumn = self.tableView.column(withIdentifier: NSUserInterfaceItemIdentifier.init("skip_count"))
            let tableColumnIndexSet = IndexSet([0, indexOfPlaysColumn, indexOfSkipsColumn])
            tableView.reloadData(forRowIndexes: tableRowIndexSet, columnIndexes: tableColumnIndexSet)
        }*/
    }
    

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        //resizeImageViewForArt()
        // Drawing code here.
    }
    
}
