//
//  WlanBonjourServiceBrowser.swift
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

class WlanBonjourServiceBrowser: NSObject, BonjourServiceBrowser, NSNetServiceBrowserDelegate, NSNetServiceDelegate {
    weak var delegate: BonjourServiceBrowserDelegate?
    var browser: NSNetServiceBrowser?
    var resolvingServices: [NSNetService] = []
    
    func startBrowsing(networkType: String) {
        let browser = NSNetServiceBrowser()
        self.browser = browser
        browser.delegate = self
        browser.searchForServicesOfType(networkType, inDomain: "")
    }
    
    func stopBrowsing() {
        if let browser = self.browser {
            browser.stop()
            browser.delegate = nil
            self.browser = nil
        }
        
        self.delegate?.didStop()
    }
    
    func test(netService: NSNetService) {
        let addresses = netService.addresses!
        let uuid = UUIDfromString(netService.name)
        let addressInformation = AddressInformation.AddressAsData((addresses[0] as NSData), netService.hostName!, netService.port)
        self.delegate?.foundAddress(uuid!, addressInformation: addressInformation)
    }
    
    func addAddress(netService: NSNetService) {
        if let addresses = netService.addresses {
           log(.Low, info: "found address for: \(netService.name), there are \(addresses.count ?? 0) addresses available.")
            if let uuid = UUIDfromString(netService.name) {
                let addressInformation = AddressInformation.AddressAsData(addresses[0] as NSData, netService.hostName!, netService.port)
                self.delegate?.foundAddress(uuid, addressInformation: addressInformation)
            }
        }
    }
    
    func netServiceBrowserWillSearch(netServiceBrowser: NSNetServiceBrowser) {
        self.delegate?.didStart()
    }
    
    func netServiceBrowserDidStopSearch(netServiceBrowser: NSNetServiceBrowser) {
        self.delegate?.didStop()
    }
    
    func netServiceBrowser(netServiceBrowser: NSNetServiceBrowser, didFindService netService: NSNetService, moreComing: Bool) {
        if ((netService.addresses?.count ?? 0) != 0) {
            self.addAddress(netService)
        } else {
            netService.delegate = self
            self.resolvingServices.append(netService)
            netService.resolveWithTimeout(5)
        }
    }
    
    func netServiceBrowser(netServiceBrowser: NSNetServiceBrowser, didRemoveService netService: NSNetService, moreComing: Bool) {
        netService.delegate = nil
        if let uuid = UUIDfromString(netService.name) {
            self.delegate?.removedAddress(uuid)
        }
    }
    
    func netServiceDidResolveAddress(netService: NSNetService) {
        if (netService.addresses?.count ?? 0) != 0 {
            netService.delegate = nil
            self.test(netService)
            //self.addAddress(netService)
        } else {
            log(.Low, info: "no addresses found.")
        }
    }
    
    func netService(netService: NSNetService, didNotResolve errorDict: [String : NSNumber]) {
        netService.delegate = nil
        log(.High, error: "Could not resolve net service. (\(errorDict))")
    }
}
