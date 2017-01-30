//
//  TableColumnVisibilityController.swift
//  minimalTunes
//
//  Created by John Moody on 10/25/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class TableColumnVisibilityController {
    
    var columnVisibilityDictionary = NSMutableDictionary()
    var tables: [NSTableView]?
    
    func columnDidChangeVisibility(column: NSTableColumn) {
        let identifier = column.identifier
        let hidden = column.hidden
        columnVisibilityDictionary[identifier] = hidden
        if tables?.count > 0 {
            for table in tables! {
                table.tableColumnWithIdentifier(identifier)?.hidden = hidden
            }
        }
    }
    
    func addTable(table: NSTableView) {
        tables?.append(table)
    }
    
    init(masterTable: NSTableView) {
        for tableColumn in masterTable.tableColumns {
            let identifier = tableColumn.identifier
            let hidden = tableColumn.hidden
            self.columnVisibilityDictionary[identifier] = hidden
        }
    }
}