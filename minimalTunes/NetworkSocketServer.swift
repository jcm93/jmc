//
//  NetworkSocketServer.swift
//  minimalTunes
//
//  Created by John Moody on 8/24/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Foundation


class SocketServer {
    let addr = "127.0.0.1"
    let port = 4000
    var host: NSHost = NSHost(address: "127.0.0.1")
    var inp: NSInputStream?
    var out: NSOutputStream?
    init() {
        NSStream.getStreamsToHost(host, port: port, inputStream: &inp, outputStream: &out)
        let inputStream = inp!
        let outputStream = out!
        inputStream.open()
        var readByte: UInt8 = 0
        while inputStream.hasBytesAvailable == true {
            inputStream.read(&readByte, maxLength: 1)
        }
        
    }
}