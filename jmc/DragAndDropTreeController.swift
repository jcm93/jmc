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
    var networkedLibraries: NSMutableDictionary = [:]
    
    func networkedLibraryWithName(name: String) -> SourceListItem? {
        return networkedLibraries[name] as? SourceListItem
    }
    
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
    
    func getNetworkPlaylistWithID(id: Int) -> SourceListItem {
        return self.selectedObjects[0] as! SourceListItem
    }
    
    func addNetworkedLibrary(name: String, address: String) {
        let newSourceListItem = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
        newSourceListItem.parent = self.sharedHeaderNode
        newSourceListItem.name = name
        newSourceListItem.is_network = true
        //let newNetworkLibrary = NSEntityDescription.insertNewObjectForEntityForName("NetworkLibrary", inManagedObjectContext: managedContext) as! SharedLibrary
        // newNetworkLibrary.address = address
        networkedLibraries[name] = newSourceListItem
    }
    
    func addSourcesForNetworkedLibrary(sourceData: [NSDictionary], item: SourceListItem) {
        let masterItem = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
        masterItem.name = "Music"
        masterItem.parent = item
        masterItem.is_network = true
        for playlist in sourceData {
            let newItem = NSEntityDescription.insertNewObjectForEntityForName("SourceListItem", inManagedObjectContext: managedContext) as! SourceListItem
            newItem.sort_order = playlist["sort_order"] as! Int
            newItem.name = playlist["name"] as? String
            let newPlaylist = NSEntityDescription.insertNewObjectForEntityForName("SongCollection", inManagedObjectContext: managedContext) as! SongCollection
            newPlaylist.id = playlist["id"] as! Int
            newItem.playlist = newPlaylist
            newItem.parent = item
            newItem.is_network = true
        }
    }
    
    func removeNetworkedLibrary(name: String) {
        let item = networkedLibraries[name] as! SourceListItem
        //remove it
    }
    


}
