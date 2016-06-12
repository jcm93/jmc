//
//  MainWindowController.swift
//  minimalTunes
//
//  Created by John Moody on 5/30/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
import CoreData

class MainWindowController: NSWindowController, NSOutlineViewDelegate {
    
    @IBOutlet var sourceListTreeController: NSTreeController!
    @IBOutlet var tableViewArrayController: NSArrayController!
    @IBOutlet weak var sourceListView: NSOutlineView!
    @IBOutlet weak var libraryTableView: NSTableView!
    var cur_view_title = "Library"
    
    //initialize managed asshole context
    lazy var managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    
    //some things
    var artistSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "artist", ascending: true), NSSortDescriptor(key: "album", ascending: true), NSSortDescriptor(key: "track_num", ascending:true)]
    var sourceListSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_order", ascending: true), NSSortDescriptor(key: "name", ascending: true)]
    

    
    
    
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        if (item.representedObject!! as! SourceListItem).is_header == true {
            return outlineView.makeViewWithIdentifier("HeaderCell", owner: self)
        }
        else if (item.representedObject!! as! SourceListItem).playlist != nil {
            return outlineView.makeViewWithIdentifier("PlaylistCell", owner: self)
        }
        else if (item.representedObject!! as! SourceListItem).network_library != nil {
            return outlineView.makeViewWithIdentifier("NetworkLibraryCell", owner: self)
        }
        else if (item.representedObject!! as! SourceListItem).playlist_folder != nil {
            return outlineView.makeViewWithIdentifier("SongCollectionFolder", owner: self)
        }
        else if (item.representedObject!! as! SourceListItem).master_playlist != nil {
            return outlineView.makeViewWithIdentifier("MasterPlaylistCell", owner: self)
        }
        else {
            return outlineView.makeViewWithIdentifier("PlaylistCell", owner: self)
        }
    }
    
    func outlineView(outlineView: NSOutlineView, shouldExpandItem item: AnyObject) -> Bool {
        if (item.representedObject!! as! SourceListItem).is_header == true {
            return true
        }
        else {
            return false
        }
    }
    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        /*print("called")
        print("how did we get here? answer: \(notification)")
        if (sourceListTreeController.selectedNodes[0].representedObject as! SourceListItem).is_header == true {
            return
        }
        if (cur_view_title == (sourceListTreeController.selectedNodes[0].representedObject as! SourceListItem).name!) {
            return
        }
        //slow? bloated? dumb? doesn't even work? all of the above?
        
        //get cached views
        let view_check = (sourceListTreeController.selectedNodes[0].representedObject! as! SourceListItem).name!
        print("view check: \(view_check)")
        let viewCacheCheck = NSFetchRequest.init(entityName: "SongCollectionView")
        var results: [SongCollectionView]?
        do {
            results = try managedContext.executeFetchRequest(viewCacheCheck) as? [SongCollectionView]
        }
        catch {
            print("err")
        }
        print("total cached views: \(results!.count)")
        
        //check if there's a cache of our current view. if not, cache it
        let cur_view_cache = results!.filter { (s: SongCollectionView) -> Bool in
            if (s.title == cur_view_title) {
                return true
            }
            else {
                return false
            }
        }
        if (cur_view_cache.count != 0) {
            let cachedView = cur_view_cache.first!
            cachedView.fetch_predicate = tableViewArrayController.fetchPredicate
            cachedView.filter_predicate = tableViewArrayController.filterPredicate
            cachedView.selected_rows = libraryTableView.selectedRowIndexes
            cachedView.sort_descriptors = tableViewArrayController.sortDescriptors
            cachedView.top_row = libraryTableView.rowsInRect(libraryTableView.visibleRect).location
            print("updated cache of current view")
        }
        else {
            let cachedView = NSEntityDescription.insertNewObjectForEntityForName("SongCollectionView", inManagedObjectContext: managedContext) as! SongCollectionView
            cachedView.fetch_predicate = tableViewArrayController.fetchPredicate
            cachedView.filter_predicate = tableViewArrayController.filterPredicate
            cachedView.selected_rows = libraryTableView.selectedRowIndexes
            cachedView.sort_descriptors = tableViewArrayController.sortDescriptors
            cachedView.title = cur_view_title
            cachedView.top_row = libraryTableView.rowsInRect(libraryTableView.visibleRect).location
            print("cached current view")
        }
        
        //now check cache for info about new view
        print("checking for info about new view")
        let new_view_cache = results!.filter { (s: SongCollectionView) -> Bool in
            if (s.title == view_check) {
                return true
            }
            else {
                return false
            }
        }
        print("new view cache count: \(new_view_cache.count)")
        
        //if we have a cached version of the view we are switching to:
        if (new_view_cache.count != 0) {
            print("new view cache hit")
            let cachedView = new_view_cache.first!
            tableViewArrayController.fetchPredicate = cachedView.fetch_predicate as! NSPredicate
            if (cachedView.filter_predicate != nil) {
                tableViewArrayController.filterPredicate = cachedView.filter_predicate as! NSPredicate
            }
            else {
                tableViewArrayController.filterPredicate = nil
            }
            tableViewArrayController.sortDescriptors = cachedView.sort_descriptors as! [NSSortDescriptor]
            if cachedView.selected_rows != nil {
                print("non nil selected rows")
                libraryTableView.selectRowIndexes(cachedView.selected_rows as! NSIndexSet, byExtendingSelection: false)
            }
            libraryTableView.scrollRowToVisible(cachedView.top_row!.integerValue)
            print("set array controller and table view predicates/sorts/scroll/selection for new view cache")
            libraryTableView.reloadData()
        }
        //otherwise
        else {*/
            if ((sourceListTreeController.selectedNodes[0].representedObject! as! SourceListItem).playlist != nil) {
                let id_array = (sourceListTreeController.selectedNodes[0].representedObject! as! SourceListItem).playlist!.track_id_list
                if (id_array != nil) {
                    tableViewArrayController.fetchPredicate = NSPredicate.init(format: "id in %@", id_array!)
                }
            }
            else {
                tableViewArrayController.fetchPredicate = nil
            }
            print("cache miss; refreshed table accordingly")
        //}
        
        //cur_view_title = (sourceListTreeController.selectedNodes[0].representedObject! as! SourceListItem).name!
        //print("updated current view title to \(cur_view_title)")
    }

    override func windowDidLoad() {
        sourceListView.setDelegate(self)
        libraryTableView.tableColumns[1].sortDescriptorPrototype = NSSortDescriptor(key: "artist_sort_order", ascending: true)
        libraryTableView.tableColumns[2].sortDescriptorPrototype = NSSortDescriptor(key: "album_sort_order", ascending: true)
        
        /*libraryTableView.tableColumns[1].sortDescriptorPrototype = NSSortDescriptor(key: "", ascending: true, comparator: {
            (a: AnyObject, b: AnyObject) -> NSComparisonResult in
            if (a as! Track).artist == (b as! Track).artist {
                if (a as! Track).album == (b as! Track).album {
                    let a_t = (a as! Track).track_num!.integerValue
                    let b_t = (b as! Track).track_num!.integerValue
                    return (a_t < b_t) ? .OrderedAscending : .OrderedDescending
                }
                else {
                    return ((a as! Track).album < (b as! Track).album) ? .OrderedAscending : .OrderedDescending
                }
            }
            else {
                return ((a as! Track).artist < (b as! Track).artist) ? .OrderedAscending : .OrderedDescending
            }
        })*/
        super.windowDidLoad()
    }
    
}
