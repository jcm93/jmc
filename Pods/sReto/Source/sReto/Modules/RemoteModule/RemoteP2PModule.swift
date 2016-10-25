//
//  RemoteModule.swift
//  sReto
//
//  Created by Julian Asamer on 06/08/14.
//  Copyright (c) 2014 - 2016 Chair for Applied Software Engineering
//
//  Licensed under the MIT License
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  The software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness
//  for a particular purpose and noninfringement. in no event shall the authors or copyright holders be liable for any claim, damages or other liability, 
//  whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.
//

import Foundation
import SocketRocket

/**
* Using a RemoteP2PModule with the LocalPeer allows it to discover and connect with other peers over the internet using a RemoteP2P server.
*
* To use this module, you need to first deploy the RemoteP2P server (it can be found in the RemoteP2P directory in Reto's repository).
*
* Besides that, if you wish to use the RemoteP2P module, all you need to do is construct an instance and pass it to the LocalPeer either in the constructor or using the addModule method.
* */
public class RemoteP2PModule: Module, Advertiser, Browser, SRWebSocketDelegate {
    
    public var browserDelegate: BrowserDelegate?
    public var advertiserDelegate: AdvertiserDelegate?
    public var isBrowsing: Bool { get { return self.wantsToBrowse && self.isConnected } }
    public var isAdvertising: Bool { get { return self.wantsToAdvertise && self.isConnected } }
    public var isConnected: Bool = false
    
    var wantsToAdvertise: Bool = false
    var wantsToBrowse: Bool = false
    var localPeerIdentifier: UUID = UUID_ZERO
    let discoveryUrl: NSURL
    let requestConnectionUrl: NSURL
    let acceptConnectionUrl: NSURL
    var discoverySocket: SRWebSocket?
    var addresses: [UUID: RemoteP2PAddress] = [:]
    // Temporary storage to keep the handlers from being deallocated
    var acceptSocketHandlers: Set<AcceptingConnectionSocketDelegate> = []
    
    override public var description: String {
        return "RemoteP2PModule: {" +
            "isAdvertising: \(self.isAdvertising), " +
            "isBrowsing: \(self.isBrowsing), " +
            "discoverySocket: \(self.discoverySocket), " +
            "addresses: \(self.addresses)}"
    }
    
    public init(baseUrl: NSURL, dispatchQueue: dispatch_queue_t) {
        self.discoveryUrl = baseUrl.URLByAppendingPathComponent("RemoteP2P/discovery")
        self.requestConnectionUrl = baseUrl.URLByAppendingPathComponent("RemoteP2P/connection/request/")
        self.acceptConnectionUrl = baseUrl.URLByAppendingPathComponent("RemoteP2P/connection/accept/")
        super.init(dispatchQueue: dispatchQueue)
        super.advertiser = self
        super.browser = self
    }
    
    deinit {
        if let socket = self.discoverySocket {
            socket.close()
        }
    }
    
    func startDiscoverySocket() {
        if self.discoverySocket != nil { return }
        
        let socket = SRWebSocket(URLRequest: NSURLRequest(URL: self.discoveryUrl))
        socket.setDelegateDispatchQueue(self.dispatchQueue)
        socket.delegate = self
        socket.open()
        self.discoverySocket = socket
    }
    
    func stopDiscoverySocket() {
        if !isBrowsing && !isAdvertising {
            self.isConnected = false
            self.discoverySocket?.close()
            self.discoverySocket = nil
        }
    }

    public func startBrowsing() {
        startDiscoverySocket()
        self.wantsToBrowse = true
        self.sendRemotePacket(.StartBrowsing)
    }
    
    public func stopBrowsing() {
        stopDiscoverySocket()
        self.wantsToBrowse = false
        self.sendRemotePacket(.StopBrowsing)
    }
  
    public func startAdvertising(identifier: UUID) {
        self.localPeerIdentifier = identifier
        self.wantsToAdvertise = true
        startDiscoverySocket()
        self.sendRemotePacket(.StartAdvertisement)
    }
    
    public func stopAdvertising() {
        self.wantsToAdvertise = false
        stopDiscoverySocket()
        self.sendRemotePacket(.StopAdvertisement)
    }
    
    func sendRemotePacket(type: RemoteP2PPacketType) {
        if let socket = self.discoverySocket {
            if !self.isConnected { return }
            let packet = RemoteP2PPacket(type: type, identifier: self.localPeerIdentifier)
            socket.send(packet.serialize())
        }
    }
    
