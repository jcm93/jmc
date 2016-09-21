//
//  DragAndDropTreeController.swift
//  minimalTunes
//
//  Created by John Moody on 7/2/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

extension NSTreeController {
    
    func indexPathOfObject(anObject:NSObject) -> NSIndexPath? {
        return self.indexPathOfObject(anObject, nodes: self.arrangedObjects.childNodes)
    }
    
    func indexPathOfObject(anObject:NSObject, nodes:[NSTreeNode]!) -> NSIndexPath? {
        for node in nodes {
            if (anObject == node.representedObject as! NSObject)  {
                return node.indexPath
            }
            if (node.childNodes != nil) {
                if let path:NSIndexPath = self.indexPathOfObject(anObject, nodes: node.childNodes)
                {
                    return path
                }
            }
        }
        return nil
    }
}

class DragAndDropTreeController: NSTreeController, NSOutlineViewDataSource {
    
    lazy var managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    
    var playlistHeaderNode: SourceListItem?
    var libraryHeaderNode: SourceListItem?
    var sharedHeaderNode: SourceListItem?
    
    var draggedNodes: [NSTreeNode]?
    
    func reorderChildren(item: NSTreeNode) {
        if item.childNodes != nil {
            var poop = item.childNodes!
            for i in 0..<poop.count {
                (poop[i].representedObject as! SourceListItem).sort_order = i
            }
        }
    }
    
    /*func outlineViewItemDidExpand(notification: NSNotification) {
        print("called")
        if (notification.object as! SourceListItem).network_library != nil {
            askNetworkLibraryForSourceList(notification.object as! SourceListItem)
        }
    }*/
    
    func checkNetworkedLibrary() {
        let networkedLibraryIP = NSUserDefaults.standardUserDefaults().stringForKey("testIP")
        let delegate = SharedLibraryRequestDelegate()
        delegate.onlineCheck(networkedLibraryIP!)
    }
    
    func addNetworkedLibrary(name: String, address: String) {
        let newSourceListItem = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
        newSourceListItem.parent = self.sharedHeaderNode
        newSourceListItem.name = name
        newSourceListItem.is_network = true
        let newNetworkLibrary = NSEntityDescription.insertNewObjectForEntityForName("NetworkLibrary", inManagedObjectContext: managedContext) as! SharedLibrary
        newNetworkLibrary.address = address
        askNetworkLibraryForSourceList(newSourceListItem)
        
    }
    
    func addSourcesForNetworkedLibrary(sourceData: [NSDictionary], item: SourceListItem) {
        let masterItem = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
        masterItem.name = "Music"
        masterItem.parent = item
        for playlist in sourceData {
            let newItem = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
            newItem.sort_order = playlist["sort_order"] as! Int
            newItem.name = playlist["name"] as? String
            let newPlaylist = NSEntityDescription.insertNewObjectForEntityForName("SongCollection", inManagedObjectContext: managedContext) as! SongCollection
            newPlaylist.id = playlist["id"] as! Int
            newItem.playlist = newPlaylist
            newItem.parent = item
        }
    }
    
    func askNetworkLibraryForSourceList(item: SourceListItem) {
        print("about to ask network library for source list")
        let networkedLibraryIP = NSUserDefaults.standardUserDefaults().stringForKey("testIPList")
        let delegate = SharedLibraryRequestDelegate()
        delegate.listRequest(networkedLibraryIP!, parentItem: item)
    }
    
    func outlineView(outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAtPoint screenPoint: NSPoint, forItems draggedItems: [AnyObject]) {
        print("called")
    }
    
    
    func outlineView(outlineView: NSOutlineView, writeItems items: [AnyObject], toPasteboard pasteboard: NSPasteboard) -> Bool {
        print(items)
        draggedNodes = items as? [NSTreeNode]
        pasteboard.setData(nil, forType: "SourceListItem")
        return true
    }
    
    func outlineView(outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: AnyObject?, proposedChildIndex index: Int) -> NSDragOperation {
        print("validate drop called on source list")
        print(info.draggingPasteboard().dataForType("Track"))
        if draggedNodes != nil {
            for draggedNode in draggedNodes! {
                if item == nil || item?.parentNode == nil || ((draggedNode).parentNode?.representedObject! as! SourceListItem).name != (item?.representedObject! as! SourceListItem).name {
                    print("weird clause reached")
                    return .None
                }
            }
        }
        if info.draggingPasteboard().dataForType("Track") != nil {
            print("non nil track data")
            if (item!.representedObject! as! SourceListItem).name == "Playlists" {
                return .Generic
            }
        }
        return .Move
    }
    
    override func objectDidEndEditing(editor: AnyObject) {
        print("objectdidendediting called")
        reorderChildren(editor as! NSTreeNode)
        super.objectDidEndEditing(editor)
    }
    
    func addVisibleNetworkLibrary() {
        
    }
    
    func outlineView(outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: AnyObject?, childIndex index: Int) -> Bool {
        if draggedNodes != nil {
            let path = (item as! NSTreeNode).indexPath.indexPathByAddingIndex(index)
            self.moveNodes(draggedNodes!, toIndexPath: path)
            reorderChildren(item as! NSTreeNode)
            draggedNodes = nil
            return true
        } else if info.draggingPasteboard().dataForType("Track") != nil {
            print("doing stuff")
            let playlistItem = (item as! NSTreeNode).representedObject! as! SourceListItem
            let playlist = playlistItem.playlist
            let data = info.draggingPasteboard().dataForType("Track")
            let unCodedThing = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as! NSMutableArray
            let tracks = { () -> [Track] in
                var result = [Track]()
                for trackURI in unCodedThing {
                    let id = managedContext.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(trackURI as! NSURL)
                    result.append(managedContext.objectWithID(id!) as! Track)
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
                playlist?.track_id_list = id_list
            }

        }
        return true
    }

}
