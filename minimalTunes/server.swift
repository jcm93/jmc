//
//  server.swift
//  minimalTunes
//
//  Created by John Moody on 9/30/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Foundation
import Foundation

extension OptionSetType {
    func containsAny(other: Self) -> Bool {
        return !intersect(other).isEmpty
    }
}

protocol SessionDelegate {
    func sessionClosed(session: EchoSession)
}

class EchoSession: NSObject, NSStreamDelegate {
    let input: NSInputStream
    let output: NSOutputStream
    var dataBuffer: NSMutableData = NSMutableData()
    var buffer = [UInt8](count: 1024, repeatedValue: 0)
    
    var sessionDelegate: SessionDelegate?
    
    
    init (input: NSInputStream, output: NSOutputStream) {
        self.input = input
        self.output = output
        super.init()
    }
    
    
    
    func open() {
        input.delegate = self
        output.delegate = self
        input.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        output.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        input.open()
        output.open()
    }
    
    func close() {
        print("closing")
        input.delegate = nil
        output.delegate = nil
        input.close()
        output.close()
        input.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        output.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        sessionDelegate?.sessionClosed(self)
    }
    
    deinit {
        print("killed")
    }
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        print("event happened \(eventCode)")
        if eventCode.contains(.HasBytesAvailable) {
            print("bytes available")
            let actuallyRead = input.read(&buffer, maxLength: 1024)
            if actuallyRead > 0 {
                let actuallyWritten = output.write(buffer, maxLength: actuallyRead)
                if actuallyRead != actuallyWritten {
                    close()
                } else {
                    print(buffer)
                    print("Echoed \(actuallyWritten) bytes")
                }
            }
        } else if eventCode.containsAny([.EndEncountered, .ErrorOccurred]) {
            print("something happened")
            close()
        }
    }
}

func handle (value: Int32) -> Void {
    print("hello signal")
}

func source_handle () -> Void {
    print("nanananana")
}

func reg_signal_handler(sig: Int32, handler: ()->Void) {
    signal(sig, SIG_IGN)
    let source = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, UInt(sig), 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
    dispatch_source_set_event_handler(source, handler)
    dispatch_resume(source)
}

class Server: SessionDelegate {
    var sessions: [EchoSession] = []
    
    func htons (port:in_port_t) -> in_port_t {
        return Int(OSHostByteOrder()) == OSLittleEndian ? _OSSwapInt16(port) : port
    }
    
    init() {
        print("PID: \(getpid())")
        
        reg_signal_handler(SIGHUP) { () -> Void in
            self.stop()
        }
        reg_signal_handler(SIGINFO) { () -> Void in
            self.logSessions()
        }
    }
    
    func sessionClosed(note: NSNotification) {
        if let session = note.object as? EchoSession,
            index = sessions.indexOf(session) {
            sessions.removeAtIndex(index)
        }
    }
    
    var isRunning: Bool = false
    var ipv4sock: CFSocket?
    var ipv6sock: CFSocket?
    
    func stop() {
        for session in sessions {
            session.close()
        }
        
        if ipv4sock != nil {
            CFSocketInvalidate(ipv4sock!)
        }
        if ipv6sock != nil {
            CFSocketInvalidate(ipv6sock!)
        }
        isRunning = false
    }
    
    func listen () -> Bool {
        var socketContext = CFSocketContext()
        let ptr = UnsafeMutablePointer<Server>.alloc(1)
        ptr.initialize(self)
        socketContext.info = UnsafeMutablePointer<Void>(ptr)
        
        var sin4 = sockaddr_in()
        let port = 9999
        sin4.sin_len = __uint8_t(sizeof(sockaddr_in))
        sin4.sin_family = sa_family_t(AF_INET)
        sin4.sin_port = htons(in_port_t(port))
        sin4.sin_addr.s_addr = inet_addr("127.0.0.1")
        
        
        var sin6 = sockaddr_in6()
        sin6.sin6_len = __uint8_t(sizeof(sockaddr_in6))
        sin6.sin6_family = sa_family_t(AF_INET6)
        sin6.sin6_port = htons(in_port_t(port))
        sin6.sin6_addr = in6addr_loopback
        
        let result = withUnsafePointers(&sin4, &sin6, &socketContext) { sinPtr, sin6Ptr, ctxtPtr -> Bool in
            ipv4sock = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_UDP, CFSocketCallBackType.AcceptCallBack.rawValue, acceptConnection, ctxtPtr)
            ipv6sock = CFSocketCreate(kCFAllocatorDefault, PF_INET6, SOCK_STREAM, IPPROTO_UDP, CFSocketCallBackType.AcceptCallBack.rawValue, acceptConnection, ctxtPtr)
            var yes = 1
            setsockopt(CFSocketGetNative(ipv4sock!), SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(sizeofValue(yes)))
            setsockopt(CFSocketGetNative(ipv6sock!), SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(sizeofValue(yes)))
            var data = CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(sinPtr), sizeof(sockaddr_in))
            var err = CFSocketSetAddress(ipv4sock!, data)
            let stop:()->Void = {
                
            }
            if err != .Success {
                stop()
                return false
            }
            data = CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(sin6Ptr), sizeof(sockaddr_in6))
            err = CFSocketSetAddress(ipv6sock!, data)
            if err != .Success {
                stop()
                return false
            }
            let source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, ipv4sock!, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source4, kCFRunLoopDefaultMode)
            let source6 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, ipv6sock!, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source6, kCFRunLoopDefaultMode)
            return true
        }
        if result {
            isRunning = true
        }
        return result
    }
    
    func addSession(session: EchoSession) {
        session.sessionDelegate = self
        sessions.append(session)
    }
    
    func sessionClosed(session: EchoSession) {
        if let index = sessions.indexOf(session) {
            sessions.removeAtIndex(index)
        }
    }
    
    func logSessions() {
        print("Sessions:\(sessions)")
    }
}

func acceptConnection(socket:CFSocket!, callbackType:CFSocketCallBackType, address:CFData!, data: UnsafePointer<Void>, context: UnsafeMutablePointer<Void>) {
    if callbackType.contains(.AcceptCallBack) {
        print("accepted connection")
        let nativeSocket = UnsafePointer<CFSocketNativeHandle>(data).memory
        var read: Unmanaged<CFReadStream>? = nil
        var write: Unmanaged<CFWriteStream>? = nil
        withUnsafeMutablePointers(&read, &write, { (readPtr, writePtr) -> Void in
            CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocket, readPtr, writePtr)
        })
        let nsRead = read!.takeRetainedValue() as NSInputStream
        let nsWrite = write!.takeRetainedValue() as NSOutputStream
        let echoSession = EchoSession(input: nsRead, output: nsWrite)
        let ptr = UnsafeMutablePointer<Server>(context)
        let server = ptr.memory
        server.addSession(echoSession)
        echoSession.open()
    }
}