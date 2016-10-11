//
//  MaybeTheLastServerAttempt.swift
//  minimalTunes
//
//  Created by John Moody on 10/2/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import sReto

class P2PServer {
    let metadataDelegate = SharedLibraryRequestHandler()
    let wlanModule: WlanModule
    let remoteModule: RemoteP2PModule
    let localPeer: LocalPeer
    let interface: DragAndDropTreeController
    let namePeerDictionary = NSMutableDictionary()
    
    init(_interface: DragAndDropTreeController) {
        interface = _interface
        self.wlanModule = WlanModule(type: "thisisstupidandiuseitforauthenticationandimmetunes", dispatchQueue: dispatch_get_main_queue())
        self.remoteModule = RemoteP2PModule(baseUrl: NSURL(string: "http://moodyonline.com")!, dispatchQueue: dispatch_get_main_queue())
        self.localPeer = LocalPeer(modules: [self.wlanModule], dispatchQueue: dispatch_get_main_queue())
        self.localPeer.start(
            onPeerDiscovered: { peer in
                print("discovered peer")
                self.onPeerDiscovered(peer)
            },
            onPeerRemoved: { peer in print("Removed peer: \(peer)") },
            onIncomingConnection: { peer, connection in
                print("Received incoming connection: \(connection) from peer: \(peer)")
                self.onIncomingConnection(peer, connection: connection)
            },
            displayName: "MyLocalPeer"
        )
    }
    
    func onPeerDiscovered(peer: RemotePeer) {
        let connection = peer.connect()
        connection.onConnect = { connection in
            self.onIncomingConnection(peer, connection: connection)
            self.askPeerForLibraryName(peer, connection: connection)
        }
    }
    
    func onPeerRemoved(peer: RemotePeer) {
        interface.removeNetworkedLibrary(peer.name!)
    }
    
    func onIncomingConnection(peer: RemotePeer, connection: Connection) {
        connection.onTransfer = { connection, transfer in
            transfer.onProgress = {transfer in print("current progress: \(transfer.progress) of \(transfer.length)") }
            transfer.onCompleteData = {transfer, data in self.parseTransfer(peer, connection: connection, transfer: transfer, data: data) }
        }
    }
    
    func parseTransfer(peer: RemotePeer, connection: Connection, transfer: Transfer, data: NSData) {
        var requestDict: NSDictionary!
        do {
            requestDict = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
        } catch {
            print(error)
        }
        let dataType = requestDict["type"] as! String
        switch dataType {
        case "request":
            parseRequest(peer, connection: connection, transfer: transfer, requestDict: requestDict)
        case "payload":
            parsePayload(peer, connection: connection, transfer: transfer, requestDict: requestDict)
        default:
            print("the tingler detects an invalid transfer")
        }
    }
    
    func getTrack(id: Int, libraryName: String) {
        let peerDict = namePeerDictionary[libraryName] as! NSMutableDictionary
        let peer = peerDict["peer"] as! RemotePeer
        let connection = peer.connect()
        connection.onConnect = { connection in
            self.onIncomingConnection(peer, connection: connection)
        }
        askPeerForSong(peer, connection: connection, id: id)
        
    }
    
    func addSongsForPlaylist(item: SourceListItem, libraryName: String) {
        let peerDict = namePeerDictionary[libraryName] as! NSMutableDictionary
        let peer = peerDict["peer"] as! RemotePeer
        let connection = peer.connect()
        connection.onConnect = { connection in
            self.onIncomingConnection(peer, connection: connection)
        }
        let id = item.playlist!.id! as Int
        askPeerForPlaylist(peer, connection: connection, id: id)
        
    }
    
