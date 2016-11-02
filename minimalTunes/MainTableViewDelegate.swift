//
//  MainTableViewDelegate.swift
//  minimalTunes
//
//  Created by John Moody on 11/2/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class MainTableViewDelegate: NSObject, NSTableViewDelegate {
    
    lazy var cachedOrders: [CachedOrder]? = {
        let request = NSFetchRequest(entityName: "CachedOrder")
        do {
            let result = try managedContext.executeFetchRequest(request) as! [CachedOrder]
            return result
        } catch {
            print(error)
            return nil
        }
    }()
    
    override init() {
        super.init()
        currentOrder = cachedOrders![0]
        currentArray = currentOrder?.tracks?.array as? [Track]
    }
    
    var currentOrder: CachedOrder?
    var currentArray: [Track]?
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = tableColumn!.identifier
        let valueString: String?
        switch identifier {
        case "artist":
            let result = tableView.makeViewWithIdentifier(identifier, owner: self) as! NSTableCellView
            valueString = currentArray![row].artist?.name
            if valueString != nil {
                result.textField!.stringValue = valueString!
            }
            return result
        case "album":
            let result = tableView.makeViewWithIdentifier(identifier, owner: self) as! NSTableCellView
            valueString = currentArray![row].album?.name
            if valueString != nil {
                result.textField!.stringValue = valueString!
            }
            return result
        case "album_artist":
            let result = tableView.makeViewWithIdentifier(identifier, owner: self) as! NSTableCellView
            valueString = currentArray![row].album?.album_artist?.name
            if valueString != nil {
                result.textField!.stringValue = valueString!
            }
            return result
        case "genre":
            let result = tableView.makeViewWithIdentifier(identifier, owner: self) as! NSTableCellView
            valueString = currentArray![row].genre?.name
            if valueString != nil {
                result.textField!.stringValue = valueString!
            }
            return result
        case "composer":
            let result = tableView.makeViewWithIdentifier(identifier, owner: self) as! NSTableCellView
            valueString = currentArray![row].composer?.name
            if valueString != nil {
                result.textField!.stringValue = valueString!
            }
            return result
        case "AutomaticTableColumnIdentifier.0":
            let result = tableView.makeViewWithIdentifier(identifier, owner: self) as! NSTableCellView
            return result
        case "is_enabled":
            let result = tableView.makeViewWithIdentifier(identifier, owner: self) as! NSButton
            let track = currentArray![row]
            result.state = track.status?.charValue == 1 ? NSOnState : NSOffState
            return result
        case "date_released":
            let result = tableView.makeViewWithIdentifier(identifier, owner: self) as! NSTableCellView
            let track = currentArray![row]
            valueString = track.album?.release_date?.description
            if valueString != nil {
                result.textField!.stringValue = valueString!
            }
            return result
        case "playlist_number":
            let result = tableView.makeViewWithIdentifier(identifier, owner: self) as! NSTableCellView
            return result
        default:
            let result = tableView.makeViewWithIdentifier(identifier, owner: self) as! NSTableCellView
            let track = currentArray![row]
            valueString = track.valueForKey(identifier) as? String
            if valueString != nil {
                result.textField!.stringValue = valueString!
            }
            return result
        }
    }
}