    func addPeer(identifier: UUID) {
        log(.Low, info: "discovered peer: \(identifier.UUIDString)")
        
        if (self.isBrowsing) {
            let connectionRequestUrl = self.requestConnectionUrl
                .URLByAppendingPathComponent(self.localPeerIdentifier.UUIDString)
                .URLByAppendingPathComponent(identifier.UUIDString)
            let address = RemoteP2PAddress(serverUrl: connectionRequestUrl, dispatchQueue: self.dispatchQueue)
            self.addresses[identifier] = address
            self.browserDelegate?.didDiscoverAddress(self, address: address, identifier: identifier)
        }
    }
    
    func removePeer(identifier: UUID) {
        if (self.isBrowsing) {
            let address = self.addresses[identifier]
            self.addresses[identifier] = nil
            if let address = address {
                self.browserDelegate?.didRemoveAddress(self, address: address, identifier: identifier)
            } else {
                log(.Low, warning: "attempted to remove an address for which no address exists.")
            }
        }
    }
    
    class AcceptingConnectionSocketDelegate: NSObject, SRWebSocketDelegate {
        let openBlock: (AcceptingConnectionSocketDelegate) -> ()
        let failBlock: (AcceptingConnectionSocketDelegate) -> ()
        
        init(openBlock: (AcceptingConnectionSocketDelegate) -> (), failBlock: (AcceptingConnectionSocketDelegate) -> ()) {
            self.openBlock = openBlock
            self.failBlock = failBlock
        }
        
        func webSocketDidOpen(webSocket: SRWebSocket!) { openBlock(self) }
        func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {}
        func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) { failBlock(self) }
        func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) { failBlock(self) }
    }
    
    func respondToConnectionRequest(identifier: UUID) {
        let acceptConnectionUrl = self.acceptConnectionUrl
            .URLByAppendingPathComponent(self.localPeerIdentifier.UUIDString)
            .URLByAppendingPathComponent(identifier.UUIDString)
        let socket = SRWebSocket(URL: acceptConnectionUrl)
        socket.setDelegateDispatchQueue(self.dispatchQueue)
        let socketHandler = AcceptingConnectionSocketDelegate(
            openBlock: {
                socketHandler in
                self.advertiserDelegate?.handleConnection(self, connection: RemoteP2PConnection(socket: socket, dispatchQueue: self.dispatchQueue))
                self.acceptSocketHandlers -= socketHandler
                return ()
            },
            failBlock: {
                socketHandler in
                self.acceptSocketHandlers -= socketHandler
                return ()
            }
        )
        acceptSocketHandlers += socketHandler
        socket.delegate = socketHandler
        socket.open()
    }
    
    @objc public func webSocketDidOpen(webSocket: SRWebSocket!) {
        self.isConnected = true
        if self.wantsToAdvertise {
            self.sendRemotePacket(.StartAdvertisement)
            self.advertiserDelegate?.didStartAdvertising(self)
        }
        if self.isBrowsing {
            self.sendRemotePacket(.StartBrowsing)
            self.browserDelegate?.didStartBrowsing(self)
        }
    }
    
    @objc public func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        log(.Medium, info: "Closed discovery websocket with close code: \(code), reason: \(reason), wasCLean: \(wasClean)")
        self.isConnected = false
        self.discoverySocket = nil
        self.browserDelegate?.didStopBrowsing(self)
        self.advertiserDelegate?.didStopAdvertising(self)
    }
    
    @objc public func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
        log(.Medium, info: "Discovery WebSocket failed with error: \(error)")
        self.isConnected = false
        self.discoverySocket = nil
        self.browserDelegate?.didStopBrowsing(self)
        self.advertiserDelegate?.didStopAdvertising(self)
    }
    
    @objc public func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        if let data = message as? NSData {
            if let packet = RemoteP2PPacket.fromData(DataReader(data)) {
                switch packet.type {
                    case .PeerAdded: self.addPeer(packet.identifier)
                    case .PeerRemoved: self.removePeer(packet.identifier)
                    case .ConnectionRequest: self.respondToConnectionRequest(packet.identifier)
                    default: log(.High, error: "Received unexpected packet type: \(packet.type.rawValue)")
                }
            } else {
                log(.High, error: "discovery packet could not be parsed.")
            }
        } else {
            log(.High, error: "message is not data.")
        }
    }
}
