//
//  DragAndDropTreeController.swift
//  minimalTunes
//
//  Created by John Moody on 7/2/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

extension NSTreeController {
    
    func indexPathOfObject(_ anObject:NSObject) -> IndexPath? {
        return self.indexPathOfObject(anObject, nodes: (self.arrangedObjects as AnyObject).children)
    }
    
    func indexPathOfObject(_ anObject:NSObject, nodes:[NSTreeNode]!) -> IndexPath? {
        for node in nodes {
            if (anObject == node.representedObject as! NSObject)  {
                return node.indexPath
            }
            if (node.children != nil) {
                if let path:IndexPath = self.indexPathOfObject(anObject, nodes: node.children)
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
        return (NSApplication.shared().delegate
            as? AppDelegate)?.managedObjectContext }()!
    
    var playlistHeaderNode: SourceListItem?
    var libraryHeaderNode: SourceListItem?
    var sharedHeaderNode: SourceListItem?
    var networkedLibraries: NSMutableDictionary = [:]
    
    func networkedLibraryWithName(_ name: String) -> SourceListItem? {
        return networkedLibraries[name] as? SourceListItem
    }
    
    func reorderChildren(_ item: NSTreeNode) {
        if item.children != nil {
            var poop = item.children!
            for i in 0..<poop.count {
                (poop[i].representedObject as! SourceListItem).sort_order = i as NSNumber?
            }
        }
    }
    
    /*func outlineViewItemDidExpand(notification: NSNotification) {
        print("called")
        if (notification.object as! SourceListItem).network_library != nil {
            askNetworkLibraryForSourceList(notification.object as! SourceListItem)
        }
    }*/
    
    func getNetworkPlaylistWithID(_ id: Int) -> SourceListItem {
        return self.selectedObjects[0] as! SourceListItem
    }
    
    func addNetworkedLibrary(_ name: String, address: String) {
        let newSourceListItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        newSourceListItem.parent = self.sharedHeaderNode
        newSourceListItem.name = name
        newSourceListItem.is_network = true
        //let newNetworkLibrary = NSEntityDescription.insertNewObjectForEntityForName("NetworkLibrary", inManagedObjectContext: managedContext) as! SharedLibrary
        // newNetworkLibrary.address = address
        networkedLibraries[name] = newSourceListItem
    }
    
    func addSourcesForNetworkedLibrary(_ sourceData: [NSDictionary], item: SourceListItem) {
        let masterItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        masterItem.name = "Music"
        masterItem.parent = item
        masterItem.is_network = true
        for playlist in sourceData {
            let newItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
            newItem.sort_order = playlist["sort_order"] as! Int as NSNumber?
            newItem.name = playlist["name"] as? String
            let newPlaylist = NSEntityDescription.insertNewObject(forEntityName: "SongCollection", into: managedContext) as! SongCollection
            newPlaylist.id = playlist["id"] as! Int as NSNumber?
            newItem.playlist = newPlaylist
            newItem.parent = item
            newItem.is_network = true
        }
    }
    
    func removeNetworkedLibrary(_ name: String) {
        let item = networkedLibraries[name] as! SourceListItem
        //remove it
    }
    


}
