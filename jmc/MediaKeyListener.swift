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
    
    var backKeyPressed = false
    var playKeyPressed = false
    var skipKeyPressed = false
    
    let callback: @convention(c) (OpaquePointer, CGEventType, CGEvent, Optional<UnsafeMutableRawPointer>) -> Optional<Unmanaged<CGEvent>> = { (proxy: OpaquePointer, type: CGEventType, event: CGEvent, refcon: Optional<UnsafeMutableRawPointer>) -> Optional<Unmanaged<CGEvent>> in
        guard type == CGEventType(rawValue: UInt32(NX_SYSDEFINED)) else { return Unmanaged.passRetained(event) }
        guard let keyEvent = NSEvent(cgEvent: event) else { return Unmanaged.passRetained(event) }
        guard keyEvent.subtype == NSEventSubtype.init(rawValue: 8) else { return Unmanaged.passRetained(event) }
        let this = Unmanaged<MediaKeyListener>.fromOpaque(refcon!).takeUnretainedValue()
        let keyCode = Int32((keyEvent.data1 & 0xFFFF0000) >> 16)
        let keyFlags = keyEvent.data1 & 0xFFFF
        let keyState = (keyFlags & 0xFF00) >> 8
        let keyIsRepeat = (keyFlags & 0x1) > 0
        switch keyCode {
        case NX_KEYTYPE_PLAY:
            if keyState == 0x0A {
                this.playKeyPressed = true
                if keyIsRepeat {
                    this.sendPlayEvent()
                }
            } else if keyState == 0x0B {
                if this.playKeyPressed {
                    this.sendPlayEvent()
                }
                this.playKeyPressed = false
            } else {
                
            }
        case NX_KEYTYPE_FAST:
            if keyState == 0x0A {
                this.skipKeyPressed = true
                if keyIsRepeat {
                    this.sendSkipEvent()
                }
            } else if keyState == 0x0B {
                if this.skipKeyPressed {
                    this.sendSkipEvent()
                }
                this.skipKeyPressed = false
            } else {
                
            }
        case NX_KEYTYPE_REWIND:
            if keyState == 0x0A {
                this.backKeyPressed = true
                if keyIsRepeat {
                    this.sendSkipBackEvent()
                }
            } else if keyState == 0x0B {
                if this.backKeyPressed {
                    this.sendSkipBackEvent()
                }
                this.backKeyPressed = false
            } else {
                
            }
        default:
            break
        }
        print(keyCode)
        return Unmanaged.passRetained(event)
    }
    
    func sendPlayEvent() {
        DispatchQueue.main.async {
            self.delegate.mainWindowController?.interpretSpacebarEvent()
        }
    }
    
    func sendSkipEvent() {
        DispatchQueue.main.async {
            self.delegate.mainWindowController?.skip()
        }
    }
    
    func sendSkipBackEvent() {
        DispatchQueue.main.async {
            self.delegate.mainWindowController?.skipBackward()
        }
    }
    
    init(_ delegate: AppDelegate) {
        self.delegate = delegate
        super.init()
        //DispatchQueue.global(qos: .default).async {
            let options = CGEventTapOptions.defaultTap
            let eventsOfInterest: UInt64 = UInt64(1 << NX_SYSDEFINED)
            let machPort = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: options, eventsOfInterest: eventsOfInterest, callback: self.callback, userInfo: Unmanaged.passRetained(self).toOpaque())
            let eventPortSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, machPort!, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), eventPortSource, CFRunLoopMode.commonModes)
            print("created event tap")
        //}
    }
}
