//
//  Data.swift
//  sReto
//
//  Created by Julian Asamer on 10/07/14.
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

/**
* Read primitive types from NSData.
* 
* Manages a position internally so that no position needs to be specified when reading data.
*/
public class DataReader {
    private let data : NSData
    public private(set) var position : Int
    
    /** Constructs a DataReader from an NSData object. */
    public init(_ data : NSData) {
        self.data = data
        self.position = 0
    }
    
    /**
    * Checks whether more than length bytes can still be read.
    * @param length The number of bytes to check
    * @return true if more than or equal to length bytes can still be read.
    */
    public func checkRemaining(length : Int) -> Bool {
        return self.position + length <= self.data.length
    }
    /**
    * The number of remaining bytes to be read.
    */
    public func remaining() -> Int {
        return self.data.length - self.position
    }
    /**
    * Asserts that a certain number of bytes can still be read.
    */
    public func assertRemaining(length : Int) {
        assert(checkRemaining(length), "There is not enough data left to read.")
    }
    /**
    * Resets the position to zero.
    */
    public func rewind() {
        self.position = 0
    }
    /**
    * Returns a given number of bytes as an NSData object.
    * @param length The length of the data that should be returned in bytes.
    * @return An NSData object with the specified length.
    */
    func getData(length : Int) -> NSData {
        self.assertRemaining(length)
        
        let data = self.data.subdataWithRange(NSMakeRange(position, length))
        self.position += length
        return data
    }
    /**
    * Returns all remaining data.
    */
    public func getData() -> NSData {
        return self.getData(self.data.length - self.position)
    }
    /**
    * Returns the next byte.
    */
    public func getByte() -> UInt8 {
        var value : UInt8 = 0
        self.getAndAdvance(&value, length: sizeof(UInt8))
        return value
    }
    /** 
    * Returns the next 4 byte integer.
    */
    public func getInteger() -> Int32 {
        var value : Int32 = 0
        self.getAndAdvance(&value, length: sizeof(Int32))
        return value
    }
    /**
    * Returns the next 8 byte long.
    */
    public func getLong() -> Int64 {
        var value : Int64 = 0
        self.getAndAdvance(&value, length: sizeof(Int64))
        return value
    }
    /**
    * Reads an UUID.
    */
    public func getUUID() -> UUID {
        var uuid: [UInt8] = Array(count: 16, repeatedValue: 0)
        
        for part in 1...2 { for byte in 1...8 { uuid[part*8-byte] = self.getByte() } }
        
        return UUID(uuid: uuid)
    }
    /**
    * Reads an NSUUID.
    */
    public func getNSUUID() -> NSUUID {
        var uuid = getUUID().uuidt
        return withUnsafePointer(&uuid.0, {pointer in NSUUID(UUIDBytes: pointer)})
    }
    /** Reads data and advances the position. */
    private func getAndAdvance(value : UnsafeMutablePointer<()>, length : Int) {
        self.assertRemaining(length)
        self.data.getBytes(value, range: NSMakeRange(self.position, length))
        position += length
    }
}

/** Write primitive types to NSData */
public class DataWriter {
    let data: NSMutableData
    
    /** Constructs a data writer with a given length. */
    public init(length: Int) {
        self.data = NSMutableData(capacity: length)!
    }
    
    /** Returns all data that was written. */
    public func getData() -> NSData {
        return self.data
    }
    /** Appends an NSData object. */
    public func add(data: NSData) {
        self.data.appendData(data)
    }
    /** Appends a byte */
    public func add(byte: UInt8) {
        var value = byte
        self.data.appendBytes(&value, length: sizeof(Int8))
    }
    /** Appends a 4 byte integer */
    public func add(integer: Int32) {
        var value = integer
        self.data.appendBytes(&value, length: sizeof(Int32))
    }
    /** Appends a 8 byte long */
    public func add(long: Int64) {
        var value = long
        self.data.appendBytes(&value, length: sizeof(Int64))
    }
    /** Appends an UUID */
    public func add(uuid: UUID) {
        for part in 1...2 {
            for byte in 1...8 {
                self.add(uuid.uuid[part*8-byte])
            }
        }
    }
    /** Appends an NSUUID */
    public func add(nsuuid: NSUUID) {
        var uuid: uuid_t = UUID_T_ZERO
        withUnsafeMutablePointer(&uuid.0, { pointer in nsuuid.getUUIDBytes(pointer)})
        self.add(fromUUID_T(uuid))
    }
}