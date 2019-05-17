//
//  MediaKeyListener.swift
//  jmc
//
//  Created by John Moody on 8/10/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

private var my_context = 0

class MediaKeyListener: NSObject {
    
    //adapted from SPMediaKeyTap: https://github.com/nevyn/SPMediaKeyTap/
    
    let delegate: AppDelegate
    var machPort: CFMachPort!
    
    var shouldInterceptMediaKeys: Bool {
        get {
            return self.bundleList[0] == Bundle.main.bundleIdentifier!
        }
    }
    
    var backKeyPressed = false
    var playKeyPressed = false
    var skipKeyPressed = false
    
    var bundleList = [ Bundle.main.bundleIdentifier!,
    "com.spotify.client",
    "com.apple.iTunes",
    "com.apple.QuickTimePlayerX",
    "com.apple.quicktimeplayer",
    "com.apple.iWork.Keynote",
    "com.apple.iPhoto",
    "org.videolan.vlc",
    "com.apple.Aperture",
    "com.plexsquared.Plex",
    "com.soundcloud.desktop",
    "org.niltsh.MPlayerX",
    "com.ilabs.PandorasHelper",
    "com.mahasoftware.pandabar",
    "com.bitcartel.pandorajam",
    "org.clementine-player.clementine",
    "fm.last.Last.fm",
    "fm.last.Scrobbler",
    "com.beatport.BeatportPro",
    "com.Timenut.SongKey",
    "com.macromedia.fireworks", // the tap messes up their mouse input
    "at.justp.Theremin",
    "ru.ya.themblsha.YandexMusic",
    "com.jriver.MediaCenter18",
    "com.jriver.MediaCenter19",
    "com.jriver.MediaCenter20",
    "co.rackit.mate",
    "com.ttitt.b-music",
    "com.beardedspice.BeardedSpice",
    "com.plug.Plug",
    "com.plug.Plug2",
    "com.netease.163music",
    "org.quodlibet.quodlibet"]
    
    @objc func activeApplicationDidChange(_ notification: Notification) {
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        if let bundleIdentifier = application.bundleIdentifier, let index = bundleList.firstIndex(of: bundleIdentifier) {
            bundleList.remove(at: index)
            bundleList.insert(bundleIdentifier, at: 0)
        }
    }
    
    func startListeningToAppSwitching() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(activeApplicationDidChange), name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }

    let callback: @convention(c) (OpaquePointer, CGEventType, CGEvent, Optional<UnsafeMutableRawPointer>) -> Optional<Unmanaged<CGEvent>> = {
        (proxy: OpaquePointer, type: CGEventType, event: CGEvent, refcon: Optional<UnsafeMutableRawPointer>) -> Optional<Unmanaged<CGEvent>> in
        if type == CGEventType.tapDisabledByTimeout || type == CGEventType.tapDisabledByUserInput {
            let this = Unmanaged<MediaKeyListener>.fromOpaque(refcon!).takeUnretainedValue()
            CGEvent.tapEnable(tap: this.machPort, enable: true)
        }
        guard type == CGEventType(rawValue: UInt32(NX_SYSDEFINED)) else { return Unmanaged.passUnretained(event) }
        guard let keyEvent = NSEvent(cgEvent: event) else { return Unmanaged.passUnretained(event) }
        guard keyEvent.subtype == NSEvent.EventSubtype.init(rawValue: 8) else { return Unmanaged.passUnretained(event) }
        let this = Unmanaged<MediaKeyListener>.fromOpaque(refcon!).takeUnretainedValue()
        guard this.shouldInterceptMediaKeys else { return Unmanaged.passUnretained(event) }
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
            }
        default:
            return Unmanaged.passUnretained(event)
        }
        print(keyCode)
        return nil
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
        defer {
            CFRunLoopRun()
        }
        self.delegate = delegate
        super.init()
        let options = CGEventTapOptions.defaultTap
        let eventsOfInterest: UInt64 = UInt64(1 << NX_SYSDEFINED)
        let machPort = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: options, eventsOfInterest: eventsOfInterest, callback: self.callback, userInfo: Unmanaged.passUnretained(self).toOpaque())
        self.machPort = machPort
        let eventPortSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, machPort!, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), eventPortSource, CFRunLoopMode.commonModes)
        print("created event tap")
        self.startListeningToAppSwitching()
    }
}
