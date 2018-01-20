//
//  TrackProxy.swift
//  jmc
//
//  Created by John Moody on 1/19/18.
//  Copyright © 2018 John Moody. All rights reserved.
//

import Cocoa

protocol ReadWriteLock {
    mutating func withReadLock(block: () -> ())
    
    mutating func withWriteLock(block: () -> ())
}

 PosixRWLock: ReadWriteLock {
    
}

class TrackProxy: NSObject {
    
    
    

}
