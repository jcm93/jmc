//
//  SourceListViewController.swift
//  minimalTunes
//
//  Created by John Moody on 12/1/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
import MultipeerConnectivity
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class SourceListViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource, NSTextFieldDelegate {
    
    //pre-Sierra NSOutlineView weakly retains items, hence the need for SourceListNodes
    
    @IBOutlet weak var sourceList: SourceListThatYouCanPressSpacebarOn!
    
    var currentAudioSource: SourceListItem?
    var currentSourceListItem: SourceListItem?
    var sourceListDataSource: SourceListDataSource?
    var sharedLibraryIdentifierDictionary = NSMutableDictionary()
    var requestedSharedPlaylists = NSMutableDictionary()
    var mainWindowController: MainWindowController?
    var server: ConnectivityManager?
    
    var rootNode: SourceListNode?
    
    var draggedNodes: [SourceListNode]?
    var libraryHeaderNode: SourceListNode?
    var playlistHeaderNode: SourceListNode?
    var sharedHeaderNode: SourceListNode?
    
    
    lazy var rootSourceListItem: SourceListItem? = {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SourceListItem")
        do {
            let predicate = NSPredicate(format: "is_root == true")
            request.predicate = predicate
            let result = try self.managedContext.fetch(request) as! [SourceListItem]
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
        return (NSApplication.shared().delegate
            as? AppDelegate)?.managedObjectContext }()!
    
    func createTree() {
        var nodesNotVisited = [SourceListItem]()
        nodesNotVisited.append(rootSourceListItem!)
        while !nodesNotVisited.isEmpty {
            let item = nodesNotVisited.removeFirst()
            let node = SourceListNode(item: item)
            if item == rootSourceListItem {
                rootNode = node
            }
            if item.parent != nil {
                node.parent = item.parent?.node
                node.parent?.children.append(node)
            }
            for child in item.children! {
                nodesNotVisited.append(child as! SourceListItem)
            }
        }
        print("done making tree")
    }
    
    func sortTree() {
        var nodesNotVisited = [SourceListNode]()
        nodesNotVisited.append(rootNode!)
        while nodesNotVisited.isEmpty == false {
            let node = nodesNotVisited.removeFirst()
            node.children.sort(by: {return Int($0.item.sort_order!) < Int($1.item.sort_order!)})
            for node in node.children {
                if node.children.count > 0 {
                    nodesNotVisited.append(node)
                }
            }
        }
    }
    
    func getCurrentSelection() -> SourceListNode {
        let node = self.sourceList.item(atRow: sourceList.selectedRow) as! SourceListNode
        return node
    }
    
    func selectLibrary() {
        let libraryRowIndexSet = IndexSet(integer: 1)
        sourceList.selectRowIndexes(libraryRowIndexSet, byExtendingSelection: false)
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            if rootNode == nil {
                return 0
            }
            var count = 0
            for item in rootNode!.children {
                if item.children.count > 0 {
                    count += 1
                }
            }
            return count
        }
        let source = item as! SourceListNode
        if source.item.name == "All Sources" {
            print("poony")
        }
        return source.children.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        let source = item as! SourceListNode
        print(source.item.name)
        if source.children.count > 0 {
            print("true")
            return true
        } else {
            print("false")
            return false
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, byItem item: Any?) {
        print("set object value called")
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        let node = sourceList.item(atRow: sourceList.row(for: obj.object as! NSTextField)) as! SourceListNode
        node.item.name = (obj.object as! NSTextField).stringValue
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
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
    
    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
        print("should edit called")
        return true
    }
    
    func getNodesBeforePlaylists() -> Int {
        var index = 0
        var found = false
        while found == false && sourceList.item(atRow: index) != nil {
            let item = sourceList.item(atRow: index) as! SourceListNode
            if item.item.parent == playlistHeaderNode!.item {
                found = true
            } else {
                index += 1
            }
        }
        return index
    }
    
    func createPlaylistFolder(_ nodes: [SourceListNode]?) {
        let playlistFolderItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        playlistFolderItem.is_folder = true
        let playlistFolderNode = SourceListNode(item: playlistFolderItem)
        playlistFolderItem.name = "New Playlist Folder"
        playlistFolderItem.parent = rootNode?.children[2].item
        playlistFolderNode.parent = playlistHeaderNode
        if nodes != nil {
            makeNodesSubnodesOfNode(nodes!, parentNode: playlistFolderNode, index: 0)
        }
        playlistHeaderNode?.children.insert(playlistFolderNode, at: 0)
        sourceList.reloadData()
        let newPlaylistIndex = IndexSet(integer: getNodesBeforePlaylists())
        sourceList.selectRowIndexes(newPlaylistIndex, byExtendingSelection: false)
        sourceList.editColumn(0, row: sourceList.selectedRow, with: nil, select: true)
    }
    
    func makeNodesSubnodesOfNode(_ nodes: [SourceListNode], parentNode: SourceListNode, index: Int) {
        let parentItem = parentNode.item
        let itemsToBeAdded = nodes.map({return $0.item})
        let newItemChildren: NSMutableOrderedSet = parentItem.children?.count > 0 ? parentItem.children?.mutableCopy() as! NSMutableOrderedSet : NSMutableOrderedSet()
        var mutableIndex = index
        for item in itemsToBeAdded {
            guard item != parentNode.item else {continue}
            let currentParentNode = item.node!.parent!
            let currentParentItem = item.node!.parent!.item
            //remove from sibling sets for both items and nodes, then reset parents
            let currentNodeSiblingIndex = currentParentNode.children.index(of: item.node!)
            currentParentNode.children.remove(at: currentNodeSiblingIndex!)
            let currentItemSiblingsMutableCopy = currentParentItem.children!.mutableCopy() as! NSMutableOrderedSet
            currentItemSiblingsMutableCopy.remove(item)
            currentParentItem.children = currentItemSiblingsMutableCopy as NSOrderedSet
            item.node!.parent = parentNode
            item.parent = parentItem
            //insert into new sibling sets at appropriate index
            newItemChildren.insert(item, at: mutableIndex)
            parentNode.children.insert(item.node!, at: mutableIndex)
            if !(parentNode == currentParentNode && currentNodeSiblingIndex < index) {
                mutableIndex += 1
            }
        }
        parentItem.children = newItemChildren as NSOrderedSet
        var index = 0
        for node in parentNode.children {
            node.item.sort_order = index as NSNumber?
            index += 1
        }
        sortTree()
        sourceList.reloadData()
    }
    
    func createPlaylist(_ tracks: [Int]?, smart_criteria: SmartCriteria?) {
        //create playlist
        let playlist = NSEntityDescription.insertNewObject(forEntityName: "SongCollection", into: managedContext) as! SongCollection
        let playlistItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        playlistItem.playlist = playlist
        playlistItem.name = "New Playlist"
        playlistItem.parent = rootNode?.children[2].item
        if tracks != nil {
            playlist.track_id_list = tracks! as NSObject?
        }
        if smart_criteria != nil {
            playlist.smart_criteria = smart_criteria
        }
        //todo ID
        playlist.id = globalRootLibrary?.next_playlist_id
        globalRootLibrary?.next_playlist_id = Int(globalRootLibrary!.next_playlist_id!) + 1 as NSNumber
        //create node
        let newSourceListNode = SourceListNode(item: playlistItem)
        newSourceListNode.parent = playlistHeaderNode
        playlistHeaderNode?.children.insert(newSourceListNode, at: 0)
        sourceList.reloadData()
        print(getNodesBeforePlaylists())
        let newPlaylistIndex = IndexSet(integer: getNodesBeforePlaylists())
        sourceList.selectRowIndexes(newPlaylistIndex, byExtendingSelection: false)
        sourceList.editColumn(0, row: sourceList.selectedRow, with: nil, select: true)
    }
    
    func addNetworkedLibrary(_ peer: MCPeerID) {
        let newSourceListItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        newSourceListItem.parent = self.rootNode?.children[1].item
        newSourceListItem.name = peer.displayName
        newSourceListItem.is_network = true
        let newLibrary = NSEntityDescription.insertNewObject(forEntityName: "Library", into: managedContext) as! Library
        newLibrary.is_network = true
        newLibrary.name = peer.displayName
        newLibrary.peer = peer
        newSourceListItem.library = newLibrary
        let newSourceListNode = SourceListNode(item: newSourceListItem)
        self.rootNode?.children[1].children.append(newSourceListNode)
        sharedLibraryIdentifierDictionary[peer] = newSourceListNode
        DispatchQueue.main.async {
            self.sourceList.reloadData()
        }
        print("wrote \(peer) to shared library identifier dictionary")
    }
    
    func removeNetworkedLibrary(_ peer: MCPeerID) {
        guard let node = self.sharedLibraryIdentifierDictionary[peer] as? SourceListNode else {return}
        var nodesNotVisited = [SourceListNode]()
        nodesNotVisited.append(node)
        while !nodesNotVisited.isEmpty {
            let theNode = nodesNotVisited.removeFirst()
            if theNode.item.playlist?.track_id_list != nil {
                //delete network tracks, track views, artist, albums, composers, genres
                let trackViewFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TrackView")
                let trackViewFetchPredicate = NSPredicate(format: "is_network == true AND track.id in %@", theNode.item.playlist?.track_id_list as! [Int])
                trackViewFetchRequest.predicate = trackViewFetchPredicate
                do {
                    let results = try managedContext.fetch(trackViewFetchRequest) as! [TrackView]
                    for thing in results {
                        managedContext.delete(thing.track!)
                        managedContext.delete(thing)
                    }
                } catch {
                    print(error)
                }
            }
            if theNode.children.count > 0 {
                nodesNotVisited.append(contentsOf: theNode.children)
            }
        }
        sharedHeaderNode!.children.remove(at: sharedHeaderNode!.children.index(of: node)!)
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SourceListItem")
        let deletePredicate = NSPredicate(format: "is_network == true")
        deleteFetch.predicate = deletePredicate
        do {
            let results = try managedContext.fetch(deleteFetch) as! [SourceListItem]
            for result in results {
                if result.library?.peer == peer {
                    managedContext.delete(result)
                }
            }
            try managedContext.save()
        } catch {
            print(error)
        }
        sourceList.reloadData()
    }
    
    func addSourcesForNetworkedLibrary(_ sourceData: [NSDictionary], peer: MCPeerID) {
        print("looking up \(peer) in shared library identifier dictionary")
        let item = self.sharedLibraryIdentifierDictionary[peer] as! SourceListNode
        //create sourcelistitem
        let masterItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        masterItem.name = "Music"
        
        masterItem.parent = item.item
        masterItem.is_network = true
        masterItem.library = item.item.library
        //create node for source list tree controller
        let newSourceListNode = SourceListNode(item: masterItem)
        item.children.append(newSourceListNode)
        //create expandable sourcelistitem for playlists
        let playlistsItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        playlistsItem.name = "Playlists"
        playlistsItem.parent = item.item
        playlistsItem.is_network = true
        playlistsItem.library = item.item.library
        //create node for source list tree controller
        let playlistsItemNode = SourceListNode(item: playlistsItem)
        item.children.append(playlistsItemNode)
        for playlist in sourceData {
            //create sourcelistitem
            let newItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
            newItem.sort_order = playlist["sort_order"] as! Int as NSNumber?
            newItem.name = playlist["name"] as? String
            newItem.parent = playlistsItem
            newItem.library = item.item.library
            //create playlist object
            let newPlaylist = NSEntityDescription.insertNewObject(forEntityName: "SongCollection", into: managedContext) as! SongCollection
            newPlaylist.id = playlist["id"] as! Int as NSNumber?
            newItem.playlist = newPlaylist
            newItem.parent = playlistsItem
            newItem.is_network = true
            //create source list node
            let sourceNode = SourceListNode(item: newItem)
            sourceNode.item = newItem
            playlistsItemNode.children.append(sourceNode)
        }
        DispatchQueue.main.async {
            self.sourceList.reloadData()
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        let source = (item as! SourceListNode).item
        if source.is_header == true {
            return false
        } else if source.children?.count > 0 && source.library != nil {
            return true
        } else if source.children?.count > 0 && source.is_folder != true {
            return false
        } else {
            return true
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let source = item as! SourceListNode
        if (source.item.is_header == true) {
            let view = outlineView.make(withIdentifier: "HeaderCell", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            view.textField?.isEditable = false
            return view
        } else if source.item.playlist != nil {
            if source.item.playlist?.smart_criteria != nil {
                let view = outlineView.make(withIdentifier: "SmartPlaylistCell", owner: self) as! SourceListCellView
                view.node = source
                view.textField?.stringValue = source.item.name!
                view.textField?.delegate = self
                return view
            } else {
                let view = outlineView.make(withIdentifier: "PlaylistCell", owner: self) as! SourceListCellView
                view.node = source
                view.textField?.stringValue = source.item.name!
                view.textField?.delegate = self
                return view
            }
        } else if source.item.is_network == true {
            let view = outlineView.make(withIdentifier: "NetworkLibraryCell", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            view.textField?.isEditable = false
            return view
        } else if source.item.is_folder == true {
            let view = outlineView.make(withIdentifier: "PlaylistFolderCell", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            view.textField?.delegate = self
            view.textField?.isEditable = true
            return view
        } else if source.item.library != nil {
            if source.item.children?.count > 0 {
                let view = outlineView.make(withIdentifier: "MasterLibraryCell", owner: self) as! SourceListCellView
                view.node = source
                view.textField?.stringValue = "All Sources"
                source.item.name = "All Sources"
                view.textField?.isEditable = false
                return view
            } else {
                let view = outlineView.make(withIdentifier: "MasterPlaylistCell", owner: self) as! SourceListCellView
                view.node = source
                view.textField?.stringValue = source.item.name!
                view.textField?.isEditable = false
                return view
            }
        } else {
            let view = outlineView.make(withIdentifier: "PlaylistCell", owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.item.name!
            view.textField?.delegate = self
            return view
        }
    }
    
    @IBAction func checkBoxPressed(_ sender: Any) {
        print("check box pressed")
        let checkBox = sender as! NSButton
        let checkBoxState = checkBox.state
        let cellView = checkBox.superview as! SourceListCellView
        let sourceListNode = cellView.node
        let library = sourceListNode?.item.library
        library?.is_active = checkBoxState == NSOnState ? true : false
    }
    
    func getNetworkPlaylist(_ id: Int) -> SourceListItem? {
        let item = requestedSharedPlaylists[id] as? SourceListItem
        return item
    }
    
    func getCurrentSelectionSharedLibraryPeer() -> MCPeerID {
        return (sourceList.item(atRow: sourceList.selectedRow) as! SourceListNode).item.library!.peer as! MCPeerID
    }
    
    func doneAddingNetworkPlaylistCallback(_ item: SourceListItem) {
        guard currentSourceListItem == item else {return}
        let track_id_list = item.playlist?.track_id_list as? [Int]
        mainWindowController?.networkPlaylistCallback(Int(item.playlist!.id!), idList: track_id_list!)
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let selectionNode = (sourceList.item(atRow: sourceList.selectedRow) as! SourceListNode)
        let selection = selectionNode.item
        self.currentSourceListItem = selection
        let track_id_list = selection.playlist?.track_id_list as? [Int]
        if track_id_list == nil && selection.is_network == true && selection.playlist?.id != nil {
            print("outline view detected network playlist")
            requestedSharedPlaylists[selection.playlist!.id!] = selection
            self.server!.getDataForPlaylist(selectionNode)
        }
        mainWindowController?.switchToPlaylist(selection)
    }
    
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
        print("called")
    }
    
    func outlineView(_ outlineView: NSOutlineView, writeItems items: [Any], to pasteboard: NSPasteboard) -> Bool {
        print(items)
        draggedNodes = items as? [SourceListNode]
        //for intra-NSOV drags, we do not attach pasteboard data
        pasteboard.setData(nil, forType: "SourceListItem")
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        print("validate drop called on source list")
        print(info.draggingPasteboard().data(forType: "Track"))
        if draggedNodes != nil {
            let node = item as? SourceListNode
            print(index)
            if node?.item.is_folder == true {
                print("returning generic")
                return .every
            } else if node == playlistHeaderNode && index != -1 {
                print("returning move")
                return .move
            } else {
                print("returning none")
                return NSDragOperation()
            }
        } else if info.draggingPasteboard().data(forType: "Track") != nil {
            print("non nil track data")
            if item != nil && (item as! SourceListNode).item.parent?.name == "Playlists" {
                return .generic
            }
        } else if info.draggingPasteboard().data(forType: "NetworkTrack") != nil {
            print("non nil networktrack data")
            if item != nil {
                let itemParentName = (item as! SourceListNode).item.parent?.name
                print(itemParentName)
                if item != nil && (itemParentName == "Playlists" || itemParentName == "Library") {
                    return .generic
                }
            }
        }
        print("returning none")
        return NSDragOperation()
    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        if draggedNodes != nil {
            var fixedIndex = index
            if index == -1 {
                fixedIndex = 0
            }
            makeNodesSubnodesOfNode(draggedNodes!, parentNode: item as! SourceListNode, index: fixedIndex)
            draggedNodes = nil
            sourceList.reloadData()
            return true
        } else if info.draggingPasteboard().data(forType: "Track") != nil {
            print("doing stuff")
            let playlistItem = (item as! SourceListNode).item
            let playlist = playlistItem.playlist
            let data = info.draggingPasteboard().data(forType: "Track")
            let unCodedThing = NSKeyedUnarchiver.unarchiveObject(with: data!) as! NSMutableArray
            let tracks = { () -> [Track] in
                var result = [Track]()
                for trackURI in unCodedThing {
                    let id = managedContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: trackURI as! URL)
                    result.append(managedContext.object(with: id!) as! Track)
                }
                return result
            }()
            for track in tracks {
                var id_list: [Int]
                if playlist!.track_id_list != nil {
                    id_list = playlist!.track_id_list as! [Int]
                } else {
                    id_list = [Int]()
                }
                id_list.append(Int(track.id!))
                playlist?.track_id_list = id_list as NSObject?
            }
        } else if info.draggingPasteboard().data(forType: "NetworkTrack") != nil {
            print("processing network track transfers")
            let playlistItem = (item as! SourceListNode).item
            let playlist = playlistItem.playlist
            let data = info.draggingPasteboard().data(forType: "NetworkTrack")
            let unCodedThing = NSKeyedUnarchiver.unarchiveObject(with: data!) as! NSMutableArray
            let tracks = { () -> [Track] in
                var result = [Track]()
                for trackURI in unCodedThing {
                    let id = managedContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: trackURI as! URL)
                    result.append(managedContext.object(with: id!) as! Track)
                }
                return result
            }()
            for track in tracks {
                self.server?.askPeerForSongDownload(currentSourceListItem!.library?.peer as! MCPeerID, track: track)
            }
            
        }
        return true
    }
    
    func selectStuff() {
        let indexSet = IndexSet(integer: 1)
        sourceList.selectRowIndexes(indexSet, byExtendingSelection: false)
        mainWindowController?.currentTableViewController?.item = libraryHeaderNode?.children[0].item
    }
    
    override func viewDidLoad() {
        self.createTree()
        self.sortTree()
        libraryHeaderNode = rootNode?.children[0]
        sharedHeaderNode = rootNode?.children[1]
        playlistHeaderNode = rootNode?.children[2]
        sourceList.delegate = self
        sourceList.dataSource = self
        sourceList.autosaveExpandedItems = true
        sourceList.expandItem(libraryHeaderNode)
        sourceList.expandItem(playlistHeaderNode)
        sourceList.reloadData()
        sourceList.allowsEmptySelection = false
        // Do view setup here.
        super.viewDidLoad()
    }

}
