//
//  MainTableViewDataSource.swift
//  minimalTunes
//
//  Created by John Moody on 10/29/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
import CoreData


class MainTableViewDataSource: NSObject, NSTableViewDataSource {
    
    lazy var cachedOrders: [CachedOrder]? = {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedOrder")
        do {
            let result = try managedContext.fetch(request) as! [CachedOrder]
            return result
        } catch {
            print(error)
            return nil
        }
    }()
    
    override init() {
        super.init()
        currentOrder = cachedOrders![0]
        currentArray = currentOrder?.track_views?.array as? [TrackView]
    }
    
    var currentOrder: CachedOrder?
    var currentArray: [TrackView]?
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        print("number rows in table view called: \(currentArray!.count)")
        return currentArray!.count
    }
    
    
    
    
}
