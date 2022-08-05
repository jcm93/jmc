//
//  ArtistViewTrackSelectionDelegate.swift
//  jmc
//
//  Created by John Moody on 8/4/22.
//  Copyright © 2022 John Moody. All rights reserved.
//

import Cocoa

class ArtistViewTrackSelectionDelegate: NSObject {
    
    var previousSelection: (Int, ArtistViewAlbumDataStore, Int)? //album index, table, clicked row
    var parent: ArtistViewAlbumViewController!
    
    func getSelection(forProposedSelection selection: IndexSet, tableView: NSTableView, album: Album) -> IndexSet {
        let albumIndex = parent.albums.firstIndex(of: album)!
        let flags = NSEvent.modifierFlags
        if flags.contains(.shift) {
            if !flags.contains(.command) {
                //if previous row clicked is above this album, select the rest of the tracks in that album
                //if previous row clicked is below this album, select the entire beginning of that album and the end of this album
                if let previousSelectionTuple = previousSelection {
                    //previous click is above
                    if previousSelectionTuple.0 < albumIndex {
                        let rowIndexes = IndexSet(previousSelectionTuple.2..<Int(previousSelectionTuple.1.album.tracks!.count))
                        previousSelectionTuple.1.selectionIndexes = previousSelectionTuple.1.selectionIndexes.union(rowIndexes)
                        for i in (previousSelectionTuple.0 + 1)..<albumIndex {
                            //select all in the albums in between
                            let albumSelectionDataStore = self.parent.views[i]
                            albumSelectionDataStore!.selectionIndexes = IndexSet(0..<Int(albumSelectionDataStore!.album.tracks!.count))
                            //albumCellView?.tracksTableView.selectAll(nil)
                        }
                        //return selection for beginning of this album, inclusive of already selected rows
                        let clickedRow = tableView.clickedRow
                        let newSelectionForThisTableView = IndexSet(0...clickedRow).union(tableView.selectedRowIndexes)
                        let dataStore = self.parent.views[albumIndex]
                        dataStore?.selectionIndexes = newSelectionForThisTableView
                        return newSelectionForThisTableView
                    } else if previousSelectionTuple.0 > albumIndex {
                        //previous click is below
                        let rowIndexes = IndexSet(0..<previousSelectionTuple.2)
                        previousSelectionTuple.1.selectionIndexes = previousSelectionTuple.1.selectionIndexes.union(rowIndexes)
                        for i in (albumIndex + 1)..<previousSelectionTuple.0 {
                            //select all in the albums in between
                            let albumSelectionDataStore = self.parent.views[i]
                            albumSelectionDataStore!.selectionIndexes = IndexSet(0..<Int(albumSelectionDataStore!.album.tracks!.count))
                            //albumCellView?.tracksTableView.selectAll(nil)
                        }
                        //return selection for end of album instead of beginning
                        let lastRowInSelection = selection.last!
                        let newSelectionForThisTableView = IndexSet(lastRowInSelection..<tableView.numberOfRows).union(tableView.selectedRowIndexes)
                        let dataStore = self.parent.views[albumIndex]
                        dataStore?.selectionIndexes = newSelectionForThisTableView
                        return newSelectionForThisTableView
                    }
                }
            }
        } else {
            //self.tableViews.forEach({$0.selectRowIndexes(IndexSet(), byExtendingSelection: false)})
            self.parent.views.values.forEach({$0.selectionIndexes = IndexSet()})
        }
        let dataStore = self.parent.views[albumIndex]
        dataStore?.selectionIndexes = selection
        return selection
    }
    
    func tableViewRowClicked(album: Album, clickedRow: Int, dataStore: ArtistViewAlbumDataStore) {
        let albumIndex = parent.albums.firstIndex(of: album)!
        self.previousSelection = (albumIndex, dataStore, clickedRow)
    }
}
