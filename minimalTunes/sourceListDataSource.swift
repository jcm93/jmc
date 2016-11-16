//
//  sourceListDataSource.swift
//  minimalTunes
//
//  Created by John Moody on 11/14/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class SourceListNode {
    var item: SourceListItem
    var children = [SourceListNode]()
    init(item: SourceListItem) {
        self.item = item
    }
}

class SourceListDataSource: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    var root: SourceListItem
    
    init(root: SourceListItem) {
        self.root = root
    }
    
    var rootNode: SourceListNode?
    
    func createTree() {
        rootNode = SourceListNode(item: root)
        var nodesNotVisited = [SourceListItem]()
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
            if newNode.item.parent == currentNode?.item {
                currentNode?.children.append(newNode)
            } else {
                currentNode = newNode
            }
        }
    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil {
            return 3
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
            return rootNode!.children[index]
        }
        let source = item as! SourceListNode
        let child = source.children[index]
        return child
    }
    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
        let source = item as! SourceListNode
        if (source.item.is_header == true) {
            return outlineView.makeViewWithIdentifier("HeaderCell", owner: self)
        } else if source.item.playlist != nil {
            return outlineView.makeViewWithIdentifier("PlaylistCell", owner: self)
        } else if source.item.is_network == true {
            return outlineView.makeViewWithIdentifier("NetworkLibraryCell", owner: self)
        } else if source.item.playlist_folder != nil {
            return outlineView.makeViewWithIdentifier("SongCollectionFolder'", owner: self)
        } else if source.item.master_playlist != nil {
            return outlineView.makeViewWithIdentifier("MasterPlaylistCell", owner: self)
        } else {
            return outlineView.makeViewWithIdentifier("PlaylistCell", owner: self)
        }
    }
}
