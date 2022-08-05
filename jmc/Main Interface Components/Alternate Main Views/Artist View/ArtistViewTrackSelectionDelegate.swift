//
//  ArtistViewTrackSelectionDelegate.swift
//  jmc
//
//  Created by John Moody on 8/4/22.
//  Copyright © 2022 John Moody. All rights reserved.
//

import Cocoa

class ArtistViewTrackSelectionDelegate: NSObject {
    
    var tableViews: [NSTableView] = [NSTableView]()
    var previousSelection: (Int, NSTableView, Int)? //album index, table, clicked row
    var parent: ArtistViewAlbumViewController!
    
    func getSelection(forProposedSelection selection: IndexSet, tableView: NSTableView, album: Album) -> IndexSet {
        //for some reason, this glitches out when the previous selection is offscreen
        if !self.tableViews.contains(tableView) {
            tableViews.append(tableView)
        }
        let flags = NSEvent.modifierFlags
        if flags.contains(.shift) {
            if !flags.contains(.command) {
                //if previous row clicked is above this album, select the rest of the tracks in that album
                //if previous row clicked is below this album, select the entire beginning of that album and the end of this album
                let albumIndex = parent.albums.firstIndex(of: album)!
                if let previousSelectionTuple = previousSelection {
                    //previous click is above
                    if previousSelectionTuple.0 < albumIndex {
                        let rowIndexes = IndexSet(previousSelectionTuple.2..<previousSelectionTuple.1.numberOfRows)
                        previousSelectionTuple.1.selectRowIndexes(rowIndexes, byExtendingSelection: true)
                        for i in (previousSelectionTuple.0 + 1)..<albumIndex {
                            //select all in the albums in between
                            let albumCellView = self.parent.views[i]
                            albumCellView?.tracksTableView.selectAll(nil)
                        }
                        //return selection for beginning of this album, inclusive of already selected rows
                        let clickedRow = tableView.clickedRow
                        let newSelectionForThisTableView = IndexSet(0...clickedRow).union(tableView.selectedRowIndexes)
                        return newSelectionForThisTableView
                    } else if previousSelectionTuple.0 > albumIndex {
                        //previous click is below
                        let rowIndexes = IndexSet(0..<previousSelectionTuple.2)
                        previousSelectionTuple.1.selectRowIndexes(rowIndexes, byExtendingSelection: true)
                        for i in (albumIndex + 1)..<previousSelectionTuple.0 {
                            //select all in the albums in between
                            let albumCellView = self.parent.views[i]
                            albumCellView?.tracksTableView.selectAll(nil)
                        }
                        //return selection for end of album instead of beginning
                        let lastRowInSelection = selection.last!
                        let newSelectionForThisTableView = IndexSet(lastRowInSelection..<tableView.numberOfRows).union(tableView.selectedRowIndexes)
                        return newSelectionForThisTableView
                    }
                }
            }
        } else {
            self.tableViews.forEach({$0.selectRowIndexes(IndexSet(), byExtendingSelection: false)})
        }
        return selection
    }
    
    func tableViewRowClicked(album: Album, clickedRow: Int, tableView: NSTableView) {
        let albumIndex = parent.albums.firstIndex(of: album)!
        self.previousSelection = (albumIndex, tableView, clickedRow)
    }
}
