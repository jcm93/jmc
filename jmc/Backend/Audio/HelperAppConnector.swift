//
//  HelperAppConnector.swift
//  jmc
//
//  Created by John Moody on 8/22/22.
//  Copyright © 2022 John Moody. All rights reserved.
//

import Cocoa

class HelperAppConnector: NSObject {

    var connection: NSXPCConnection!
    //var helper: jmcHelper!
    
    func connect() {
        self.connection = NSXPCConnection.init(machServiceName: "com.jcm.jmcHelper", options: [])
        //self.connection = NSXPCConnection.init(serviceName: "com.jcm.jmcHelper")
        connection.remoteObjectInterface = NSXPCInterface(with: jmcHelperProtocol.self)
        connection.resume()
        let service = connection.remoteObjectProxyWithErrorHandler { error in
            print("received error: \(error)")
        } as! jmcHelperProtocol
        print("testing XPC")
        service.test(input: "butts") { response in
            print("response from XPC service: \(response)")
        }
    }
    
    override init() {
        super.init()
    }
}