    func parsePayload(peer: RemotePeer, connection: Connection, transfer: Transfer, requestDict: NSDictionary) {
        let payloadType = requestDict["payload"] as! String
        switch payloadType {
            case "name":
                let name = requestDict["name"] as! String
                interface.addNetworkedLibrary(name, address: "poophole")
                let connectionDictionary = NSMutableDictionary()
                connectionDictionary["peer"] = peer
                self.namePeerDictionary[name] = connectionDictionary
                self.askPeerForSourceList(peer, connection: connection)
            case "list":
                let name = requestDict["name"] as! String
                let networkedLibrary = interface.networkedLibraryWithName(name)
                let list = requestDict["list"] as! [NSDictionary]
                interface.addSourcesForNetworkedLibrary(list, item: networkedLibrary!)
            case "playlist":
                let id = requestDict["id"] as! Int
                let item = interface.getNetworkPlaylistWithID(id)
                let songs = requestDict["playlist"] as! [NSDictionary]
                interface.addSongsToNetworkedLibrary(item, songs: songs)
                print("the tingler got a playlist")
            case "track":
                let trackPayloadString = requestDict["track"] as! String
                let trackPayloadData = NSData.init(base64EncodedString: trackPayloadString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                let path = NSUserDefaults.standardUserDefaults().stringForKey("libraryPath")! + "/test.mp3"
                print(path)
                NSFileManager.defaultManager().createFileAtPath(path, contents: trackPayloadData, attributes: nil)
                let newTrack = NSEntityDescription.insertNewObjectForEntityForName("Track", inManagedObjectContext: managedContext) as! Track
                let fuck = (NSApplication.sharedApplication().delegate as? AppDelegate)!.mainWindowController!
                newTrack.name = (fuck.networkPlaylistArrayController.selectedObjects[0] as! NetworkTrack).name
                newTrack.location = NSURL(fileURLWithPath: path).absoluteString
                print(newTrack.location)
                fuck.playSong(newTrack)
                print("the tingler got a song")
        default:
            print("the tingler got an invalid payload")
        }
    }
    
    func parseRequest(peer: RemotePeer, connection: Connection, transfer: Transfer, requestDict: NSDictionary) {
        guard (requestDict["type"] as! String) == "request" else {return}
        let request = requestDict["request"] as! String
        switch request {
            case "name":
                sendPeerLibraryName(peer, connection: connection)
            case "list":
                sendPeerSourceList(peer, connection: connection)
            case "playlist":
                let playlistID = requestDict["id"] as! Int
                sendPeerPlaylistInfo(peer, connection: connection, playlistID: playlistID)
            case "track":
                let id = requestDict["id"] as! Int
                sendPeerTrack(peer, connection: connection, trackID: id)
        default:
            print("the tingler detects an invalid request")
        }
        
    }
    
    func sendPeerPlaylistInfo(peer: RemotePeer, connection: Connection, playlistID: Int) {
        let playlist = metadataDelegate.getPlaylist(playlistID)
        let playlistPayloadDictionary = NSMutableDictionary()
        playlistPayloadDictionary["type"] = "payload"
        playlistPayloadDictionary["payload"] = "playlist"
        playlistPayloadDictionary["id"] = playlistID
        playlistPayloadDictionary["playlist"] = playlist
        var serializedDict: NSData!
        do {
            serializedDict = try NSJSONSerialization.dataWithJSONObject(playlistPayloadDictionary, options: NSJSONWritingOptions.PrettyPrinted)
        } catch {
            print(error)
        }
        connection.send(serializedDict)
    }
    
    func sendPeerTrack(peer: RemotePeer, connection: Connection, trackID: Int) {
        let trackData = metadataDelegate.getSong(trackID)
        let trackPayloadDictionary = NSMutableDictionary()
        trackPayloadDictionary["type"] = "payload"
        trackPayloadDictionary["payload"] = "track"
        trackPayloadDictionary["track"] = trackData?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
        var serializedDict: NSData!
        do {
            serializedDict = try NSJSONSerialization.dataWithJSONObject(trackPayloadDictionary, options: NSJSONWritingOptions.PrettyPrinted)
        } catch {
            print(error)
        }
        connection.send(serializedDict)
    }
    
    func sendPeerLibraryName(peer: RemotePeer, connection: Connection) {
        let libraryName = NSUserDefaults.standardUserDefaults().stringForKey("libraryName")
        let libraryNameDictionary = NSMutableDictionary()
        libraryNameDictionary["type"] = "payload"
        libraryNameDictionary["payload"] = "name"
        libraryNameDictionary["name"] = libraryName
        var serializedDict: NSData!
        do {
            serializedDict = try NSJSONSerialization.dataWithJSONObject(libraryNameDictionary, options: NSJSONWritingOptions.PrettyPrinted)
        } catch {
            print(error)
        }
        connection.send(serializedDict)
    }
    
    func sendPeerSourceList(peer: RemotePeer, connection: Connection) {
        let sourceList = metadataDelegate.getSourceList()
        let sourceListPayloadDictionary = NSMutableDictionary()
        sourceListPayloadDictionary["name"] = NSUserDefaults.standardUserDefaults().stringForKey("libraryName")
        sourceListPayloadDictionary["type"] = "payload"
        sourceListPayloadDictionary["payload"] = "list"
        sourceListPayloadDictionary["list"] = sourceList
        var serializedDict: NSData!
        do {
            serializedDict = try NSJSONSerialization.dataWithJSONObject(sourceListPayloadDictionary, options: NSJSONWritingOptions.PrettyPrinted)
        } catch {
            print(error)
        }
        connection.send(serializedDict)
    }
    
    func askPeerForLibraryName(peer: RemotePeer, connection: Connection) {
        let requestDictionary = NSMutableDictionary()
        requestDictionary["type"] = "request"
        requestDictionary["request"] = "name"
        var data: NSData!
        do {
            data = try NSJSONSerialization.dataWithJSONObject(requestDictionary, options: NSJSONWritingOptions.PrettyPrinted)
            connection.send(data: data)
        } catch {
            print(error)
        }
    }
    
    func askPeerForSourceList(peer: RemotePeer, connection: Connection) {
        let requestDictionary = NSMutableDictionary()
        requestDictionary["type"] = "request"
        requestDictionary["request"] = "list"
        var data: NSData!
        do {
            data = try NSJSONSerialization.dataWithJSONObject(requestDictionary, options: NSJSONWritingOptions.PrettyPrinted)
            connection.send(data: data)
        } catch {
            print(error)
        }
    }
    
    func askPeerForPlaylist(peer: RemotePeer, connection: Connection, id: Int) {
        let requestDictionary = NSMutableDictionary()
        requestDictionary["type"] = "request"
        requestDictionary["request"] = "playlist"
        requestDictionary["id"] = id
        var data: NSData!
        do {
            data = try NSJSONSerialization.dataWithJSONObject(requestDictionary, options: NSJSONWritingOptions.PrettyPrinted)
            connection.send(data: data)
        } catch {
            print(error)
        }
    }
    
    func askPeerForSong(peer: RemotePeer, connection: Connection, id: Int) {
        let requestDictionary = NSMutableDictionary()
        requestDictionary["type"] = "request"
        requestDictionary["request"] = "track"
        requestDictionary["id"] = id
        var data: NSData!
        do {
            data = try NSJSONSerialization.dataWithJSONObject(requestDictionary, options: NSJSONWritingOptions.PrettyPrinted)
            connection.send(data: data)
        } catch {
            print(error)
        }
    }
}