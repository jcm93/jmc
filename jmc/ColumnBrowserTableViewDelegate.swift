//
//  ColumnBrowserTableViewDelegate.swift
//  minimalTunes
//
//  Created by John Moody on 6/21/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class ColumnBrowserTableViewDelegate: NSObject, NSTableViewDelegate {
    
    /*func tableViewSelectionDidChange(notification: NSNotification) {
        print("i am called")
        let table = notification.object as! TableViewYouCanPressSpacebarOn
        let pred = table.mainWindowController?.tableViewArrayController.filterPredicate
        print(pred)
        if table.windowIdentifier == "artist" {
            if (table.mainWindowController?.artistArrayController.selectedObjects[0] != nil) {
                let artist = table.mainWindowController?.artistArrayController.selectedObjects[0] as! Artist
                table.mainWindowController?.tableViewArrayController.filterPredicate = NSPredicate(format: "artist.name == %@", artist.name!)
            }
        }
    }*/
}
