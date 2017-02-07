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
        tableView.delegate = trackViewArrayController
        tableView.dataSource = trackViewArrayController
        tableView.libraryTableViewController = self
        tableView.reloadData()
        tableView.focusRingType = .none
        self.view.window?.makeFirstResponder(self)
        super.viewDidLoad()
        // Do view setup here.
    }
}
