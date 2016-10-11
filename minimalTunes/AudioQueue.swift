 //
//  AudioQueue.swift
//  minimalTunes
//
//  Created by John Moody on 6/13/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
import AVFoundation

enum completionHandlerType {
    case seek
    case natural
    case destroy
}

class AudioQueue: NSObject, AVAudioPlayerDelegate {
    
    dynamic var trackQueue = [Track]()
    dynamic var currentTrack: Track?
    dynamic var auxTrackQueue = [Track]()
    
    var curNode = AVAudioPlayerNode()
    var mixerNode = AVAudioMixerNode()
    var curFile: AVAudioFile?
    var audioEngine = AVAudioEngine()
    
    dynamic var is_initialized = false
    dynamic var track_changed = false
    dynamic var needs_tracks = false
    dynamic var done_playing = true
    
    var currentHandlerType: completionHandlerType = .natural
    
    var duration_seconds: Double?
    var duration_frames: Int64?
    var track_frame_offset: Double?
    var is_paused: Bool?
    
    var total_offset_frames: Int64 = 0
    var total_offset_seconds: Int64 = 0
    
    var mainWindowController: MainWindowController?
    
    override init() {
        audioEngine.attachNode(curNode)
        audioEngine.connect(curNode, to: audioEngine.mainMixerNode, format: curFile?.processingFormat)
    }
    
    
    func playImmediately(track: Track) {
        currentHandlerType = .destroy
        print("paused value is \(is_paused)")
        currentTrack = track
        initializePlayback()
        if (is_paused == false || is_paused == nil) {
            print("reached play clause")
            play()
        }
        print(audioEngine)
        currentHandlerType = .natural
    }
    
    func addTrackToQueue(track: Track, index: Int?) {
        print("adding track to audio queue")
        print(index)
        print(trackQueue.count)
        if (currentTrack == nil) {
            playImmediately(track)
        }
        else if (trackQueue.count == 0) {
            trackQueue.append(track)
        }
        else {
            if (index != nil && index < trackQueue.count) {
                trackQueue.insert(track, atIndex: index!)
            }
            else {
                trackQueue.append(track)
            }
        }
    }
    
    
    func swapTracks(first_index: Int, second_index: Int) {
        if (trackQueue.count < 2) {
            return
        }
        else {
            let tmp = trackQueue[first_index]
            trackQueue[first_index] = trackQueue[second_index]
            trackQueue[second_index] = tmp
        }
    }
    
    func initializePlayback() {
        if currentTrack == nil {
            return
        }
        else {
            do {
                if curNode.playing == true {
                    print("initializing playback while node is playing, resetting node")
                    audioEngine.reset()//necessary?
                    total_offset_frames = 0
                    total_offset_seconds = 0
                    audioEngine.detachNode(curNode)
                    curNode = AVAudioPlayerNode()
                    audioEngine.attachNode(curNode)
                    audioEngine.connect(curNode, to: audioEngine.mainMixerNode, format: curFile?.processingFormat)
                }
                let location = currentTrack!.location!
                let url = NSURL(string: location)
                curFile = try AVAudioFile(forReading: url!)
                print(location)
                curNode.scheduleFile(curFile!, atTime: nil, completionHandler: handleCompletion)
                print(curFile?.processingFormat)
                print(audioEngine.outputNode)
                //audioEngine.connect(curNode, to: audioEngine.mainMixerNode, format: curFile?.processingFormat)
                resetValues()
                if (audioEngine.running == false) {
                    try audioEngine.start()
                }
                is_initialized = true
                self.track_frame_offset = 0
            }
            catch {
                print("audio player error: \(error)")
            }
        }
    }
    
    func changeTrack() {
        dispatch_async(dispatch_get_main_queue()) {
            print("changing track")
            if self.track_changed == false {
                self.track_changed = true
            }
            else if self.track_changed == true {
                self.track_changed = false
            }
        }
    }
    
    func observerDonePlaying() {
        print("setting done playing")
        if done_playing == true {
            done_playing = false
        }
        else if done_playing == false {
            done_playing = true
        }
    }
    
    func tryGetMoreTracks() {
        if trackQueue.count > 0 {
            currentTrack = trackQueue.removeFirst()
        }
        else {
            currentTrack = mainWindowController?.getNextTrack()
            mainWindowController?.currentTrack = currentTrack
        }
    }
    
