//
//  LibraryTableViewController.swift
//  minimalTunes
//
//  Created by John Moody on 12/1/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class LibraryTableViewControllerCellBased: LibraryTableViewController {
    
    override func viewDidLoad() {
        self.tableView.doubleAction = #selector(tableViewDoubleClick)
        columnVisibilityMenu.delegate = self
        self.initializeColumnVisibilityMenu(self.tableView)
        tableView.setDelegate(trackViewArrayController)
        tableView.setDataSource(trackViewArrayController)
        tableView.libraryTableViewController = self
        tableView.reloadData()
        tableView.focusRingType = .None
        self.view.window?.makeFirstResponder(self)
        super.viewDidLoad()
        // Do view setup here.
    }
}
