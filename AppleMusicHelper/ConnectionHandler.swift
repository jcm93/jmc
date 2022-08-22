//
//  ConnectionHandler.swift
//  AppleMusicHelper
//
//  Created by John Moody on 8/22/22.
//  Copyright © 2022 John Moody. All rights reserved.
//

import Foundation


class ConnectionHandler: NSObject, NSXPCListenerDelegate {
    
    var listener: NSXPCListener!
    var helper: jmcHelper!
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: jmcHelperProtocol.self)
        newConnection.exportedObject = helper
        return true
    }
    
    override init() {
        super.init()
        self.helper = jmcHelper()
        self.listener = NSXPCListener.service()
        self.listener.delegate = self
        listener.resume()
    }
}
