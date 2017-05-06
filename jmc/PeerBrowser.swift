//
//  PeerBrowser.swift
//  minimalTunes
//
//  Created by John Moody on 12/15/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
import MultipeerConnectivity

class ConnectivityManager: NSObject, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate {
    
    let serviceIdentifier = "jmc"
    let thisPeerID = MCPeerID(displayName: Host.current().localizedName!)
    let serviceAdvertiser: MCNearbyServiceAdvertiser
    let serviceBrowser: MCNearbyServiceBrowser
    let interface: SourceListViewController?
    let metadataDelegate: SharedLibraryRequestHandler?
    let databaseManager: DatabaseManager
    var requestedTrackDatas = [Int : Track]()
    
    var delegate: AppDelegate?
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.thisPeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        session.delegate = self
        return session
    }()
    
    init(delegate: AppDelegate, slvc: SourceListViewController) {
        self.interface = slvc
        self.delegate = delegate
        self.databaseManager = DatabaseManager()
        self.metadataDelegate = SharedLibraryRequestHandler()
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: thisPeerID, discoveryInfo: nil, serviceType: serviceIdentifier)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: thisPeerID, serviceType: serviceIdentifier)
        super.init()
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
        slvc.server = self
        print("server started")
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    //mark advertiser
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print(error)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("got invitation from \(peerID)")
        invitationHandler(true, self.session)
    }
    
    //mark browser
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lost peer: \(peerID)")
        //interface!.removeNetworkedLibrary(peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("error starting browsering: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("found peer: \(peerID) with info \(info)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    //mark session
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("received data from peer \(peerID)")
        var requestDict: NSDictionary!
        do {
            requestDict = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
        } catch {
            print(error)
        }
        let dataType = requestDict["type"] as! String
        switch dataType {
        case "request":
            print("data was a request")
            parseRequest(peerID, requestDict: requestDict)
        case "payload":
            parsePayload(peerID, requestDict: requestDict)
        default:
            print("the tingler detects an invalid transfer")
        }
    }
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) session \(session) changed state to \(state.rawValue)")
        if state == MCSessionState.connected {
            sendPeerLibraryName(peerID)
        } else if state == MCSessionState.notConnected {
            DispatchQueue.main.async {
                self.interface?.removeNetworkedLibrary(peerID)
            }
            serviceBrowser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
        }
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("got \(stream) with name \(streamName) from peer \(peerID)")
    }
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        print("got a certificate \(certificate) from \(peerID)")
        certificateHandler(true)
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("started getting resource \(resourceName) from peer \(peerID) with progress \(progress)")
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        print("finished getting resource \(resourceName) from peer \(peerID) at url \(localURL) with error \(error)")
    }
    
    func getTrack(_ id: Int, peer: MCPeerID) {
        askPeerForSong(peer, id: id)
    }
    
    func getDataForPlaylist(_ item: SourceListItem) {
        print("about to ask peer for playlist")
        let peer = item.library!.peer as! MCPeerID
        let visibleColumns = UserDefaults.standard.object(forKey: DEFAULTS_SAVED_COLUMNS_STRING) as! NSDictionary
        let visibleColumnsArray = visibleColumns.allKeys(for: false) as! [String]
        let id = item.playlist!.id! as Int
        askPeerForPlaylist(peer, id: id, visibleColumns: visibleColumnsArray)
    }
    
    func parsePayload(_ peer: MCPeerID, requestDict: NSDictionary) {
        let payloadType = requestDict["payload"] as! String
        switch payloadType {
        case "name":
            DispatchQueue.main.async {
                self.interface!.addNetworkedLibrary(peer)
            }
            self.askPeerForSourceList(peer)
        case "list":
            let list = requestDict["list"] as! [NSDictionary]
            DispatchQueue.main.async {
                self.interface!.addSourcesForNetworkedLibrary(list, peer: peer)
            }
        case "playlist":
            let requestedID = requestDict["id"] as! Int
            let item = interface!.getNetworkPlaylist(requestedID)
            let playlist = requestDict["playlist"] as? NSDictionary
            DispatchQueue.main.async {
                if playlist != nil {
                    self.databaseManager.addTracksForPlaylistData(playlist!, item: item!)
                    self.interface!.doneAddingNetworkPlaylistCallback(item!)
                }
            }
            print("the tingler got a playlist")
        case "track":
            guard delegate!.mainWindowController?.is_streaming == true else {return}
            let trackB64 = requestDict["track"] as! String
            let trackData = Data(base64Encoded: trackB64, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)
            guard trackData != nil else {return}
            databaseManager.saveStreamingNetworkTrack(delegate!.mainWindowController!.currentTrack!, data: trackData!)
            DispatchQueue.main.async {
                self.delegate!.mainWindowController!.playNetworkSongCallback()
            }
            print("the tingler got a song")
        case "track download":
            guard let track = (self.requestedTrackDatas[requestDict["id"] as! Int]) else {return}
            self.requestedTrackDatas.removeValue(forKey: requestDict["id"] as! Int)
            let trackB64 = requestDict["track"] as! String
            guard let trackData = Data(base64Encoded: trackB64, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) else {return}
            guard let trackMetadata = requestDict["metadata"] as? NSDictionary else {return}
            let databaseManager = DatabaseManager()
            DispatchQueue.main.async {
                databaseManager.createFileForNetworkTrack(track, data: trackData, trackMetadata: trackMetadata)
            }
            print("the tingler got a song download")
        default:
            print("the tingler got an invalid payload")
        }
    }
    
    func parseRequest(_ peer: MCPeerID, requestDict: NSDictionary) {
        guard (requestDict["type"] as! String) == "request" else {return}
        let request = requestDict["request"] as! String
        switch request {
        case "name":
            sendPeerLibraryName(peer)
        case "list":
            sendPeerSourceList(peer)
        case "playlist":
            print("got request for playlist")
            let playlistID = requestDict["id"] as! Int
            let visibleColumnsArray = requestDict["fields"] as! [String]
            sendPeerPlaylistInfo(peer, playlistID: playlistID, visibleColumns: visibleColumnsArray)
        case "track":
            let id = requestDict["id"] as! Int
            sendPeerTrack(peer, trackID: id)
        case "track download":
            let id = requestDict["id"] as! Int
            sendPeerTrackDownload(peer, trackID: id)
        default:
            print("the tingler detects an invalid request")
        }
    }
    
    func sendPeerPlaylistInfo(_ peer: MCPeerID, playlistID: Int, visibleColumns: [String]) {
        let playlist = metadataDelegate!.getPlaylist(playlistID, fields: visibleColumns)
        let playlistPayloadDictionary = NSMutableDictionary()
        playlistPayloadDictionary["type"] = "payload"
        playlistPayloadDictionary["payload"] = "playlist"
        playlistPayloadDictionary["library"] = globalRootLibrary?.name
        playlistPayloadDictionary["id"] = playlistID
        playlistPayloadDictionary["playlist"] = playlist
        var serializedDict: Data!
        do {
            serializedDict = try JSONSerialization.data(withJSONObject: playlistPayloadDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
            try self.session.send(serializedDict, toPeers: [peer], with: .reliable)
        } catch {
            print(error)
        }
    }
    
    func sendPeerTrack(_ peer: MCPeerID, trackID: Int) {
        let trackData = metadataDelegate!.getSong(trackID)
        let trackPayloadDictionary = NSMutableDictionary()
        trackPayloadDictionary["type"] = "payload"
        trackPayloadDictionary["payload"] = "track"
        trackPayloadDictionary["track"] = trackData?.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
        var serializedDict: Data!
        do {
            serializedDict = try JSONSerialization.data(withJSONObject: trackPayloadDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
            try session.send(serializedDict, toPeers: [peer], with: .reliable)
        } catch {
            print(error)
        }
    }
    
    func sendPeerTrackDownload(_ peer: MCPeerID, trackID: Int) {
        let trackData = metadataDelegate!.getSong(trackID)
        let trackPayloadDictionary = NSMutableDictionary()
        trackPayloadDictionary["type"] = "payload"
        trackPayloadDictionary["payload"] = "track download"
        trackPayloadDictionary["id"] = trackID
        trackPayloadDictionary["track"] = trackData?.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
        trackPayloadDictionary["metadata"] = metadataDelegate!.getAllMetadataForTrack(trackID)
        var serializedDict: Data!
        do {
            serializedDict = try JSONSerialization.data(withJSONObject: trackPayloadDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
            print("sending song")
            try session.send(serializedDict, toPeers: [peer], with: .reliable)
        } catch {
            print(error)
        }
    }
    
    func sendPeerLibraryName(_ peer: MCPeerID) {
        let libraryName = globalRootLibrary?.name
        let libraryNameDictionary = NSMutableDictionary()
        libraryNameDictionary["type"] = "payload"
        libraryNameDictionary["payload"] = "name"
        libraryNameDictionary["name"] = libraryName
        var serializedDict: Data!
        do {
            serializedDict = try JSONSerialization.data(withJSONObject: libraryNameDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
            try session.send(serializedDict, toPeers: [peer], with: .reliable)
        } catch {
            print(error)
        }
    }
    
    func sendPeerSourceList(_ peer: MCPeerID) {
        let sourceList = metadataDelegate!.getSourceList()
        let sourceListPayloadDictionary = NSMutableDictionary()
        sourceListPayloadDictionary["name"] = UserDefaults.standard.string(forKey: "libraryName")
        sourceListPayloadDictionary["type"] = "payload"
        sourceListPayloadDictionary["payload"] = "list"
        sourceListPayloadDictionary["list"] = sourceList
        var serializedDict: Data!
        do {
            serializedDict = try JSONSerialization.data(withJSONObject: sourceListPayloadDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
            try session.send(serializedDict, toPeers: [peer], with: .reliable)
        } catch {
            print(error)
        }
    }
    
    func askPeerForLibraryName(_ peer: MCPeerID) {
        let requestDictionary = NSMutableDictionary()
        requestDictionary["type"] = "request"
        requestDictionary["request"] = "name"
        var data: Data!
        do {
            data = try JSONSerialization.data(withJSONObject: requestDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            print("error asking for library name: \(error)")
        }
    }
    
    func askPeerForSourceList(_ peer: MCPeerID) {
        let requestDictionary = NSMutableDictionary()
        requestDictionary["type"] = "request"
        requestDictionary["request"] = "list"
        var data: Data!
        do {
            data = try JSONSerialization.data(withJSONObject: requestDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            print("error asking for source list: \(error)")
        }
    }
    
    func askPeerForPlaylist(_ peer: MCPeerID, id: Int, visibleColumns: [String]) {
        let requestDictionary = NSMutableDictionary()
        requestDictionary["type"] = "request"
        requestDictionary["request"] = "playlist"
        requestDictionary["fields"] = visibleColumns
        requestDictionary["id"] = id
        var data: Data!
        do {
            data = try JSONSerialization.data(withJSONObject: requestDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
            print("sending playlist request to peer")
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            print("error asking for playlist: \(error)")
        }
    }
    
    func askPeerForSong(_ peer: MCPeerID, id: Int) {
        let requestDictionary = NSMutableDictionary()
        requestDictionary["type"] = "request"
        requestDictionary["request"] = "track"
        requestDictionary["id"] = id
        var data: Data!
        do {
            data = try JSONSerialization.data(withJSONObject: requestDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
            try session.send(data, toPeers: [peer], with: MCSessionSendDataMode.reliable)
        } catch {
            print("error asking for song: \(error)")
        }
    }
    
    func askPeerForSongDownload(_ peer: MCPeerID, track: Track) {
        let requestDictionary = NSMutableDictionary()
        requestDictionary["type"] = "request"
        requestDictionary["request"] = "track download"
        requestDictionary["id"] = track.id!
        self.requestedTrackDatas[Int(track.id!)] = track
        var data: Data!
        do {
            data = try JSONSerialization.data(withJSONObject: requestDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
            try session.send(data, toPeers: [peer], with: MCSessionSendDataMode.reliable)
        } catch {
            print("error asking for song download: \(error)")
        }
        
    }
}
