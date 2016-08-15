
/*
 NSData+Compression.swift
 Created by Danilo Altheman on 17/06/15.
 The MIT License (MIT)
 Copyright © 2015 Quaddro - Danilo Altheman. All rights reserved.
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
import Compression

enum LZFSEAction: Int {
    case Compress
    case Decompress
}

/*extension NSData {
    class func compress(fileURL: NSURL, action: LZFSEAction) -> NSData {
        
        let data: NSData = NSData(contentsOfURL: fileURL)!
        
        let sourceBuffer: UnsafePointer<UInt8> = UnsafePointer<UInt8>(data.bytes)
        let sourceBufferSize: Int = data.length
        
        let destinationBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.alloc(sourceBufferSize)
        let destinationBufferSize: Int = sourceBufferSize
        
        var status: Int
        switch action {
        case .Compress:
            status = compression_encode_buffer(destinationBuffer, destinationBufferSize, sourceBuffer, sourceBufferSize, nil, COMPRESSION_LZFSE)
        default:
            status = compression_decode_buffer(destinationBuffer, destinationBufferSize, sourceBuffer, sourceBufferSize, nil, COMPRESSION_LZFSE)
        }
        
        if status == 0 {
            print("Error with status: \(status)")
        }
        print("Original size: \(sourceBufferSize) | Compressed size: \(status)")
        return NSData(bytesNoCopy: destinationBuffer, length: status)
    }
}*/