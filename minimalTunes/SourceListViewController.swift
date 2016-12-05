//
//  SourceListViewController.swift
//  minimalTunes
//
//  Created by John Moody on 12/1/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class SourceListViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
    
    //pre-Sierra NSOutlineView weakly retains items, hence the need for SourceListNodes
    
    @IBOutlet weak var sourceList: SourceListThatYouCanPressSpacebarOn!
    
    var currentAudioSource: SourceListItem?
    var currentSourceListItem: SourceListItem?
    var sourceListDataSource: SourceListDataSource?
    var sharedLibraryIdentifierDictionary = NSMutableDictionary()
    var requestedSharedPlaylists = NSMutableDictionary()
    var mainWindowController: MainWindowController?
    var server: P2PServer?
    
    var rootNode: SourceListNode?
    
    var libraryHeaderNode: SourceListNode?
    var playlistHeaderNode: SourceListNode?
    var sharedHeaderNode: SourceListNode?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        libraryHeaderNode = rootNode?.children[0]
        sharedHeaderNode = rootNode?.children[1]
        playlistHeaderNode = rootNode?.children[2]
        // Do view setup here.
    }
    
    lazy var rootSourceListItem: SourceListItem? = {
        let request = NSFetchRequest(entityName: "SourceListItem")
        do {
            let predicate = NSPredicate(format: "name == 'root'")
            request.predicate = predicate
            let result = try self.managedContext.executeFetchRequest(request) as! [SourceListItem]
            if result.count > 0 {
                return result[0]
            } else {
                return nil
            }
        } catch {
            print("error getting library: \(error)")
            return nil
        }
    }()
    
    lazy var managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    
    func createTree() {
        rootNode = SourceListNode(item: rootSourceListItem!)
        var nodesNotVisited = [SourceListItem]()
        var nodesAlreadyVisited = [SourceListNode]()
        var currentNode = rootNode
        for item in rootNode!.item.children! {
            nodesNotVisited.append(item as! SourceListItem)
        }
        while nodesNotVisited.isEmpty == false {
            let item = nodesNotVisited.removeFirst()
            let newNode = SourceListNode(item: item)
            if item.children != nil {
                for item in item.children! {
                    nodesNotVisited.append(item as! SourceListItem)
                }
            }
            nodesAlreadyVisited.append(newNode)
            if newNode.item.parent == currentNode?.item {
                currentNode?.children.append(newNode)
            } else {
                currentNode = nodesAlreadyVisited.removeFirst()
                if newNode.item.parent == currentNode!.item {
                    currentNode?.children.append(newNode)
                }
            }
        }
    }
    
    func sortTree() {
        var nodesNotVisited = [SourceListNode]()
        nodesNotVisited.append(rootNode!)
        while nodesNotVisited.isEmpty == false {
            let node = nodesNotVisited.removeFirst()
            node.children.sortInPlace({return Int($0.item.sort_order!) < Int($1.item.sort_order!)})
            for node in node.children {
                if node.children.count > 0 {
                    nodesNotVisited.append(node)
                }
            }
        }
    }
    
    func getCurrentSelection() -> SourceListNode {
        let node = self.sourceList.itemAtRow(sourceList.selectedRow) as! SourceListNode
        return node
    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil {
            var count = 0
            for item in rootNode!.children {
                if item.children.count > 0 {
                    count += 1
                }
            }
            return count
        }
        let source = item as! SourceListNode
        return source.children.count
    }
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        let source = item as! SourceListNode
        if source.children.count > 0 {
            return true
        } else {
            return false
        }
    }
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil {
            if rootNode!.children[index].children.count > 0 {
                return rootNode!.children[index]
            } else {
                return rootNode!.children[index+1]
            }
        }
        let source = item as! SourceListNode
        let child = source.children[index]
        return child
    }
    
    func getNodesBeforePlaylists() -> Int {
        var unvisitedViableNodes = [SourceListNode]()
        var sum = 0
        unvisitedViableNodes.append(rootNode!)
        while unvisitedViableNodes.isEmpty == false {
            let node = unvisitedViableNodes.removeFirst()
            sum += 1
            if node.children.count > 0 {
                for child in node.children {
                    if child.children.count > 0 {
                        unvisitedViableNodes.append(child)
                    }
                    sum += 1
                }
            }
        }
        return sum
    }
    
    func createPlaylist(tracks: [Int]?) {
        //create playlist
        let playlist = NSEntityDescription.insertNewObjectForEntityForName("SongCollection", inManagedObjectContext: managedContext) as! SongCollection
        let playlistItem = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
        playlistItem.playlist = playlist
        playlistItem.name = "New Playlist"
        playlistItem.parent = rootNode?.children[2].item
        if tracks != nil {
            playlist.track_id_list = tracks!
        }
        //todo ID
        //create node
        let newSourceListNode = SourceListNode(item: playlistItem)
        playlistHeaderNode?.children.insert(newSourceListNode, atIndex: 0)
        sourceList.reloadData()
        let newPlaylistIndex = NSIndexSet(index: getNodesBeforePlaylists())
        sourceList.selectRowIndexes(newPlaylistIndex, byExtendingSelection: false)
        sourceList.editColumn(0, row: sourceList.selectedRow, withEvent: nil, select: true)
    }
    
    func addNetworkedLibrary(name: String) {
        let newSourceListItem = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
        newSourceListItem.parent = self.rootNode?.children[1].item
        newSourceListItem.name = name
        newSourceListItem.is_network = true
        let newLibrary = NSEntityDescription.insertNewObjectForEntityForName("Library", inManagedObjectContext: managedContext) as! Library
        newLibrary.is_network = true
        newLibrary.name = name
        newSourceListItem.library = newLibrary
        let newSourceListNode = SourceListNode(item: newSourceListItem)
        self.rootNode?.children[1].children.append(newSourceListNode)
        sharedLibraryIdentifierDictionary[name] = newSourceListNode
        sourceList.reloadData()
        print("wrote \(name) to shared library identifier dictionary")
    }
    
    func addSourcesForNetworkedLibrary(sourceData: [NSDictionary], peer: String) {
        print("looking up \(peer) in shared library identifier dictionary")
        let item = self.sharedLibraryIdentifierDictionary[peer] as! SourceListNode
        //create sourcelistitem
        let masterItem = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
        masterItem.name = "Music"
        
        masterItem.parent = item.item
        masterItem.is_network = true
        masterItem.library = item.item.library
        //create node for source list tree controller
        let newSourceListNode = SourceListNode(item: masterItem)
        item.children.append(newSourceListNode)
        //create expandable sourcelistitem for playlists
        let playlistsItem = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
        playlistsItem.name = "Playlists"
        playlistsItem.parent = item.item
        playlistsItem.is_network = true
        playlistsItem.library = item.item.library
        //create node for source list tree controller
        let playlistsItemNode = SourceListNode(item: playlistsItem)
        item.children.append(playlistsItemNode)
        for playlist in sourceData {
            //create sourcelistitem
            let newItem = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
            newItem.sort_order = playlist["sort_order"] as! Int
            newItem.name = playlist["name"] as? String
            newItem.parent = playlistsItem
            newItem.library = item.item.library
            //create playlist object
            let newPlaylist = NSEntityDescription.insertNewObjectForEntityForName("SongCollection", inManagedObjectContext: managedContext) as! SongCollection
            newPlaylist.id = playlist["id"] as! Int
            newItem.playlist = newPlaylist
            newItem.parent = playlistsItem
            newItem.is_network = true
            //create source list node
            let sourceNode = SourceListNode(item: newItem)
            sourceNode.item = newItem
            playlistsItemNode.children.append(sourceNode)
        }
        sourceList.reloadData()
    }
    
    func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool {
        let source = (item as! SourceListNode).item
        if source.is_header == true {
            return false
        } else if source.children?.count > 0 {
            return false
        } else {
            return true
        }
    }
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        let source = item as! SourceListNode
        if (source.item.is_header == true) {
            let view = outlineView.makeViewWithIdentifier("HeaderCell", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            return view
        } else if source.item.playlist != nil {
            let view = outlineView.makeViewWithIdentifier("PlaylistCell", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            return view
        } else if source.item.is_network == true {
            let view = outlineView.makeViewWithIdentifier("NetworkLibraryCell", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            return view
        } else if source.item.playlist_folder != nil {
            let view = outlineView.makeViewWithIdentifier("SongCollectionFolder", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            return view
        } else if source.item.master_playlist != nil {
            let view = outlineView.makeViewWithIdentifier("MasterPlaylistCell", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            return view
        } else {
            let view = outlineView.makeViewWithIdentifier("PlaylistCell", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            return view
        }
    }
    
    func getNetworkPlaylist(id: Int) -> SourceListItem? {
        let item = requestedSharedPlaylists[id] as? SourceListItem
        return item
    }
    
    func getCurrentSelectionSharedLibraryName() -> String {
        return (sourceList.itemAtRow(sourceList.selectedRow) as! SourceListNode).item.library!.name!
    }
    
    func doneAddingNetworkPlaylistCallback(item: SourceListItem) {
        guard currentSourceListItem == item else {return}
        let track_id_list = item.playlist?.track_id_list as? [Int]
        mainWindowController?.networkPlaylistCallback(Int(item.playlist!.id!), idList: track_id_list!)
    }
    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        let selectionNode = (sourceList.itemAtRow(sourceList.selectedRow) as! SourceListNode)
        let selection = selectionNode.item
        self.currentSourceListItem = selection
        let is_network = selection.is_network
        let id = Int(selection.playlist!.id!)
        let track_id_list = selection.playlist?.track_id_list as? [Int]
        if track_id_list == nil {
            if is_network == true {
                requestedSharedPlaylists[id] = selection
                self.server?.getDataForPlaylist(selectionNode)
            }
            mainWindowController?.switchToPlaylist([], id: id, is_network: Bool(is_network!))
        } else {
            mainWindowController?.switchToPlaylist(track_id_list!, id: id, is_network: Bool(is_network!))
        }
    }

}
