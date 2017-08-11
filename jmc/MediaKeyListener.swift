//
//  MediaKeyListener.swift
//  jmc
//
//  Created by John Moody on 8/10/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class MediaKeyListener: NSObject {
    
    let delegate: AppDelegate
    
    let callback: @convention(c) (OpaquePointer, CGEventType, CGEvent, Optional<UnsafeMutableRawPointer>) -> Optional<Unmanaged<CGEvent>> = { (proxy: OpaquePointer, type: CGEventType, event: CGEvent, refcon: Optional<UnsafeMutableRawPointer>) -> Optional<Unmanaged<CGEvent>> in
        print("callback")
        let value = event.getIntegerValueField(CGEventField.keyboardEventKeycode)
        print(value)
        return Unmanaged.passRetained(event)
    }
    
    init(_ delegate: AppDelegate) {
        self.delegate = delegate
        super.init()
        let placement = CGEventTapPlacement.headInsertEventTap
        let options = CGEventTapOptions.defaultTap
        let eventsOfInterest: UInt64 = UInt64(NX_SYSDEFINED)
        let doingus = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: options, eventsOfInterest: eventsOfInterest, callback: self.callback, userInfo: nil)
        let eventPortSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, doingus!, 0)
        print("created event tap")
    }
}
