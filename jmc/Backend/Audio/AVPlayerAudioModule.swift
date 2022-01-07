//
//  AVPlayerAudioModule.swift
//  jmc
//
//  Created by John Moody on 12/29/21.
//  Copyright © 2021 John Moody. All rights reserved.
//

import Cocoa
import AVFoundation

class AVPlayerAudioModule: NSObject {
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
    
    override init() {
        self.player = AVQueuePlayer()
    }
    
    func playImmediately(_ track: Track) {
        if let location = track.location {
            let trackURL = URL(string: location)!
            self.track = track
            self.player = AVQueuePlayer(url: trackURL)
            DispatchQueue.main.async {self.changeTrackObservers()}
            self.player.play()
        }
    }
    
    func playImmediatelyNoObservers(_ track: Track) {
        if let location = track.location {
            let trackURL = URL(string: location)!
            self.track = track
            self.player = AVQueuePlayer(url: trackURL)
            self.player.play()
        }
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
            changeTrack(changeEventID: self.currentValidChangeTrackEventID)
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
            playImmediatelyNoObservers(self.track)
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
    
}
