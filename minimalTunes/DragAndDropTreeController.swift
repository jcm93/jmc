//
//  DragAndDropTreeController.swift
//  minimalTunes
//
//  Created by John Moody on 7/2/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class DragAndDropTreeController: NSTreeController, NSOutlineViewDataSource {
    
    lazy var managedContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    
    var draggedNodes: [NSTreeNode]?
    
    func reorderChildren(item: NSTreeNode) {
        if item.childNodes != nil {
            var poop = item.childNodes!
            for i in 0..<poop.count {
                (poop[i].representedObject as! SourceListItem).sort_order = i
            }
        }
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
        if draggedNodes != nil {
            for draggedNode in draggedNodes! {
                if item == nil || item?.parentNode == nil || ((draggedNode).parentNode?.representedObject! as! SourceListItem).name != (item?.representedObject! as! SourceListItem).name {
                    return .None
                }
            }
        }
        return .Move
    }
    
    func outlineView(outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: AnyObject?, childIndex index: Int) -> Bool {
        var index_offset = 0
        let path = (item as! NSTreeNode).indexPath.indexPathByAddingIndex(index)
        moveNodes(draggedNodes!, toIndexPath: path)
        reorderChildren(item as! NSTreeNode)
        return true
    }

}
