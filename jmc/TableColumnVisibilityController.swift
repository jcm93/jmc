//
//  TableColumnVisibilityController.swift
//  minimalTunes
//
//  Created by John Moody on 10/25/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
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


class TableColumnVisibilityController {
    
    var columnVisibilityDictionary = NSMutableDictionary()
    var tables: [NSTableView]?
    
    func columnDidChangeVisibility(_ column: NSTableColumn) {
        let identifier = column.identifier
        let hidden = column.isHidden
        columnVisibilityDictionary[identifier] = hidden
        if tables?.count > 0 {
            for table in tables! {
                table.tableColumn(withIdentifier: identifier)?.isHidden = hidden
            }
        }
    }
    
    func addTable(_ table: NSTableView) {
        tables?.append(table)
    }
    
    init(masterTable: NSTableView) {
        for tableColumn in masterTable.tableColumns {
            let identifier = tableColumn.identifier
            let hidden = tableColumn.isHidden
            self.columnVisibilityDictionary[identifier] = hidden
        }
    }
}
