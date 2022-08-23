//
//  ConnectionHandler.swift
//  jmc
//
//  Created by John Moody on 8/23/22.
//  Copyright © 2022 John Moody. All rights reserved.
//

import Foundation


class ConnectionHandler: NSObject, NSXPCListenerDelegate {
    
    var listener: NSXPCListener!
    var helper: jmcHelper!
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: jmcHelperProtocol.self)
        newConnection.exportedObject = helper
        newConnection.resume()
        return true
    }
    
    override init() {
        super.init()
        self.helper = jmcHelper()
        self.listener = NSXPCListener.init(machServiceName: "com.jcm.jmcHelper")
        self.listener.delegate = self
        //listener.resume()
    }
}
