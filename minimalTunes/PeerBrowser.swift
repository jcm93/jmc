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
    
    let serviceIdentifier = "j-tunes"
    let thisPeerID = MCPeerID(displayName: NSHost.currentHost().localizedName!)
    let serviceAdvertiser: MCNearbyServiceAdvertiser
    let serviceBrowser: MCNearbyServiceBrowser
    let interface: SourceListViewController?
    let metadataDelegate: SharedLibraryRequestHandler?
    var requestedTrackDatas = [Int : Track]()
    
    var delegate: AppDelegate?
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.thisPeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.None)
        session.delegate = self
        return session
    }()
    
    init(delegate: AppDelegate, slvc: SourceListViewController) {
        self.interface = slvc
        self.delegate = delegate
        self.metadataDelegate = SharedLibraryRequestHandler()
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: thisPeerID, discoveryInfo: nil, serviceType: serviceIdentifier)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: thisPeerID, serviceType: serviceIdentifier)
        super.init()
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
        slvc.server = self
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    //mark advertiser
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        print(error)
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        print("got invitation from \(peerID)")
        invitationHandler(true, self.session)
    }
    
    //mark browser
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lost peer: \(peerID)")
        interface!.removeNetworkedLibrary(peerID)
    }
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print("error starting browsering: \(error)")
    }
    
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("found peer: \(peerID) with info \(info)")
        browser.invitePeer(peerID, toSession: self.session, withContext: nil, timeout: 10)
    }
    
    //mark session
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        print("received data from peer \(peerID)")
        var requestDict: NSDictionary!
        do {
            requestDict = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
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
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        print("peer \(peerID) session \(session) changed state to \(state.rawValue)")
        if state == MCSessionState.Connected {
            sendPeerLibraryName(peerID)
        }
    }
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("got \(stream) with name \(streamName) from peer \(peerID)")
    }
    func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
        print("got a certificate \(certificate) from \(peerID)")
        certificateHandler(true)
    }
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        print("started getting resource \(resourceName) from peer \(peerID) with progress \(progress)")
    }
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        print("finished getting resource \(resourceName) from peer \(peerID) at url \(localURL) with error \(error)")
    }
    
    func getTrack(id: Int, peer: MCPeerID) {
        askPeerForSong(peer, id: id)
    }
    
    func getDataForPlaylist(item: SourceListNode) {
        print("about to ask peer for playlist")
        let peer = item.item.library!.peer as! MCPeerID
        let visibleColumns = NSUserDefaults.standardUserDefaults().objectForKey(DEFAULTS_SAVED_COLUMNS_STRING) as! NSDictionary
        let visibleColumnsArray = visibleColumns.allKeysForObject(false) as! [String]
        let id = item.item.playlist!.id! as Int
        askPeerForPlaylist(peer, id: id, visibleColumns: visibleColumnsArray)
    }
    
    func parsePayload(peer: MCPeerID, requestDict: NSDictionary) {
        let payloadType = requestDict["payload"] as! String
        switch payloadType {
        case "name":
            dispatch_async(dispatch_get_main_queue()) {
                self.interface!.addNetworkedLibrary(peer)
            }
            self.askPeerForSourceList(peer)
        case "list":
            let list = requestDict["list"] as! [NSDictionary]
            dispatch_async(dispatch_get_main_queue()) {
                self.interface!.addSourcesForNetworkedLibrary(list, peer: peer)
            }
        case "playlist":
            let requestedID = requestDict["id"] as! Int
            let item = interface!.getNetworkPlaylist(requestedID)
            let playlist = requestDict["playlist"] as? NSDictionary
            dispatch_async(dispatch_get_main_queue()) {
                if playlist != nil {
                    self.addTracksForPlaylistData(playlist! , item: item!)
                }
            }
            print("the tingler got a playlist")
        case "track":
            guard delegate!.mainWindowController?.is_streaming == true else {return}
            let trackB64 = requestDict["track"] as! String
            let trackData = NSData(base64EncodedString: trackB64, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
            guard trackData != nil else {return}
            let fileManager = NSFileManager.defaultManager()
            let libraryPath = NSUserDefaults.standardUserDefaults().stringForKey(DEFAULTS_LIBRARY_PATH_STRING)
            let libraryURL = NSURL(fileURLWithPath: libraryPath!)
            let trackFilePath = libraryURL.URLByAppendingPathComponent("test.mp3").path
            fileManager.createFileAtPath(trackFilePath!, contents: trackData, attributes: nil)
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate!.mainWindowController!.playNetworkSongCallback()
            }
            print("the tingler got a song")
        case "track download":
            guard let track = (self.requestedTrackDatas[requestDict["id"] as! Int]) else {return}
            self.requestedTrackDatas.removeValueForKey(requestDict["id"] as! Int)
            let trackB64 = requestDict["track"] as! String
            guard let trackData = NSData(base64EncodedString: trackB64, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters) else {return}
            let fileHandler = YeOldeFileHandler()
            fileHandler.createFileForNetworkTrack(track, data: trackData)
            print("the tingler got a song download")
        default:
            print("the tingler got an invalid payload")
        }
    }
    
    func parseRequest(peer: MCPeerID, requestDict: NSDictionary) {
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
    
    func sendPeerPlaylistInfo(peer: MCPeerID, playlistID: Int, visibleColumns: [String]) {
        let playlist = metadataDelegate!.getPlaylist(playlistID, fields: visibleColumns)
        let playlistPayloadDictionary = NSMutableDictionary()
        playlistPayloadDictionary["type"] = "payload"
        playlistPayloadDictionary["payload"] = "playlist"
        playlistPayloadDictionary["library"] = NSUserDefaults.standardUserDefaults().stringForKey(DEFAULTS_LIBRARY_NAME_STRING)
        playlistPayloadDictionary["id"] = playlistID
        playlistPayloadDictionary["playlist"] = playlist
        var serializedDict: NSData!
        do {
            serializedDict = try NSJSONSerialization.dataWithJSONObject(playlistPayloadDictionary, options: NSJSONWritingOptions.PrettyPrinted)
            try self.session.sendData(serializedDict, toPeers: [peer], withMode: .Reliable)
        } catch {
            print(error)
        }
    }
    
    func sendPeerTrack(peer: MCPeerID, trackID: Int) {
        let trackData = metadataDelegate!.getSong(trackID)
        let trackPayloadDictionary = NSMutableDictionary()
        trackPayloadDictionary["type"] = "payload"
        trackPayloadDictionary["payload"] = "track"
        trackPayloadDictionary["track"] = trackData?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
        var serializedDict: NSData!
        do {
            serializedDict = try NSJSONSerialization.dataWithJSONObject(trackPayloadDictionary, options: NSJSONWritingOptions.PrettyPrinted)
            try session.sendData(serializedDict, toPeers: [peer], withMode: .Reliable)
        } catch {
            print(error)
        }
    }
    
    func sendPeerTrackDownload(peer: MCPeerID, trackID: Int) {
        let trackData = metadataDelegate!.getSong(trackID)
        let trackPayloadDictionary = NSMutableDictionary()
        trackPayloadDictionary["type"] = "payload"
        trackPayloadDictionary["payload"] = "track download"
        trackPayloadDictionary["id"] = trackID
        trackPayloadDictionary["track"] = trackData?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
        var serializedDict: NSData!
        do {
            serializedDict = try NSJSONSerialization.dataWithJSONObject(trackPayloadDictionary, options: NSJSONWritingOptions.PrettyPrinted)
            try session.sendData(serializedDict, toPeers: [peer], withMode: .Reliable)
        } catch {
            print(error)
        }
    }
    
    func sendPeerLibraryName(peer: MCPeerID) {
        let libraryName = NSUserDefaults.standardUserDefaults().stringForKey("libraryName")
        let libraryNameDictionary = NSMutableDictionary()
        libraryNameDictionary["type"] = "payload"
        libraryNameDictionary["payload"] = "name"
        libraryNameDictionary["name"] = libraryName
        var serializedDict: NSData!
        do {
            serializedDict = try NSJSONSerialization.dataWithJSONObject(libraryNameDictionary, options: NSJSONWritingOptions.PrettyPrinted)
            try session.sendData(serializedDict, toPeers: [peer], withMode: .Reliable)
        } catch {
            print(error)
        }
    }
    
    func sendPeerSourceList(peer: MCPeerID) {
        let sourceList = metadataDelegate!.getSourceList()
        let sourceListPayloadDictionary = NSMutableDictionary()
        sourceListPayloadDictionary["name"] = NSUserDefaults.standardUserDefaults().stringForKey("libraryName")
        sourceListPayloadDictionary["type"] = "payload"
        sourceListPayloadDictionary["payload"] = "list"
        sourceListPayloadDictionary["list"] = sourceList
        var serializedDict: NSData!
        do {
            serializedDict = try NSJSONSerialization.dataWithJSONObject(sourceListPayloadDictionary, options: NSJSONWritingOptions.PrettyPrinted)
            try session.sendData(serializedDict, toPeers: [peer], withMode: .Reliable)
        } catch {
            print(error)
        }
    }
    
    func askPeerForLibraryName(peer: MCPeerID) {
        let requestDictionary = NSMutableDictionary()
        requestDictionary["type"] = "request"
        requestDictionary["request"] = "name"
        var data: NSData!
        do {
            data = try NSJSONSerialization.dataWithJSONObject(requestDictionary, options: NSJSONWritingOptions.PrettyPrinted)
            try session.sendData(data, toPeers: [peer], withMode: .Reliable)
        } catch {
            print("error asking for library name: \(error)")
        }
    }
    
    func askPeerForSourceList(peer: MCPeerID) {
        let requestDictionary = NSMutableDictionary()
        requestDictionary["type"] = "request"
        requestDictionary["request"] = "list"
        var data: NSData!
        do {
            data = try NSJSONSerialization.dataWithJSONObject(requestDictionary, options: NSJSONWritingOptions.PrettyPrinted)
            try session.sendData(data, toPeers: [peer], withMode: .Reliable)
        } catch {
            print("error asking for source list: \(error)")
        }
    }
    
    func askPeerForPlaylist(peer: MCPeerID, id: Int, visibleColumns: [String]) {
        let requestDictionary = NSMutableDictionary()
        requestDictionary["type"] = "request"
        requestDictionary["request"] = "playlist"
        requestDictionary["fields"] = visibleColumns
        requestDictionary["id"] = id
        var data: NSData!
        do {
            data = try NSJSONSerialization.dataWithJSONObject(requestDictionary, options: NSJSONWritingOptions.PrettyPrinted)
            print("sending playlist request to peer")
            try session.sendData(data, toPeers: [peer], withMode: .Reliable)
        } catch {
            print("error asking for playlist: \(error)")
        }
    }
    
    func askPeerForSong(peer: MCPeerID, id: Int) {
        let requestDictionary = NSMutableDictionary()
        requestDictionary["type"] = "request"
        requestDictionary["request"] = "track"
        requestDictionary["id"] = id
        var data: NSData!
        do {
            data = try NSJSONSerialization.dataWithJSONObject(requestDictionary, options: NSJSONWritingOptions.PrettyPrinted)
            try session.sendData(data, toPeers: [peer], withMode: MCSessionSendDataMode.Reliable)
        } catch {
            print("error asking for song: \(error)")
        }
    }
    
    func askPeerForSongDownload(peer: MCPeerID, track: Track) {
        let requestDictionary = NSMutableDictionary()
        requestDictionary["type"] = "request"
        requestDictionary["request"] = "track download"
        requestDictionary["id"] = track.id!
        self.requestedTrackDatas[Int(track.id!)] = track
        var data: NSData!
        do {
            data = try NSJSONSerialization.dataWithJSONObject(requestDictionary, options: NSJSONWritingOptions.PrettyPrinted)
            try session.sendData(data, toPeers: [peer], withMode: MCSessionSendDataMode.Reliable)
        } catch {
            print("error asking for song download: \(error)")
        }
        
    }
    
    func addTracksForPlaylistData(playlistDictionary: NSDictionary, item: SourceListItem) {
        let library = {() -> Library? in
            let fetchReq = NSFetchRequest(entityName: "Library")
            let predicate = NSPredicate(format: "is_network == nil OR is_network == false")
            fetchReq.predicate = predicate
            do {
                let result = try managedContext.executeFetchRequest(fetchReq)[0] as! Library
                return result
            } catch {
                return nil
            }
        }()
        //get tracks
        let tracks = playlistDictionary["playlist"] as! [NSDictionary]
        let addedArtists = NSMutableDictionary()
        let addedAlbums = NSMutableDictionary()
        let addedComposers = NSMutableDictionary()
        let addedGenres = NSMutableDictionary()
        let addedTracks = NSMutableDictionary()
        var addedTrackViews = [TrackView]()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        for track in tracks {
            let newTrack = NSEntityDescription.insertNewObjectForEntityForName("Track", inManagedObjectContext: managedContext) as! Track
            let newTrackView = NSEntityDescription.insertNewObjectForEntityForName("TrackView", inManagedObjectContext: managedContext) as! TrackView
            newTrackView.is_network = true
            newTrackView.track = newTrack
            newTrack.is_network = true
            newTrack.is_playing = false
            for field in track.allKeys as! [String] {
                let trackArtist: Artist
                switch field {
                case "id":
                    let id = track["id"] as! Int
                    newTrack.id = track["id"] as? Int
                    addedTracks[id] = newTrack
                case "is_enabled":
                    newTrack.status = track["is_enabled"] as? Bool
                case "name":
                    newTrack.name = track["name"] as? String
                    newTrackView.name_order = track["name_order"] as? Int
                case "time":
                    newTrack.time = track["time"] as? NSNumber
                case "artist":
                    let artistName = track["artist"] as! String
                    let artist: Artist = {
                        if addedArtists[artistName] != nil {
                            return addedArtists[artistName] as! Artist
                        } else {
                            let artistCheck = checkIfArtistExists(artistName)
                            if artistCheck == nil {
                                let artist = NSEntityDescription.insertNewObjectForEntityForName("Artist", inManagedObjectContext: managedContext) as! Artist
                                artist.name = artistName
                                artist.id = library?.next_artist_id
                                library?.next_artist_id = Int(library!.next_artist_id!) + 1
                                artist.is_network = true
                                addedArtists[artistName] = artist
                                return artist
                            } else {
                                return artistCheck!
                            }
                        }
                    }()
                    newTrack.artist = artist
                    newTrackView.artist_order = track["artist_order"] as? Int
                    trackArtist = artist
                case "album":
                    let albumName = track["album"] as! String
                    let album: Album = {
                        if addedAlbums[albumName] != nil {
                            return addedAlbums[albumName] as! Album
                        } else {
                            let albumCheck = checkIfAlbumExists(albumName)
                            if albumCheck == nil {
                                let album = NSEntityDescription.insertNewObjectForEntityForName("Album", inManagedObjectContext: managedContext) as! Album
                                album.name = albumName
                                album.id = library?.next_album_id
                                library?.next_album_id = Int(library!.next_album_id!) + 1
                                album.is_network = true
                                addedAlbums[albumName] = album
                                return album
                            } else {
                                return albumCheck!
                            }
                        }
                    }()
                    newTrack.album = album
                    newTrackView.album_order = track["album_order"] as? Int
                case "date_added":
                    newTrack.date_added = dateFormatter.dateFromString(track["date_added"] as! String)
                    newTrackView.date_added_order = track["date_added_order"] as? Int
                case "date_modified":
                    newTrack.date_modified = dateFormatter.dateFromString(track["date_modified"] as! String)
                case "date_released":
                    newTrack.album?.release_date = dateFormatter.dateFromString(track["date_released"] as! String)
                    newTrackView.release_date_order = track["release_date_order"] as? Int
                case "comments":
                    newTrack.comments = track["comments"] as? String
                case "composer":
                    let composerName = track["composer"] as! String
                    let composer: Composer = {
                        if addedComposers[composerName] != nil {
                            return addedComposers[composerName] as! Composer
                        } else {
                            let composerCheck = checkIfComposerExists(composerName)
                            if composerCheck == nil {
                                let composer = NSEntityDescription.insertNewObjectForEntityForName("Composer", inManagedObjectContext: managedContext) as! Composer
                                composer.name = composerName
                                composer.id = library?.next_composer_id
                                library?.next_composer_id = Int(library!.next_composer_id!) + 1
                                composer.is_network = true
                                addedComposers[composerName] = composer
                                return composer
                            } else {
                                return composerCheck!
                            }
                        }
                    }()
                    newTrack.composer = composer
                case "disc_number":
                    newTrack.disc_number = track["disc_number"] as? Int
                case "equalizer_preset":
                    newTrack.equalizer_preset = track["equalizer_preset"] as? String
                case "genre":
                    let genreName = track["genre"] as! String
                    let genre: Genre = {
                        if addedComposers[genreName] != nil {
                            return addedGenres[genreName] as! Genre
                        } else {
                            let genreCheck = checkIfGenreExists(genreName)
                            if genreCheck == nil {
                                let genre = NSEntityDescription.insertNewObjectForEntityForName("Genre", inManagedObjectContext: managedContext) as! Genre
                                genre.name = genreName
                                genre.id = library?.next_genre_id
                                library?.next_genre_id = Int(library!.next_genre_id!) + 1
                                genre.is_network = true
                                addedGenres[genreName] = genre
                                return genre
                            } else {
                                return genreCheck!
                            }
                        }
                    }()
                    newTrack.genre = genre
                    newTrackView.genre_order = track["genre_order"] as? Int
                case "kind":
                    newTrack.file_kind = track["kind"] as? String
                    newTrackView.kind_order = track["kind_order"] as? Int
                case "date_last_played":
                    newTrack.date_last_played = dateFormatter.dateFromString(track["date_last_played"] as! String)
                case "date_last_skipped":
                    newTrack.date_last_skipped = dateFormatter.dateFromString(track["date_last_skipped"] as! String)
                case "movement_name":
                    newTrack.movement_name = track["movement_name"] as? String
                case "movement_number":
                    newTrack.movement_number = track["movement_number"] as? Int
                case "play_count":
                    newTrack.play_count = track["play_count"] as? Int
                case "rating":
                    newTrack.rating = track["rating"] as? Int
                case "bit_rate":
                    newTrack.bit_rate = track["bit_rate"] as? Int
                case "sample_rate":
                    newTrack.sample_rate = track["sample_Rate"] as? Int
                case "size":
                    newTrack.size = track["size"] as? Int
                case "skip_count":
                    newTrack.skip_count = track["skip_count"] as? Int
                case "sort_album":
                    newTrack.sort_album = track["sort_album"] as? String
                case "sort_album_artist":
                    newTrack.sort_album_artist = track["sort_album_artist"] as? String
                    newTrackView.album_artist_order = track["album_artist_order"] as? Int
                case "sort_artist":
                    newTrack.sort_artist = track["sort_artist"] as? String
                case "sort_composer":
                    newTrack.sort_composer = track["sort_composer"] as? String
                case "sort_name":
                    newTrack.sort_name = track["sort_name"] as? String
                case "track_number":
                    newTrack.track_num = track["track_number"] as? Int
                case "location":
                    newTrack.location = track["location"] as? String
                case "album_artist":
                    let artistName = track["album_artist"] as! String
                    let artist: Artist = {
                        if addedArtists[artistName] != nil {
                            return addedArtists[artistName] as! Artist
                        } else {
                            let artistCheck = checkIfArtistExists(artistName)
                            if artistCheck == nil {
                                let artist = NSEntityDescription.insertNewObjectForEntityForName("Artist", inManagedObjectContext: managedContext) as! Artist
                                artist.name = artistName
                                artist.is_network = true
                                addedArtists[artistName] = artist
                                return artist
                            } else {
                                return artistCheck!
                            }
                        }
                    }()
                    newTrack.album?.album_artist = artist
                default:
                    break
                }
            }
            addedTrackViews.append(newTrackView)
        }
        let track_id_list = addedTrackViews.map({return Int($0.track!.id!)})
        item.playlist?.track_id_list = track_id_list
        interface!.doneAddingNetworkPlaylistCallback(item)
        
    }
}