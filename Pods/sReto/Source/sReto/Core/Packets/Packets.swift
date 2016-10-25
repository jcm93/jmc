//
//  Packets.swift
//  sReto
//
//  Created by Julian Asamer on 13/07/14.
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
* The first four bytes of any packet contains it's type, represented as an integer. The different types are declared in this enum.
* See the packet's definitions below for more information about each type.
*/
enum PacketType: Int32 {
    case Unknown = 0
    
    // Routing Layer
    case LinkHandshake = 1
    case MulticastHandshake = 2
    case LinkState = 3
    case FloodPacket = 4
    case RoutedConnectionEstablishedConfirmation = 5
    
    // Connectivity
    case ManagedConnectionHandshake = 10
    case CloseRequest = 11
    case CloseAnnounce = 12
    case CloseAcknowledge = 13
    
    // Data transmission
    case TransferStarted = 20
    case DataPacket = 21
    case CancelledTransfer = 22
    case ProgressInformation = 23
}

/** 
* The Packet protocol requires packets to implement a serialize function.
* In general, packets offer a static deserialize method as well, this method is not part of this protocol.
*/
protocol Packet {
    func serialize() -> NSData
}
/** A helper class that does some generic data verification. */
class Packets {
    /**
    * Verifies that the data (wrapped in a DataReader) has the expected packet type, and has the minimum required lenght (i.e. number of bytes).
    * @param data The data to check
    * @param expectedType The type the packet is expected to have
    * @param minimumLength The minimum length required for the packet to be valid
    * @return Whether the conditions are met
    */
    class func check(data data: DataReader, expectedType: PacketType, minimumLength: Int) -> Bool {
        if !data.checkRemaining(minimumLength) {
            log(.High, error: "Could not parse, not enough data remaining (\(minimumLength) needed, \(data.remaining()) remaining).")
            return false
        }
        let type = data.getInteger()
        if type != expectedType.rawValue {
            log(.High, error: "Could not parse, invalid packet type: \(type)")
            return false
        }
        
        return true
    }
}

/**
* A ManagedConnectionHandshake is sent once a connection was established with another peer.
* It contains the connections unique identifier, which is used to decide whether the new underlying connection should be used 
* with an existing connection (e.g. in the case of a reconnect), or if a new Connection should be created.
*/
struct ManagedConnectionHandshake: Packet {
    static var type: PacketType {
        return PacketType.ManagedConnectionHandshake
    }
    static var length: Int {
        return sizeof(Int32) + sizeof(UUID)
    }
    
    let connectionIdentifier: UUID
    
    static func deserialize(data: DataReader) -> ManagedConnectionHandshake? {
        if !Packets.check(data: data, expectedType: type, minimumLength: length) {
            return nil
        }
        return ManagedConnectionHandshake(connectionIdentifier: data.getUUID())
    }
    
    func serialize() -> NSData {
        let data = DataWriter(length: self.dynamicType.length)
        data.add(self.dynamicType.type.rawValue)
        data.add(self.connectionIdentifier)
        return data.getData()
    }
}

/**
* A CloseRequest is sent to the Connection establisher if the destination of the Connection attempts to close it.
* The establisher is expected to respond with a CloseAnnounce packet.
*/
struct CloseRequest: Packet {
    static var type: PacketType { get { return PacketType.CloseRequest } }
    static var length: Int { get { return sizeof(Int32) } }
    
    static func deserialize(data: DataReader) -> CloseRequest? {
        if !Packets.check(data: data, expectedType: type, minimumLength: length) { return nil }
        return CloseRequest()
    }
    
    func serialize() -> NSData {
        let data = DataWriter(length: self.dynamicType.length)
        data.add(self.dynamicType.type.rawValue)
        return data.getData()
    }
}
/**
* Announces that a connection will close. Sent by the Connection establisher.
*/
struct CloseAnnounce: Packet {
    static var type: PacketType { get { return PacketType.CloseAnnounce } }
    static var length: Int { get { return sizeof(Int32) } }
    
    static func deserialize(data: DataReader) -> CloseAnnounce? {
        if !Packets.check(data: data, expectedType: type, minimumLength: length) { return nil }
        return CloseAnnounce()
    }
    
    func serialize() -> NSData {
        let data = DataWriter(length: self.dynamicType.length)
        data.add(self.dynamicType.type.rawValue)
        return data.getData()
    }
}
/** 
* Acknowledges that a Connection is about to close. Sent by all destinations of a Connection.
* Once the establisher has received all acknowledgements (if the Connection is not a multicast connection, it is only one acknowledgement),
* the underlying connection is closed.
*/
struct CloseAcknowledge: Packet {
    static var type: PacketType { get { return PacketType.CloseAcknowledge } }
    static var length: Int { get { return sizeof(Int32) } }
    
