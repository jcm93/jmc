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

class AudioQueue: NSObject {
    //todo consistent naming
    dynamic var trackQueue = [Track]()
    dynamic var currentTrackLocation: String?
    
    var curNode = AVAudioPlayerNode()
    var mixerNode = AVAudioMixerNode()
    var equalizer: AVAudioUnitEQ = {
        let doingle = AVAudioUnitEQ(numberOfBands: 10)
        let bands = doingle.bands
        bands[0].frequency = 32
        bands[0].bypass = false
        bands[1].frequency = 64
        bands[1].bypass = false
        bands[2].frequency = 128
        bands[2].bypass = false
        bands[3].frequency = 256
        bands[3].bypass = false
        bands[4].frequency = 512
        bands[4].bypass = false
        bands[5].frequency = 1024
        bands[5].bypass = false
        bands[6].frequency = 2048
        bands[6].bypass = false
        bands[7].frequency = 4096
        bands[7].bypass = false
        bands[8].frequency = 8192
        bands[8].bypass = false
        bands[9].frequency = 16384
        bands[9].bypass = false
        return doingle
    }()
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
        //audioEngine.connect(curNode, to: audioEngine.mainMixerNode, format: curFile?.processingFormat)
        audioEngine.attachNode(equalizer)
        /*audioEngine.connect(curNode, to: equalizer, format: nil)
        audioEngine.connect(equalizer, to: audioEngine.outputNode, format: nil)*/
        audioEngine.connect(curNode, to: equalizer, format: nil)
        audioEngine.connect(equalizer, to: audioEngine.outputNode, format: nil)
    }
    
    func adjustEqualizer(band: Int, value: Float) {
        print("adjust band called")
        guard -12 <= value && value <= 12 else {return}
        print("adjusting a band")
        let band = equalizer.bands[band]
        band.gain = value
    }
    
    func toggleEqualizer(state: Int) {
        if state == NSOnState {
            print("using eq")
            equalizer.bypass = false
            
        } else {
            print("no eq")
            equalizer.bypass = true
        }
    }
    
    func adjustGain(value: Float) {
        guard -12 <= value && value <= 12 else {return}
        equalizer.globalGain = value
    }
    
    func playNetworkImmediately(track: NetworkTrack) {
        currentHandlerType = .destroy
        let networkPath = NSUserDefaults.standardUserDefaults().stringForKey("libraryPath")! + "/test.mp3"
        currentTrackLocation = NSURL(fileURLWithPath: networkPath).absoluteString
        print("paused value is \(is_paused)")
        initializePlayback()
        if (is_paused == false || is_paused == nil) {
            print("reached play clause")
            play()
        }
        print(audioEngine)
        currentHandlerType = .natural
    }
    
    func playImmediately(trackLocation: String) {
        currentHandlerType = .destroy
        print("paused value is \(is_paused)")
        currentTrackLocation = trackLocation
        initializePlayback()
        if (is_paused == false || is_paused == nil) {
            print("reached play clause")
            play()
        }
        print(audioEngine)
        currentHandlerType = .natural
        changeTrack()
    }
    
    func addTrackToQueue(track: Track, index: Int?) {
        print("adding track to audio queue")
        print(index)
        print(trackQueue.count)
        if (currentTrackLocation == nil) {
            playImmediately(track.location!)
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
        if currentTrackLocation == nil {
            return
        }
        else {
            do {
                if curNode.playing == true {
                    print("initializing playback while node is playing, resetting node")
                    total_offset_frames = 0
                    total_offset_seconds = 0
                    audioEngine.stop()
                    audioEngine.detachNode(curNode)
                    curNode = AVAudioPlayerNode()
                    audioEngine.attachNode(curNode)
                    audioEngine.connect(curNode, to: equalizer, format: nil)
                }
                let location = currentTrackLocation!
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
            currentTrackLocation = trackQueue.removeFirst().location!
        }
        else {
            let nextTrack = mainWindowController?.getNextTrack()
            currentTrackLocation = nextTrack?.location
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
            if (currentTrackLocation != nil) {
                print("natural next track")
                var delay: Double = 0
                do {
                    let location = currentTrackLocation!
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
        if (currentTrackLocation != nil) {
            print("skipping to new track")
            playImmediately(currentTrackLocation!)
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
