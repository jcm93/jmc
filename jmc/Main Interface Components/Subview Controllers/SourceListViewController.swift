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


class SourceListViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource, NSTextFieldDelegate, NSMenuDelegate {
    
    @IBOutlet weak var sourceList: SourceListThatYouCanPressSpacebarOn!
    
    var currentAudioSource: SourceListItem?
    var currentSourceListItem: SourceListItem?
    var sharedLibraryIdentifierDictionary = NSMutableDictionary()
    var requestedSharedPlaylists = NSMutableDictionary()
    var mainWindowController: MainWindowController?
    var server: ConnectivityManager?
    var draggedNodes: [SourceListItem]?
    var libraryHeaderNode: SourceListItem?
    var playlistHeaderNode: SourceListItem?
    var sharedHeaderNode: SourceListItem?
    
    @IBOutlet var sourceListMenu: NSMenu!
    var editSmartPlaylistMenuItem = NSMenuItem(title: "Edit Smart Playlist", action: #selector(editSmartPlaylistAction), keyEquivalent: "")
    var removePlaylistMenuItem = NSMenuItem(title: "Remove Playlist", action: #selector(removePlaylist), keyEquivalent: "")
    var exportPlaylistMenuItem = NSMenuItem(title: "Export Playlist", action: #selector(exportPlaylist), keyEquivalent: "")
    
    var playlistMenuItems: [NSMenuItem]!
    
    lazy var rootSourceListItem: SourceListItem! = {
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
        return (NSApplication.shared.delegate
            as? AppDelegate)?.managedObjectContext }()!
    
    func getCurrentSelection() -> SourceListItem {
        let node = self.sourceList.item(atRow: sourceList.selectedRow) as! SourceListItem
        return node
    }
    
    func selectLibrary() {
        let libraryRowIndexSet = IndexSet(integer: 1)
        sourceList.selectRowIndexes(libraryRowIndexSet, byExtendingSelection: false)
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            //at root
            if sharedHeaderNode?.children?.count > 0 {
                return 3
            } else if playlistHeaderNode?.children?.count > 0 {
                return 2
            } else {
                return 1
            }
        } else {
            return (item as? SourceListItem)?.children?.count ?? 0
        }
    }
    
    @IBAction func editSmartPlaylistAction(_ sender: Any) {
        self.sourceList.selectRowIndexes(IndexSet(integer: sourceList.clickedRow), byExtendingSelection: false)
        self.mainWindowController?.showAdvancedFilter()
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        guard let item = sourceList.item(atRow: sourceList.clickedRow) as? SourceListItem else { return }
        guard item.playlist != nil else { menu.removeAllItems(); return }
        if menu.items.count == 0 {
            for item in self.playlistMenuItems {
                menu.addItem(item)
            }
        }
        if item.playlist?.smart_criteria != nil {
            if !self.sourceListMenu.items.contains(self.editSmartPlaylistMenuItem) {
                self.sourceListMenu.insertItem(self.editSmartPlaylistMenuItem, at: 1)
            }
        } else {
            if self.sourceListMenu.items.contains(self.editSmartPlaylistMenuItem) {
                self.sourceListMenu.removeItem(self.editSmartPlaylistMenuItem)
            }
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        let source = item as! SourceListItem
        if source.children?.count > 0 {
            return true
        } else {
            return false
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, byItem item: Any?) {
        print("set object value called")
    }
    
    @IBAction func allSourcesAction(_ sender: Any) {
        self.mainWindowController?.delegate?.openLibraryManager(self)
        
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        let item = sourceList.item(atRow: sourceList.row(for: (obj.object as! NSTextField))) as? SourceListItem
        item?.name = (obj.object as! NSTextField).stringValue
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            let children = rootSourceListItem.children!
            if (children[index] as? SourceListItem)?.children?.count > 0 {
                return children[index]
            } else {
                guard rootSourceListItem.children?.count > index + 1 else {
                    return children[index]
                }
                return children[index + 1]
            }
        }
        let source = item as! SourceListItem
        let child = source.children![index]
        return child
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
        print("should edit called")
        return true
    }

    func reloadData() {
        print("source list reload data called")
        let selection = sourceList.selectedRowIndexes
        sourceList.reloadData()
        sourceList.selectRowIndexes(selection, byExtendingSelection: false)
        DispatchQueue.main.async {
            self.sourceList.expandItem(self.libraryHeaderNode, expandChildren: true)
            self.sourceList.expandItem(self.playlistHeaderNode)
        }
    }
    
    func createPlaylistFolder(_ items: [SourceListItem]?) {
        let playlistFolderItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        playlistFolderItem.is_folder = true
        playlistFolderItem.name = "New Playlist Folder"
        if items != nil {
            makeItemsChildrenOfItem(items!, parentItem: playlistFolderItem, index: 0)
        }
        playlistHeaderNode?.insertIntoChildren(playlistFolderItem, at: 0)
        sourceList.reloadData()
        sourceList.expandItem(self.playlistHeaderNode)
        let newPlaylistIndex = IndexSet(integer: sourceList.row(forItem: playlistFolderItem))
        sourceList.selectRowIndexes(newPlaylistIndex, byExtendingSelection: false)
        sourceList.editColumn(0, row: sourceList.selectedRow, with: nil, select: true)
    }
    
    func makeItemsChildrenOfItem(_ items: [SourceListItem], parentItem: SourceListItem, index: Int) {
        for item in items {
            item.parent = nil
        }
        let indices = IndexSet(integersIn: index..<index+items.count)
        parentItem.mutableOrderedSetValue(forKey: "children").insert(items, at: indices)
    }
    
    func createPlaylist(_ tracks: [Track]?, smart_criteria: SmartCriteria?) {
        //create playlist
        let playlist = NSEntityDescription.insertNewObject(forEntityName: "SongCollection", into: managedContext) as! SongCollection
        let playlistItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        playlistItem.playlist = playlist
        playlistItem.name = "New Playlist"
        playlist.name = "New Playlist"
        if tracks != nil {
            playlist.tracks = NSOrderedSet(array: tracks!.map({return $0.view!}))
        }
        if smart_criteria != nil {
            playlist.smart_criteria = smart_criteria
        }
        //todo ID
        playlist.id = globalRootLibrary?.next_playlist_id
        globalRootLibrary?.next_playlist_id = Int(globalRootLibrary!.next_playlist_id!) + 1 as NSNumber
        //create node
        playlistHeaderNode?.insertIntoChildren(playlistItem, at: 0)
        sourceList.reloadData()
        sourceList.expandItem(self.playlistHeaderNode)
        let newPlaylistIndex = IndexSet(integer: sourceList.row(forItem: playlistItem))
        sourceList.selectRowIndexes(newPlaylistIndex, byExtendingSelection: false)
        sourceList.editColumn(0, row: sourceList.selectedRow, with: nil, select: true)
    }
    
    func addNetworkedLibrary(_ peer: MCPeerID) {
        let newSourceListItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        newSourceListItem.parent = sharedHeaderNode
        newSourceListItem.name = peer.displayName
        newSourceListItem.is_network = true
        let newLibrary = NSEntityDescription.insertNewObject(forEntityName: "Library", into: managedContext) as! Library
        newLibrary.is_network = true
        newLibrary.name = peer.displayName
        newLibrary.peer = peer
        newSourceListItem.library = newLibrary
        sharedLibraryIdentifierDictionary[peer] = newSourceListItem
        DispatchQueue.main.async {
            self.reloadData()
        }
        print("wrote \(peer) to shared library identifier dictionary")
    }
    
    func removeNetworkedLibrary(_ peer: MCPeerID) {
        guard let item = self.sharedLibraryIdentifierDictionary[peer] as? SourceListItem else {return}
        mainWindowController?.delegate?.databaseManager?.removeSource(library: item.library!)
    }
    
    func addSourcesForNetworkedLibrary(_ sourceData: [NSDictionary], peer: MCPeerID) {
        print("looking up \(peer) in shared library identifier dictionary")
        let item = self.sharedLibraryIdentifierDictionary[peer] as! SourceListItem
        //create sourcelistitem
        let masterItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        masterItem.name = "Music"
        masterItem.parent = item
        masterItem.is_network = true
        masterItem.library = item.library
        //create expandable sourcelistitem for playlists
        let playlistsItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        playlistsItem.name = "Playlists"
        playlistsItem.parent = item
        playlistsItem.is_network = true
        playlistsItem.library = item.library
        //create node for source list tree controller
        for playlist in sourceData {
            //create sourcelistitem
            let newItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
            newItem.sort_order = playlist["sort_order"] as! Int as NSNumber?
            newItem.name = playlist["name"] as? String
            newItem.parent = playlistsItem
            newItem.library = item.library
            //create playlist object
            let newPlaylist = NSEntityDescription.insertNewObject(forEntityName: "SongCollection", into: managedContext) as! SongCollection
            newPlaylist.id = playlist["id"] as! Int as NSNumber?
            newItem.playlist = newPlaylist
            newItem.parent = playlistsItem
            newItem.is_network = true
            //create source list node
        }
        DispatchQueue.main.async {
            self.reloadData()
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        let source = item as! SourceListItem
        if source.is_header == true {
            return false
        } else if source.children?.count > 0 && source.library != nil {
            return true
        } else if source.volume != nil && !volumeIsAvailable(volume: source.volume!) {
            return false
        } else if source.children?.count > 0 && source.is_folder != true {
            return false
        } else {
            return true
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let source = item as! SourceListItem
        if (source.is_header == true) {
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.name!
            view.textField?.isEditable = false
            return view
        } else if source.playlist != nil {
            if source.playlist?.smart_criteria != nil {
                let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SmartPlaylistCell"), owner: self) as! SourceListCellView
                view.node = source
                view.textField?.stringValue = source.name!
                view.textField?.delegate = self
                if source.playlist?.name != source.name {
                    source.playlist?.name = source.name
                }
                return view
            } else {
                let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PlaylistCell"), owner: self) as! SourceListCellView
                view.node = source
                view.textField?.stringValue = source.name!
                view.textField?.delegate = self
                if source.playlist?.name != source.name {
                    source.playlist?.name = source.name
                }
                return view
            }
        } else if source.is_network == true {
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NetworkLibraryCell"), owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.name!
            view.textField?.isEditable = false
            return view
        } else if source.is_folder == true {
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PlaylistFolderCell"), owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.name!
            view.textField?.delegate = self
            view.textField?.isEditable = true
            return view
        } else if source.library != nil {
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MasterLibraryCell"), owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = "All Sources"
            view.textField?.isEditable = false
            return view
        } else if source.volume != nil {
            if volumeIsAvailable(volume: source.volume!) {
                let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MasterPlaylistCell"), owner: self) as! SourceListCellView
                view.node = source
                view.textField?.stringValue = source.volume!.name ?? ""
                view.textField?.isEditable = false
                return view
            } else {
                let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MasterPlaylistCellDisabled"), owner: self) as! SourceListCellView
                view.node = source
                view.textField?.stringValue = source.volume!.name ?? ""
                return view
            }

        } else {
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PlaylistCell"), owner: self) as! SourceListCellView
            view.node = source
            view.textField?.stringValue = source.name!
            view.textField?.delegate = self
            if source.playlist?.name != source.name {
                source.playlist?.name = source.name
            }
            return view
        }
    }
    
    @IBAction func checkBoxPressed(_ sender: Any) {
        if mainWindowController?.currentTableViewController?.playlist == nil {
            mainWindowController?.currentTableViewController?.initializeForLibrary()
        }
    }
    
    func getNetworkPlaylist(_ id: Int) -> SourceListItem? {
        let item = requestedSharedPlaylists[id] as? SourceListItem
        return item
    }
    
    func getCurrentSelectionSharedLibraryPeer() -> MCPeerID {
        return (sourceList.item(atRow: sourceList.selectedRow) as! SourceListItem).library!.peer as! MCPeerID
    }
    
    func doneAddingNetworkPlaylistCallback(_ item: SourceListItem) {
        guard currentSourceListItem == item else { return }
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if let selection = (sourceList.item(atRow: sourceList.selectedRow) as? SourceListItem) {
            self.currentSourceListItem = selection
            //let track_id_list = selection.playlist?.track_id_list as? [Int]
            /*if track_id_list == nil && selection.is_network == true && selection.playlist?.id != nil {
                print("outline view detected network playlist")
                requestedSharedPlaylists[selection.playlist!.id!] = selection
                self.server!.getDataForPlaylist(selection)
            }*/
            mainWindowController?.switchToPlaylist(selection)
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
        print("called")
    }
    
    func outlineView(_ outlineView: NSOutlineView, writeItems items: [Any], to pasteboard: NSPasteboard) -> Bool {
        print(items)
        draggedNodes = items as? [SourceListItem]
        //for intra-NSOV drags, we do not attach pasteboard data
        pasteboard.setData(nil, forType: NSPasteboard.PasteboardType(rawValue: "SourceListItem"))
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == String(Character(UnicodeScalar(NSDeleteCharacter)!)) {
            deleteSelection()
        }
    }
    
    @IBAction func exportPlaylist(_ sender: Any) {
        let selectedPlaylists = sourceList.selectedRowIndexes.flatMap({return (sourceList.item(atRow: $0) as? SourceListItem)?.playlist})
        let delegate = (NSApplication.shared.delegate as! AppDelegate)
        delegate.launchAddFilesDialog()
        DispatchQueue.global(qos: .default).async {
            self.export(playlists: selectedPlaylists)
        }
    }
    @IBAction func removePlaylist(_ sender: Any) {
        deleteSelection()
    }
    
    func export(playlists: [SongCollection]) { //does not handle errors good
        let playlistsFolder = globalRootLibrary!.getCentralMediaFolder()!.appendingPathComponent("Exported Playlists")
        let visualUpdateHandler = (NSApplication.shared.delegate as! AppDelegate).backgroundAddFilesHandler
        var index = 0
        DispatchQueue.main.async {
            visualUpdateHandler?.prepareForNewTask(actionName: "Copying", thingName: "files", thingCount: playlists.reduce(0, { return $0 + $1.tracks!.count }))
        }
        var playlistFolders = [URL]()
        for playlist in playlists {
            let playlistFolder = playlistsFolder.appendingPathComponent(playlist.name!)
            do {
                try FileManager.default.createDirectory(at: playlistFolder, withIntermediateDirectories: true, attributes: nil)
                for trackView in playlist.tracks! {
                    index += 1
                    DispatchQueue.main.async {
                        visualUpdateHandler?.increment(thingsDone: index)
                    }
                    guard let track = (trackView as? TrackView)?.track, let trackURL = URL(string: track.location!) else { continue }
                    let trackFilename = trackURL.lastPathComponent
                    do {
                        try FileManager.default.copyItem(at: trackURL, to: playlistFolder.appendingPathComponent(trackFilename))
                    } catch {
                        print("error copying track \(track.name)")
                    }
                }
            } catch {
                print("error exporting playlist \(playlist.name)")
            }
            playlistFolders.append(playlistFolder)
        }
        DispatchQueue.main.async {
            NSWorkspace.shared.activateFileViewerSelecting(playlistFolders)
        }
        DispatchQueue.main.async {
            visualUpdateHandler?.finish()
        }
    }
    
    func deleteSelection() {
        let playlistHeaderIndex = sourceList.row(forItem: playlistHeaderNode)
        var validIndicesToDelete = IndexSet()
        for index in sourceList.selectedRowIndexes {
            if index > playlistHeaderIndex {
                validIndicesToDelete.insert(index)
            }
        }
        let sourceListItems = validIndicesToDelete.map({return sourceList.item(atRow: $0)})
        for item in sourceListItems {
            managedContext.delete(item as! NSManagedObject)
        }
        let viewIndices = IndexSet(validIndicesToDelete.map({return $0 - playlistHeaderIndex - 1}))
        sourceList.removeItems(at: viewIndices, inParent: playlistHeaderNode, withAnimation: NSTableView.AnimationOptions.effectFade)
    }
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        print("validate drop called on source list")
        print(info.draggingPasteboard().data(forType: NSPasteboard.PasteboardType(rawValue: "Track")))
        let source = item as? SourceListItem
        if draggedNodes != nil {
            print(index)
            if source?.is_folder == true {
                print("returning generic")
                return .every
            } else if source == playlistHeaderNode && index != -1 {
                print("returning move")
                return .move
            } else {
                print("returning none")
                return NSDragOperation()
            }
        } else if info.draggingPasteboard().data(forType: NSPasteboard.PasteboardType(rawValue: "Track")) != nil {
            print("non nil track data")
            if source != nil && source!.parent!.name == "Playlists" {
                return .generic
            }
        } else if info.draggingPasteboard().data(forType: NSPasteboard.PasteboardType(rawValue: "NetworkTrack")) != nil {
            print("non nil networktrack data")
            if source != nil {
                let itemParentName = source!.parent?.name
                print(itemParentName)
                if source != nil && (itemParentName == "Playlists" || itemParentName == "Library") {
                    return .generic
                }
            }
        }
        print("returning none")
        return NSDragOperation()
        print("poop")
    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        if draggedNodes != nil {
            var fixedIndex = index
            if index == -1 {
                fixedIndex = 0
            }
            makeItemsChildrenOfItem(draggedNodes!, parentItem: item as! SourceListItem, index: fixedIndex)
            draggedNodes = nil
            self.reloadData()
            return true
        } else if info.draggingPasteboard().data(forType: NSPasteboard.PasteboardType(rawValue: "Track")) != nil {
            print("doing stuff")
            let playlistItem = item as! SourceListItem
            let playlist = playlistItem.playlist
            let data = info.draggingPasteboard().data(forType: NSPasteboard.PasteboardType(rawValue: "Track"))
            let unCodedThing = NSKeyedUnarchiver.unarchiveObject(with: data!) as! NSMutableArray
            let tracks = { () -> [Track] in
                var result = [Track]()
                for trackURI in unCodedThing {
                    let id = managedContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: trackURI as! URL)
                    result.append(managedContext.object(with: id!) as! Track)
                }
                return result
            }()
            playlist?.addToTracks(tracks.map({return $0.view!}))
        } else if info.draggingPasteboard().data(forType: NSPasteboard.PasteboardType(rawValue: "NetworkTrack")) != nil {
            print("processing network track transfers")
            let playlistItem = item as! SourceListItem
            let playlist = playlistItem.playlist
            let data = info.draggingPasteboard().data(forType: NSPasteboard.PasteboardType(rawValue: "NetworkTrack"))
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
        mainWindowController?.currentTableViewController?.item = libraryHeaderNode?.children?[0] as! SourceListItem
    }
    
    override func viewDidLoad() {
        libraryHeaderNode = rootSourceListItem?.children?[0] as? SourceListItem
        sharedHeaderNode = rootSourceListItem?.children?[1] as? SourceListItem
        playlistHeaderNode = rootSourceListItem?.children?[2] as? SourceListItem
        self.playlistMenuItems = [self.removePlaylistMenuItem, self.exportPlaylistMenuItem]
        sourceList.delegate = self
        sourceList.dataSource = self
        sourceList.autosaveExpandedItems = true
        sourceList.expandItem(libraryHeaderNode, expandChildren: true)
        sourceList.expandItem(playlistHeaderNode)
        sourceList.reloadData()
        sourceListMenu.delegate = self
        sourceList.allowsEmptySelection = false
        // Do view setup here.
        super.viewDidLoad()
    }

}
