//
//  WlanBonjourServiceAdvertiser.swift
//  sReto
//
//  Created by Julian Asamer on 25/07/14.
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

class WlanBonjourServiceAdvertiser: NSObject, BonjourServiceAdvertiser, NSNetServiceDelegate {
    var delegate: BonjourServiceAdvertiserDelegate?
    var netService : NSNetService?

    func startAdvertising(name: String, type: String, port: UInt) {
        let netService = NSNetService(domain: "", type: type, name: name, port: Int32(port))
        self.netService = netService
        
        netService.delegate = self
        netService.publish()
    }
    
    func stopAdvertising() {
        if let netService = self.netService {
            netService.stop()
            netService.delegate = nil
            self.netService = nil
        }
        
        self.delegate?.didStop()
    }
    
    func netServiceDidPublish(sender: NSNetService) {
        log(.Low, info: "published wlan bonjour address: \(sender.name)")
        self.delegate?.didPublish()
    }
    
    func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber]) {
        log(.Medium, error: "failed to publish on wlan: \(errorDict)")
        self.delegate?.didNotPublish()
    }
    
    func netServiceDidStop(sender: NSNetService){
        log(.Medium, info: "stopped publishing on wlan")
        self.delegate?.didStop()
    }
}