    let source: UUID
    
    static func deserialize(data: DataReader) -> CloseAcknowledge? {
        if !Packets.check(data: data, expectedType: type, minimumLength: length) { return nil }
        return CloseAcknowledge(source: data.getUUID())
    }
    
    func serialize() -> NSData {
        let data = DataWriter(length: self.dynamicType.length)
        data.add(self.dynamicType.type.rawValue)
        data.add(source)
        return data.getData()
    }
}

/**
* Sent when a transfer was cancelled by the sender of a data transfer, or sent when the cancellation of a transfer is requested by the receiver of the data transfer.
*/
struct CancelledTransferPacket: Packet {
    static var type: PacketType { get { return PacketType.CancelledTransfer } }
    static var length: Int { get { return sizeof(Int32) + sizeof(UUID) } }
    
    let transferIdentifier: UUID
    
    static func deserialize(data: DataReader) -> CancelledTransferPacket? {
        if !Packets.check(data: data, expectedType: type, minimumLength: length) { return nil }
        return CancelledTransferPacket(transferIdentifier: data.getUUID())
    }
    
    func serialize() -> NSData {
        let data = DataWriter(length: self.dynamicType.length)
        data.add(self.dynamicType.type.rawValue)
        data.add(self.transferIdentifier)
        return data.getData()
    }
}

/**
* A DataPacket sends the payload data of a transfer.
*/
struct DataPacket: Packet {
    static var type: PacketType { get { return PacketType.DataPacket } }
    static var minimumLength: Int { get { return sizeof(Int32) } }
    
    let data: NSData
    
    static func deserialize(data: DataReader) -> DataPacket? {
        if !Packets.check(data: data, expectedType: type, minimumLength: minimumLength) { return nil }
        return DataPacket(data: data.getData())
    }
    
    func serialize() -> NSData {
        let data = DataWriter(length: self.dynamicType.minimumLength + self.data.length)
        data.add(self.dynamicType.type.rawValue)
        data.add(self.data)
        return data.getData()
    }
}

/** 
* This packet is sent when a transfer was interrupted and can be resumed to ensure that any data that went missing is resent.
*/
struct ProgressInformation {
    static var minimumLength: Int { get { return sizeof(UUID) + sizeof(Int32) } }
    let transferIdentifier: UUID
    let progress: Int32
}

struct ProgressInformationPacket: Packet {
    static var type: PacketType { get { return PacketType.ProgressInformation } }
    static var minimumLength: Int { get { return sizeof(Int32) } }
    
    let information: [ProgressInformation]
    
    static func deserialize(data: DataReader) -> ProgressInformationPacket? {
        if !Packets.check(data: data, expectedType: type, minimumLength: minimumLength) { return nil }
        
        return ProgressInformationPacket(
            information: Array(0..<data.getInteger()).map {
                _ in ProgressInformation(transferIdentifier: data.getUUID(), progress: data.getInteger())
            }
        )
    }
    
    func serialize() -> NSData {
        let data = DataWriter(length: self.dynamicType.minimumLength + ProgressInformation.minimumLength * self.information.count)
        data.add(self.dynamicType.type.rawValue)
        data.add(Int32(self.information.count))
        
        for progressInfo in self.information {
            data.add(progressInfo.transferIdentifier)
            data.add(progressInfo.progress)
        }
        
        return data.getData()
    }
}

/**
* Sent when a new transfer is started.
*/
struct StartedTransferPacket: Packet {
    static var type: PacketType { get { return PacketType.TransferStarted } }
    static var minimumLength: Int { get { return sizeof(Int32)*2 + sizeof(UUID) } }
    
    let transferIdentifier: UUID
    let transferLength: Int32
    
    static func deserialize(data: DataReader) -> StartedTransferPacket? {
        if !Packets.check(data: data, expectedType: type, minimumLength: minimumLength) { return nil }
        return StartedTransferPacket(transferIdentifier: data.getUUID(), transferLength: data.getInteger())
    }
    
    func serialize() -> NSData {
        let data = DataWriter(length: self.dynamicType.minimumLength)
        data.add(self.dynamicType.type.rawValue)
        data.add(self.transferIdentifier)
        data.add(self.transferLength)
        return data.getData()
    }
}