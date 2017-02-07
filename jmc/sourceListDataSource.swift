//
//  sourceListDataSource.swift
//  minimalTunes
//
//  Created by John Moody on 11/14/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class SourceListNode: NSObject {
    var item: SourceListItem
    var children = [SourceListNode]()
    var parent: SourceListNode?
    init(item: SourceListItem) {
        self.item = item
        super.init()
        item.node = self
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
                newNode.parent = currentNode
            } else {
                currentNode = newNode
            }
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return 3
        }
        let source = item as! SourceListNode
        return source.children.count
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        let source = item as! SourceListNode
        if source.children.count > 0 {
            return true
        } else {
            return false
        }
    }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return rootNode!.children[index]
        }
        let source = item as! SourceListNode
        let child = source.children[index]
        return child
    }
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        let source = item as! SourceListNode
        if (source.item.is_header == true) {
            return outlineView.make(withIdentifier: "HeaderCell", owner: self)
        } else if source.item.playlist != nil {
            return outlineView.make(withIdentifier: "PlaylistCell", owner: self)
        } else if source.item.is_network == true {
            return outlineView.make(withIdentifier: "NetworkLibraryCell", owner: self)
        } else if source.item.is_folder == true {
            return outlineView.make(withIdentifier: "SongCollectionFolder'", owner: self)
        } else if source.item.master_playlist != nil {
            return outlineView.make(withIdentifier: "MasterPlaylistCell", owner: self)
        } else {
            return outlineView.make(withIdentifier: "PlaylistCell", owner: self)
        }
    }
}
