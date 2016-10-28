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
    let delegate: AppDelegate
    let interface: DragAndDropTreeController
    let namePeerDictionary = NSMutableDictionary()
    var isStreaming = false
    var isPlayingBackStream = false
    
    var streamingData = NSMutableData()
    
    init(_delegate: AppDelegate) {
        self.delegate = _delegate
        self.interface = delegate.mainWindowController!.sourceListTreeController!
        self.wlanModule = WlanModule(type: "metunes", dispatchQueue: dispatch_get_main_queue())
        self.remoteModule = RemoteP2PModule(baseUrl: NSURL(string: "ws://162.243.26.172:8080/")!, dispatchQueue: dispatch_get_main_queue())
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
    
    func AddTracksForPlaylistData(playlistDictionary: NSDictionary) {
        //get tracks
        let tracks = playlistDictionary["playlist"] as! [NSDictionary]
        var addedArtists = NSMutableDictionary()
        var addedAlbums = NSMutableDictionary()
        var addedComposers = NSMutableDictionary()
        var addedGenres = NSMutableDictionary()
        for track in tracks {
            let newTrack = NSEntityDescription.insertNewObjectForEntityForName("Track", inManagedObjectContext: managedContext) as! Track
            newTrack.is_network = true
            for field in track.allKeys as! [String] {
                switch field {
                case "is_enabled":
                    newTrack.status = track["is_enabled"] as? Bool
                case "name":
                    newTrack.name = track["name"] as? String
                case "time":
                    newTrack.time = track["time"] as? NSNumber
                case "artist":
                    let artist = checkIfArtistExists(track["artist"])
                    
                case "album":
                    dict["album"] = self.album?.name
                case "date_added":
                    dict["date_added"] = self.date_added
                case "date_modified":
                    dict["date_modified"] = self.date_modified
                case "date_released":
                    dict["date_released"] = self.album?.release_date
                case "comments":
                    dict["comments"] = self.comments
                case "composer":
                    dict["composer"] = self.composer?.name
                case "disc_number":
                    dict["disc_number"] = self.disc_number
                case "equalizer_preset":
                    dict["equalizer_preset"] = self.equalizer_preset
                case "genre":
                    dict["genre"] = self.genre?.name
                case "kind":
                    dict["kind"] = self.file_kind
                case "date_last_played":
                    dict["date_last_played"] = self.date_last_played
                case "date_last_skipped":
                    dict["date_last_skipped"] = self.date_last_skipped
                case "movement_name":
                    dict["movement_name"] = self.movement_name
                case "movement_number":
                    dict["movement_number"] = self.movement_number
                case "play_count":
                    dict["play_count"] = self.play_count
                case "rating":
                    dict["rating"] = self.rating
                case "bit_rate":
                    dict["bit_rate"] = self.bit_rate
                case "sample_rate":
                    dict["sample_rate"] = self.sample_rate
                case "size":
                    dict["size"] = self.size
                case "skip_count":
                    dict["skip_count"] = self.skip_count
                case "sort_album":
                    dict["sort_album"] = self.sort_album
                case "sort_album_artist":
                    dict["sort_album_artist"] = self.sort_album_artist
                case "sort_artist":
                    dict["sort_artist"] = self.sort_artist
                case "sort_composer":
                    dict["sort_composer"] = self.sort_composer
                case "sort_name":
                    dict["sort_name"] = self.sort_name
                case "track_number":
                    dict["track_number"] = self.track_num
                default:
                    break
                }
            }
        }
        
    }
    
    func onPeerDiscovered(peer: RemotePeer) {
        let connection = peer.connect()
        connection.onClose = { connection in print("Connection closed.") }
        connection.onError = { error in print("error: \(error)") }
        connection.onData = { data in print("Received data!") }
        connection.onConnect = { connection in
            print("successfully connected")
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
    
    func startStreaming(peer: RemotePeer, connection: Connection) {
        connection.onTransfer = { connection, transfer in
            transfer.onPartialData = { transfer, data in
                self.streamingData.appendData(data)
                if self.isPlayingBackStream == false {
                    let newTrack = NSEntityDescription.insertNewObjectForEntityForName("Track", inManagedObjectContext: managedContext) as! Track
                    let fuck = (NSApplication.sharedApplication().delegate as? AppDelegate)!.mainWindowController!
                    let fuck2 = fuck.queue
                    newTrack.name = (fuck.networkPlaylistArrayController.selectedObjects[0] as! NetworkTrack).name
                    print(newTrack.location)
                    self.isPlayingBackStream = true
                }
            }
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
    
    func getDataForPlaylist(item: SourceListItem) {
        let libraryName = item.library?.name
        let peerDict = namePeerDictionary[libraryName!] as! NSMutableDictionary
        let peer = peerDict["peer"] as! RemotePeer
        let connection = peer.connect()
        connection.onConnect = { connection in
            self.onIncomingConnection(peer, connection: connection)
        }
        let visibleColumns = NSUserDefaults.standardUserDefaults().objectForKey(DEFAULTS_SAVED_COLUMNS_STRING) as! NSDictionary
        let visibleColumnsArray = visibleColumns.allKeysForObject(true) as! [String]
        let id = item.playlist!.id! as Int
        askPeerForPlaylist(peer, connection: connection, id: id, visibleColumns: visibleColumnsArray)
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
                guard delegate.mainWindowController?.is_streaming == true else {return}
                let trackB64 = requestDict["track"] as! String
                let trackData = NSData(base64EncodedString: trackB64, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                guard trackData != nil else {return}
                let fileManager = NSFileManager.defaultManager()
                let libraryPath = NSUserDefaults.standardUserDefaults().stringForKey("libraryPath")
                let libraryURL = NSURL(fileURLWithPath: libraryPath!)
                let trackFilePath = libraryURL.URLByAppendingPathComponent("test.mp3").path
                fileManager.createFileAtPath(trackFilePath!, contents: trackData, attributes: nil)
                delegate.mainWindowController!.playNetworkSong()
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
                let visibleColumnsArray = requestDict["fields"] as! [String]
                sendPeerPlaylistInfo(peer, connection: connection, playlistID: playlistID, visibleColumns: visibleColumnsArray)
            case "track":
                let id = requestDict["id"] as! Int
                sendPeerTrack(peer, connection: connection, trackID: id)
        default:
            print("the tingler detects an invalid request")
        }
        
    }
    
    func sendPeerPlaylistInfo(peer: RemotePeer, connection: Connection, playlistID: Int, visibleColumns: [String]) {
        let playlist = metadataDelegate.getPlaylist(playlistID, fields: visibleColumns)
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
            print("error asking for library name: \(error)")
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
            print("error asking for source list: \(error)")
        }
    }
    
    func askPeerForPlaylist(peer: RemotePeer, connection: Connection, id: Int, visibleColumns: [String]) {
        let requestDictionary = NSMutableDictionary()
        requestDictionary["type"] = "request"
        requestDictionary["request"] = "playlist"
        requestDictionary["fields"] = visibleColumns
        requestDictionary["id"] = id
        var data: NSData!
        do {
            data = try NSJSONSerialization.dataWithJSONObject(requestDictionary, options: NSJSONWritingOptions.PrettyPrinted)
            connection.send(data: data)
        } catch {
            print("error asking for playlist: \(error)")
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
            print("error asking for song: \(error)")
        }
    }
}