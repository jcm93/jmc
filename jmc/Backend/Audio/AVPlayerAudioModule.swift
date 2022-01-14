//
//  AVPlayerAudioModule.swift
//  jmc
//
//  Created by John Moody on 12/29/21.
//  Copyright © 2021 John Moody. All rights reserved.
//

import Cocoa
import AVFoundation
import AVKit

class AVPlayerAudioModule: NSObject, AVRoutePickerViewDelegate {
    //now that macos natively supports flac, no need for bundled .flac/.ogg, AudioModule, FileBufferer, etc....
    var player: AVQueuePlayer!
    var track: Track!
    var nextTrack: Track!
    var is_paused: Bool = false
    var fileManager: FileManager = FileManager()
    var currentValidChangeTrackEventID: Int = 0
    var upcomingTrack: Track? = nil
    var isSeeking: Bool = false
    var networkFlag: Bool = false
    var mainWindowController: MainWindowController!
    @objc dynamic var done_playing = false
    @objc dynamic var track_changed = false
    var firstPlay = true
    var currentBoundaryObserver: Any?
    var musicKitTestThing: MusicKitPlayer?
    var appleMusicTrackIdentifier: Any?
    
    override init() {
        self.player = AVQueuePlayer()
        super.init()
        self.player.allowsExternalPlayback = true
        self.player.addObserver(self, forKeyPath: "currentItem", options: .new, context: nil)
        self.musicKitTestThing = MusicKitPlayer()
        let appURL = URL(string: "https://github.com/jcm93/jmc")!
        self.musicKitTestThing!.configure(withDeveloperToken: secretAPITokenInSecretFile, appName: "jmc", appBuild: "0.3", appURL: appURL, appIconURL: nil, onSuccess: success, onError: errorAuthorizing)
        if #available(macOS 12.0, *) {
            self.appleMusicTrackIdentifier = AppleMusicTrackIdentifier(authorizes: true)
        }
    }
    
    func success() {
        print("successfully authorized")
        self.musicKitTestThing?.authorize(onSuccess: successAuthorizing, onError: errorAuthorizing)
    }
    
    func successAuthorizing(_ thing: String) {
        print("poopy")
    }
    
    func errorAuthorizing(_ error: Error) {
        print("error authorizing")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "currentItem" {
            changeTrackObservers()
            self.registerBoundaryObserverForNewTrack()
        }
    }
    
    func registerBoundaryObserverForNewTrack() {
        //lets check when 1 second out
        let boundary = CMTimeSubtract(self.player.currentItem!.asset.duration, CMTime(seconds: 1.0, preferredTimescale: self.player.currentItem!.asset.duration.timescale))
        let boundaryValue = NSValue(time: boundary)
        self.player.addBoundaryTimeObserver(forTimes: [boundaryValue], queue: DispatchQueue.main, using: itemAboutToFinishPlaying)
    }
    
    func itemAboutToFinishPlaying() {
        removeObservers()
        if self.player.items().count > 1 {
            //don't need to do anything
        } else {
            let nextTrack = mainWindowController?.getNextTrack(background: false)
            if nextTrack?.is_network == true {
                networkFlag = true
            }
            let newItem = makeAVPlayerItemFromTrack(nextTrack!)
            self.player.insert(newItem, after: self.player.currentItem)
        }
    }
    
    func removeObservers() {
        if let observer = self.currentBoundaryObserver {
            self.player.removeTimeObserver(observer)
        }
    }
    
    func makeAVPlayerItemFromTrack(_ track: Track) -> AVPlayerItem {
        let url = URL(string: track.location!)!
        let item = AVPlayerItem(url: url)
        return item
    }
    
    func playImmediately(_ track: Track) {
        if let location = track.location {
            let trackURL = URL(string: location)!
            self.track = track
            let item = AVPlayerItem(url: trackURL)
            if item.asset == self.player.currentItem?.asset {
                self.player.seek(to: CMTime(seconds: 0.0, preferredTimescale: item.duration.timescale))
            } else {
                removeObservers()
                self.player.replaceCurrentItem(with: item)
                let itemsToRemove = self.player.items()[1..<self.player.items().count]
                for item in itemsToRemove {
                    self.player.remove(item)
                }
            }
            //DispatchQueue.main.async {self.changeTrackObservers()}
            self.player.play()
        } else {
            let trackName = track.name ?? ""
            //if track.is_network == true {
                if #available(macOS 12.0, *) {
                    Task {
                        let trackID = await (self.appleMusicTrackIdentifier as! AppleMusicTrackIdentifier).requestResource(track: trackName)
                        let mediaID = MediaID(trackID)
                        self.musicKitTestThing!.setQueue(song: mediaID, onSuccess: self.musicKitTestThing!.player.play, onError: errorStartingStreamedTrack)
                    }
                }
            //}
        }
    }
    
    func doNothing() {
        
    }
    
    func errorStartingStreamedTrack(e: Error) {
        print(e)
    }
    
    func changeTrackObservers() {
        if self.track_changed == false {
            self.track_changed = true
        }
        else if self.track_changed == true {
            self.track_changed = false
        }
    }
    
    func changeTrack(changeEventID: Int) {
        
    }
    
    func pause() {
        self.is_paused = true
        self.player.pause()
    }
    
    func play() {
        guard fileManager.fileExists(atPath: URL(string: self.track.location!)!.path) else {return}
        is_paused = false
        self.player.play()
        if upcomingTrack != nil {
            self.changeTrack(changeEventID: self.currentValidChangeTrackEventID)
        }
    }
    
    func seek(_ frac: Double) {
        guard self.isSeeking != true else {
            print("is seeking;returning");
            return
        }
        self.isSeeking = true
        let duration = self.player.currentItem!.duration.seconds
        let timescale = self.player.currentItem!.duration.timescale
        let newDuration = frac * duration
        let newTime = CMTime(seconds: newDuration, preferredTimescale: timescale)
        self.player.seek(to: newTime)
        //ends up at self.fileBuffererSeekDecodeCallback
        self.isSeeking = false
    }
    
    func skip() {
        tryGetMoreTracks(background: false)
        playImmediately(self.track)
    }
    
    func skipBackward() {
        if (self.track != nil) {
            print("skipping to new track")
            playImmediately(self.track)
        }
        else {
            print("skipping, no new track")
            //cleanly stop everything
            self.player = AVQueuePlayer()
            self.observerDonePlaying()
        }
    }
    
    func observerDonePlaying() {
        print("setting done playing")
        if done_playing == true {
            done_playing = false
        } else if done_playing == false {
            done_playing = true
        }
    }
    
    func tryGetMoreTracks(background: Bool) {
        if self.nextTrack != nil {
            self.track = background ? backgroundContext.object(with: self.nextTrack.objectID) as? Track : self.nextTrack
        } else {
            self.nextTrack = self.mainWindowController?.getNextTrack(background: background)
            if nextTrack?.is_network == true {
                networkFlag = true
            }
            self.track = nextTrack
            self.nextTrack = nil
        }
    }
    
    func addTrackToQueue(_ track: Track, index: Int) {
        let itemURL = URL(string: track.location!)!
        let asset = AVPlayerItem(url: itemURL)
        let itemToInsertAfter = self.player.items()[index - 1]
        self.player.insert(asset, after: itemToInsertAfter)
    }
    
    func addAVPlayerItemToQueue(item: AVPlayerItem, index: Int) {
        let itemToInsertAfter = self.player.items()[index - 1]
        self.player.insert(item, after: itemToInsertAfter)
    }
    
    func removeTrackAtIndex(index: Int) -> AVPlayerItem {
        let item = self.player.items()[index]
        self.player.remove(item)
        return item
    }
    
}