    func handleCompletion() {
        //called any time the playback node is stopped, whether for a seek, skip, or natural playback operation ending
        //if this is the result of a scheduleFile or scheduleSegment operation, it is called after the last segment of the buffer is scheduled, not played. this is not the case for scheduleBuffer operations
        //this can probably crash all over the place if the database can't be accessed for any reason
        print("handle completion called")
        switch currentHandlerType {
        case .natural:
            tryGetMoreTracks()
            if (currentTrack != nil) {
                print("natural next track")
                var delay: Double = 0
                do {
                    let location = currentTrack!.location!
                    let url = NSURL(string: location)
                    let gapless_duration = AVAudioTime(sampleTime: curFile!.length - Int64(track_frame_offset!), atRate: curFile!.processingFormat.sampleRate)
                    total_offset_frames += gapless_duration.sampleTime
                    total_offset_seconds = total_offset_frames / Int64(curFile!.processingFormat.sampleRate)
                    curFile = try AVAudioFile(forReading: url!)
                    let time = AVAudioTime(sampleTime: total_offset_frames, atRate: curFile!.processingFormat.sampleRate)
                    curNode.scheduleFile(curFile!, atTime: time, completionHandler: handleCompletion)
                    delay = ((Double(gapless_duration.sampleTime) / gapless_duration.sampleRate) - (Double(curNode.lastRenderTime!.sampleTime - Int64(track_frame_offset!))/(curNode.lastRenderTime?.sampleRate)!))
                    self.track_frame_offset = 0
                    resetValues()
                } catch {
                    print("error: \(error)")
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                    self.changeTrack()
                }
            }
            else {
                print("natural next track, no new tracks")
                let gapless_duration = AVAudioTime(sampleTime: curFile!.length, atRate: curFile!.processingFormat.sampleRate)
                let delay = ((Double(gapless_duration.sampleTime) / gapless_duration.sampleRate) - (Double(curNode.lastRenderTime!.sampleTime)/(curNode.lastRenderTime?.sampleRate)!))
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                    //cleanly stop everything
                    self.observerDonePlaying()
                    self.total_offset_frames = 0
                    self.total_offset_seconds = 0
                    self.is_initialized = false
                    self.track_frame_offset = 0
                    self.audioEngine.reset()
                    print("done handling completion")
                }
            }
        case .seek:
            print("seek completion handler")
            //do nothing
        case .destroy:
            print("destruction")
            self.total_offset_frames = 0
            self.total_offset_seconds = 0
            self.track_frame_offset = 0
            //do nothing
        }
    }
    
    func skip() {
        tryGetMoreTracks()
        currentHandlerType = .destroy
        if (currentTrack != nil) {
            print("skipping to new track")
            playImmediately(currentTrack!)
            changeTrack()
        }
        else {
            print("skipping, no new track")
            //cleanly stop everything
            self.observerDonePlaying()
            self.total_offset_frames = 0
            self.total_offset_seconds = 0
            self.is_initialized = false
            self.track_frame_offset = 0
            self.audioEngine.reset()
        }
        currentHandlerType = .natural
    }
    
    func skip_backward() {
        
    }
    
    func seek(frac: Double) {
        let frame = Int64(frac * Double(duration_frames!))
        track_frame_offset = Double(frame)
        currentHandlerType = .seek
        curNode.stop()
        curNode.scheduleSegment(curFile!, startingFrame: frame, frameCount: UInt32(duration_frames!)-UInt32(frame), atTime: nil, completionHandler: handleCompletion)
        if (is_paused == false) {
            curNode.play()
        }
        total_offset_frames = 0
        total_offset_seconds = 0
        currentHandlerType = .natural
    }
    
    func resetValues() {
        if (curFile != nil) {
            duration_seconds = Double((curFile?.length)!) / (curFile?.processingFormat.sampleRate)!
            duration_frames = curFile?.length
        }
    }
    
    
    func play() {
        is_paused = false
        if audioEngine.running == true {
            curNode.play()
        } else {
            audioEngine.prepare()
            do {
                try audioEngine.start()
            } catch {
                print(error)
            }
        }

    }
    func pause() {
        is_paused = true
        curNode.pause()
    }
}
