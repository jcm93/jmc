 //
//  AudioModule.swift
//  minimalTunes
//
//  Created by John Moody on 6/13/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
import AVFoundation
import AVKit

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}


enum completionHandlerType: Int {
    case seek
    case natural
    case destroy
}
 
 enum LastTrackCompletionType: Int {
    case natural, skipped
 }
 
//typealias FLAC__StreamDecoderReadCallback = (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafeMutablePointer<UInt8>>, Optional<UnsafeMutablePointer<Int>>, Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderReadStatus
 

 class AudioModule: NSObject {
    
    /*
    graph structure:
  
    player node
        |
    mixer (for sample rate conversion)
        |
    equalizer
        |
    mainMixerNode (for volume control)
        |
    outputNode
  
    */
    
    //todo consistent naming
    @objc dynamic var trackQueue = [Track]()
    @objc dynamic var currentTrackLocation: String?
    var networkFlag = false
    var fileBuffererDictionary = [URL : FileBufferer]()
    var currentFileBufferer: FileBufferer?
    var trackTransitionBufferGuardStop = false
    var fileManager = FileManager.default
    var upcomingTrackURL: URL?
    var endOfCurrentTrackFrame: AVAudioFramePosition?
    //var airplayDeviceHandler: AirPlayDeviceHandler
    
    let verbotenFileTypes = ["m4v", "m4p"]
    
    var curPlayerNode = AVAudioPlayerNode()
    var sampleRateMixer = AVAudioMixerNode()
    var equalizer: AVAudioUnitEQ = {
        let doingle = AVAudioUnitEQ(numberOfBands: 10)
        let bands = doingle.bands
        bands[0].frequency = 32
        bands[0].bandwidth = 1
        bands[0].bypass = false
        bands[1].frequency = 64
        bands[1].bandwidth = 1
        bands[1].bypass = false
        bands[2].frequency = 128
        bands[2].bandwidth = 1
        bands[2].bypass = false
        bands[3].frequency = 256
        bands[3].bandwidth = 1
        bands[3].bypass = false
        bands[4].frequency = 512
        bands[4].bandwidth = 1
        bands[4].bypass = false
        bands[5].frequency = 1024
        bands[5].bandwidth = 1
        bands[5].bypass = false
        bands[6].frequency = 2048
        bands[6].bandwidth = 1
        bands[6].bypass = false
        bands[7].frequency = 4096
        bands[7].bandwidth = 1
        bands[7].bypass = false
        bands[8].frequency = 8192
        bands[8].bandwidth = 1
        bands[8].bypass = false
        bands[9].frequency = 16384
        bands[9].bandwidth = 1
        bands[9].bypass = false
        if let defaultsEQ = UserDefaults.standard.object(forKey: DEFAULTS_CURRENT_EQ_STRING) as? [Float] {
            var index = 0
            for band in defaultsEQ {
                if index == 10 {continue}
                bands[index].gain = band
                index += 1
            }
            doingle.globalGain = defaultsEQ[10]
        }
        return doingle
    }()
    var curFile: AVAudioFile?
    var audioEngine = AVAudioEngine()
    var lastTrackCompletionType: LastTrackCompletionType = .natural
    var routeDetector: NSObject?
    
    @objc dynamic var is_initialized = false
    @objc dynamic var track_changed = false
    @objc dynamic var needs_tracks = false
    @objc dynamic var done_playing = true
    
    var currentHandlerType: completionHandlerType = .natural
    
    var duration_seconds: Double?
    var duration_frames: Int64?
    var track_frame_offset: Double?
    var is_paused: Bool?
    var finalBuffer: Bool?
    var finalBufferQueued: Bool?
    var isSeeking = false
    var seekInterrupted = false
    var didSeek = false
    var seekFinalCount = 0
    var changeTrackEventCounter: Int = 0
    var currentValidChangeTrackEventID: Int = 0
    var lastRenderedFrame: AVAudioFramePosition? = 0
    var isFirstPlayback = true
    var queueNextTrackEventCounter: Int = 0
    var currentValidQueueEventID: Int = 0
    var differentFileScheduleTime: AVAudioTime?
    
    var total_offset_frames:   Int64 = 0
    var total_offset_seconds: Double = 0
    var nextBufferStartFrame: Int64 = 0
    var nextFileIsDifferentFormat = false
    var nextFileInitialBuffer: AVAudioPCMBuffer?
    
    var mainWindowController: MainWindowController?
    
    func addListenerBlock( _ listenerBlock: @escaping AudioObjectPropertyListenerBlock, onAudioObjectID: AudioObjectID, forPropertyAddress: AudioObjectPropertyAddress) {
        var forPropertyAddress = forPropertyAddress
        if (kAudioHardwareNoError != AudioObjectAddPropertyListenerBlock(onAudioObjectID, &forPropertyAddress, nil, listenerBlock)) {
            print("Error calling: AudioObjectAddPropertyListenerBlock") }
    }
    
    override init() {
        //self.airplayDeviceHandler = AirPlayDeviceHandler()
        super.init()
        /*addListenerBlock(audioObjectPropertyListenerBlock,
                         onAudioObjectID: AudioObjectID(bitPattern: kAudioObjectSystemObject),
                         forPropertyAddress: AudioObjectPropertyAddress(
                            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                            mScope: kAudioObjectPropertyScopeGlobal,
                            mElement: kAudioObjectPropertyElementMaster))*/
        doInitialization()
    }
    
    func doInitialization() {
        audioEngine.attach(curPlayerNode)
        audioEngine.attach(self.sampleRateMixer)
        audioEngine.attach(self.equalizer)
        audioEngine.connect(curPlayerNode, to: sampleRateMixer, format: nil)
        audioEngine.connect(sampleRateMixer, to: equalizer, format: nil)
        audioEngine.connect(equalizer, to: audioEngine.mainMixerNode, format: nil)
        if #available(OSX 10.13, *) {
            self.routeDetector = AVRouteDetector()
        } else {
            // Fallback on earlier versions
        }
    }
    
    func resetEngineCompletely() {
        self.audioEngine.stop() //hmm
        audioEngine.detach(curPlayerNode)
        audioEngine.detach(self.sampleRateMixer)
        audioEngine.detach(self.equalizer)
        self.curPlayerNode = AVAudioPlayerNode()
        self.curPlayerNode.reset()
        doInitialization()
    }
    
    func getDefaultAudioOutputDevice () -> AudioObjectID {
        var devicePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        var deviceID: AudioObjectID = 0
        var dataSize = UInt32(truncatingIfNeeded: MemoryLayout<AudioDeviceID>.size)
        let systemObjectID = AudioObjectID(bitPattern: kAudioObjectSystemObject)
        if (kAudioHardwareNoError != AudioObjectGetPropertyData(systemObjectID, &devicePropertyAddress, 0, nil, &dataSize, &deviceID)) { return 0 }
        return deviceID
    }
 
    func audioObjectPropertyListenerBlock (_ numberAddresses: UInt32, addresses: UnsafePointer<AudioObjectPropertyAddress>) {
        var index: UInt32 = 0
        while index < numberAddresses {
            let address: AudioObjectPropertyAddress = addresses[0]
            switch address.mSelector {
            case kAudioHardwarePropertyDefaultOutputDevice:
                var deviceID = getDefaultAudioOutputDevice()
                print(audioEngine.isRunning)
                print(curPlayerNode.isPlaying)
                do {
                    AudioUnitSetProperty(audioEngine.outputNode.audioUnit!, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &deviceID, UInt32(MemoryLayout<AudioObjectID>.size))
                    audioEngine.reset()
                    try audioEngine.start()
                } catch {
                    print("starting failed")
                    print(error)
                }
                print("kAudioHardwarePropertyDefaultOutputDevice: \(deviceID)")
                print(audioEngine.isRunning)
                print(curPlayerNode.isPlaying)
            default:
                print("uhh")
            }
            index += 1
        }
    }
    
    func adjustEqualizer(_ band: Int, value: Float) {
        print("adjust band called")
        guard -12 <= value && value <= 12 else {return}
        print("adjusting a band")
        let band = equalizer.bands[band]
        var defaultsEQ = equalizer.bands.map({return $0.gain})
        defaultsEQ.append(equalizer.globalGain)
        UserDefaults.standard.set(defaultsEQ, forKey: DEFAULTS_CURRENT_EQ_STRING)
        band.gain = value
    }
    
    func changeVolume(_ newVolume: Float) {
        //todo figure out why this doesnt work
        guard newVolume <= 1 && newVolume >= 0 else {return}
        audioEngine.mainMixerNode.outputVolume = newVolume
        UserDefaults.standard.set(newVolume, forKey: DEFAULTS_VOLUME_STRING)
    }
    
    func toggleEqualizer(_ state: Int) {
        if state == NSControl.StateValue.on.rawValue {
            print("using eq")
            equalizer.bypass = false
            
        } else {
            print("no eq")
            equalizer.bypass = true
        }
    }
    
    func adjustGain(_ value: Float) {
        guard -12 <= value && value <= 12 else {return}
        equalizer.globalGain = value
        var defaultsEQ = equalizer.bands.map({return $0.gain})
        defaultsEQ.append(equalizer.globalGain)
        UserDefaults.standard.set(defaultsEQ, forKey: DEFAULTS_CURRENT_EQ_STRING)
    }
    
    func playNetworkImmediately(_ track: Track) {
        self.isFirstPlayback = true
        currentHandlerType = .destroy
        currentTrackLocation = track.location
        print("paused value is \(is_paused)")
        initializePlayback()
        play()
        print(audioEngine)
        currentHandlerType = .natural
        changeTrack(changeEventID: self.currentValidChangeTrackEventID)
        self.isFirstPlayback = false
    }
    
    func stopForNetworkTrack() {
        curPlayerNode.pause()
    }
    
    func playImmediately(_ trackLocation: String) {
        self.isFirstPlayback = true
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
        changeTrack(changeEventID: self.currentValidChangeTrackEventID)
        self.isFirstPlayback = false
    }
    
    func playImmediatelyNoObservers(_ trackLocation: String) {
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
    }
    
    func removeTracksFromQueue(_ indexes: [Int]) {
    }
    
    func addTrackToQueue(_ track: Track, index: Int?) {
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
                trackQueue.insert(track, at: index!)
                print("inserted \(track.name) at \(index)")
            }
            else {
                trackQueue.append(track)
            }
        }
    }
    
    
    func swapTracks(_ first_index: Int, second_index: Int) {
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
                print("initializing playback for new thing, resetting node")
                self.trackTransitionBufferGuardStop = true
                total_offset_frames = 0
                total_offset_seconds = 0
                nextBufferStartFrame = 0
                resetEngineCompletely()
                let location = currentTrackLocation!
                let url = URL(string: location)
                if verbotenFileTypes.contains(url!.pathExtension) {
                    return
                }
                self.currentFileBufferer = createFileBufferer(url: url!)
                let initialBuffer = self.currentFileBufferer!.prepareFirstBuffer()
                nextBufferStartFrame += Int64(initialBuffer!.frameLength)
                audioEngine.disconnectNodeInput(sampleRateMixer)
                audioEngine.connect(curPlayerNode, to: sampleRateMixer, format: currentFileBufferer?.format)
                self.curPlayerNode.scheduleBuffer(initialBuffer!, at: nil, options: .interrupts, completionHandler: fileBuffererCompletion)
                DispatchQueue.global(qos: .default).async {
                    print("dispatching second buffer fill for new track")
                    self.finalBuffer = false
                    self.currentFileBufferer!.fillNextBuffer()
                }
                //print("scheduling initial buffer of length \(initialBuffer!.frameLength)")
                //print("nextBufferStartFrame is \(self.nextBufferStartFrame)")
                //print(curFile?.processingFormat)
                //print(audioEngine.outputNode)
                resetValues()
                if (audioEngine.isRunning == false) {
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
    
    func prepareEngineForNewFormat(_ format: AVAudioFormat) {
        
    }
    
    func changeTrack(changeEventID: Int) {
        print("changeTrack called")
        if (changeEventID != self.currentValidChangeTrackEventID) {
            print("ignoring changeTrack event, invalid ID. eventID is \(changeEventID), validID is \(self.currentValidChangeTrackEventID)")
            //ignore
        } else {
            if self.isFirstPlayback == true {
                print("this should only be called if no tracks have played yet")
                self.isFirstPlayback = false
                DispatchQueue.main.async {
                    if self.track_changed == false {
                        self.track_changed = true
                    }
                    else if self.track_changed == true {
                        self.track_changed = false
                    }
                }
            } else {
                let frameLastPlayed = self.curPlayerNode.playerTime(forNodeTime: self.curPlayerNode.lastRenderTime!)?.sampleTime ?? self.lastRenderedFrame ?? 0//uh
                if frameLastPlayed >= self.endOfCurrentTrackFrame! {
                    if self.nextFileIsDifferentFormat != false {
                        print("different format thingy change")
                        audioEngine.disconnectNodeInput(sampleRateMixer)
                        audioEngine.connect(curPlayerNode, to: sampleRateMixer, format: nextFileInitialBuffer!.format)
                        let time = curPlayerNode.playerTime(forNodeTime: AVAudioTime(sampleTime: self.endOfCurrentTrackFrame!, atRate: self.currentFileBufferer!.format.sampleRate))
                        curPlayerNode.scheduleBuffer(self.nextFileInitialBuffer!, at: time, options: .interrupts, completionHandler: fileBuffererCompletion)
                        self.nextBufferStartFrame = Int64(nextFileInitialBuffer!.frameLength)
                        self.nextFileIsDifferentFormat = false
                        self.nextFileInitialBuffer = nil
                        self.differentFileScheduleTime = nil
                        curPlayerNode.play()
                        total_offset_frames = 0
                        total_offset_seconds = 0
                        track_frame_offset = 0
                    } else {
                        print("total offset frames \(self.total_offset_frames)")
                        print("duration frames \(self.duration_frames)")
                        print("track frame offset \(self.track_frame_offset)")
                        let new_frames = (self.duration_frames! - Int64(self.track_frame_offset!))
                        let new_seconds = Double(new_frames) / self.currentFileBufferer!.currentDecodeBuffer.format.sampleRate
                        self.total_offset_frames += new_frames
                        print("new total offset frames \(self.total_offset_frames)")
                        self.total_offset_seconds += new_seconds
                    }
                    DispatchQueue.main.async {
                        if self.upcomingTrackURL != nil {
                            self.currentFileBufferer = self.fileBuffererDictionary[self.upcomingTrackURL!]
                            self.currentFileBufferer?.fillNextBuffer()
                        }
                        self.upcomingTrackURL = nil
                        self.resetValues()
                        if self.track_changed == false {
                            self.track_changed = true
                        }
                        else if self.track_changed == true {
                            self.track_changed = false
                        }
                        self.track_frame_offset = 0
                    }
                } else {
                    //are we paused?
                    if self.is_paused == true {
                        //do nothing, we'll catch it when we unpause
                    } else {
                        let length = self.duration_frames!
                        let gapless_duration = AVAudioTime(sampleTime: length - Int64(self.track_frame_offset!) + self.total_offset_frames, atRate: self.currentFileBufferer!.currentDecodeBuffer.format.sampleRate)
                        let secondsPlayed = Double(self.curPlayerNode.playerTime(forNodeTime: self.curPlayerNode.lastRenderTime!)!.sampleTime) / self.curPlayerNode.lastRenderTime!.sampleRate
                        let delay = ((Double(gapless_duration.sampleTime) / gapless_duration.sampleRate) - secondsPlayed)
                        print("delay set to \(delay)")
                        let thisChangeEventID = self.changeTrackEventCounter
                        self.changeTrackEventCounter += 1
                        self.currentValidChangeTrackEventID = thisChangeEventID
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                            self.changeTrack(changeEventID: thisChangeEventID)
                        }

                    }
                }
            }
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
    
    func getTrackLocation(_ track: Track) -> String {
        if track.is_network == false {
            return track.location!
        } else {
            return track.location!
        }
    }
    
    func tryGetMoreTracks() {
        if trackQueue.count > 0 {
            currentTrackLocation = trackQueue.removeFirst().location!
        } else {
            let nextTrack = mainWindowController?.getNextTrack()
            if nextTrack?.is_network == true {
                networkFlag = true
            }
            currentTrackLocation = nextTrack?.location
        }
    }
    
    func createFileBufferer(url: URL) -> FileBufferer? {
        print("begin create file bufferer")
        if url.pathExtension.lowercased() == "flac" {
            let fileBufferer = FlacDecoder(file: url, audioModule: self)
            fileBufferer?.actualInitTest()
            self.fileBuffererDictionary[url] = fileBufferer
            self.trackTransitionBufferGuardStop = false
            print("end create file bufferer")
            return fileBufferer
        } else {
            do {
                let newFile = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
                let fileBufferer = AVAudioFileBufferer(file: newFile, audioModule: self)
                self.fileBuffererDictionary[url] = fileBufferer
                print("end create file bufferer")
                self.trackTransitionBufferGuardStop = false
                return fileBufferer
            } catch {
                print(error)
                print("end create file bufferer")
                self.trackTransitionBufferGuardStop = false
                return nil
            }
        }
    }
    
    func fileBuffererCompletion() {
        if currentHandlerType == .destroy {
            lastTrackCompletionType = .skipped
        } else {
            lastTrackCompletionType = .natural
        }
        //swap decode buffer
        let bufferThatCompleted = currentFileBufferer?.currentDecodeBuffer == currentFileBufferer?.bufferA ? currentFileBufferer?.bufferA : currentFileBufferer?.bufferB
        //print("buffer that just played is \(bufferThatCompleted)")
        //print("\(Date()): file bufferer completion called, finalBuffer is \(finalBuffer) and trackTransitionBufferGuardStop is \(trackTransitionBufferGuardStop)")
        if self.isSeeking == true {
            print("is seeking, file bufferer completion finished")
            return
        }
        if self.finalBufferQueued == true {
            //skip filling next buffer, because initial buffer of next track is already scheduled
            self.finalBuffer = true
        } else if self.finalBuffer == true {
            self.finalBuffer = false
        } else if self.trackTransitionBufferGuardStop != true {
            //print("filling next buffer")
             self.currentFileBufferer!.fillNextBuffer()
        }
        //print("file bufferer completion finished")
    }
    
    func fileBuffererSeekDecodeCallback(isFinalBuffer: Bool) {
        //print("beginning of file seek buffer decode callback")
        if self.upcomingTrackURL != nil {
            self.upcomingTrackURL = nil
            self.seekInterrupted = true
        }
        let newBuffer = self.currentFileBufferer!.currentDecodeBuffer
        self.currentHandlerType = .seek
        curPlayerNode.stop()
        audioEngine.stop()
        audioEngine.detach(self.curPlayerNode)
        self.curPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(self.curPlayerNode)
        audioEngine.connect(self.curPlayerNode, to: self.sampleRateMixer, format: self.currentFileBufferer!.format)
        do {try audioEngine.start()} catch {print(error);return}
        self.total_offset_frames = 0
        self.total_offset_seconds = 0
        self.nextBufferStartFrame = 0
        total_offset_frames = 0
        total_offset_seconds = 0
        curPlayerNode.scheduleBuffer(newBuffer, at: nil, options: .interrupts, completionHandler: fileBuffererCompletion)
        curPlayerNode.play()
        self.currentHandlerType = .natural
        //print("cur player node last render time \(curPlayerNode.lastRenderTime)")
        //print("scheduled buffer \(newBuffer)")
        self.isSeeking = false
        if isFinalBuffer == true {
            self.finalBuffer = true
            self.finalBufferQueued = false
            print("is final buffer")
            nextBufferStartFrame += Int64(newBuffer.frameLength)
            //handle this differently..
            let thisQueueEventID = self.queueNextTrackEventCounter
            self.queueNextTrackEventCounter += 1
            self.currentValidQueueEventID = thisQueueEventID
            handleCompletion(optionalID: thisQueueEventID)
            //schedule next file
        } else {
            self.finalBuffer = false
            self.finalBufferQueued = false
            //print("is not final buffer")
            nextBufferStartFrame += Int64(newBuffer.frameLength)
            self.currentFileBufferer?.fillNextBuffer()
        }
        currentHandlerType = .natural
        self.didSeek = true
        mainWindowController?.seekCompleted()
        //print("end of file seek buffer decode callback")
    }
    
    func fileBuffererDecodeCallback(isFinalBuffer: Bool) {
        //called when a buffer is decoded. always schedule the buffer after the end of the current one
        //print("beginning of file buffer decode callback")
        let newBuffer = self.currentFileBufferer!.currentDecodeBuffer
        //turns out all this math is unnecessary; scheduling 'at the end of all other buffers' is sufficient
        //let currentBuffer = self.currentFileBufferer!.currentDecodeBuffer == self.currentFileBufferer!.bufferA ? self.currentFileBufferer!.bufferB : self.currentFileBufferer!.bufferA
        //let frameToScheduleAt = nextBufferStartFrame
        //print("scheduling buffer \(newBuffer) at frame \(frameToScheduleAt). buffer is \(newBuffer.frameLength) in length")
        //let time = AVAudioTime(sampleTime: frameToScheduleAt, atRate: currentBuffer.format.sampleRate)
        //print(time)
        curPlayerNode.scheduleBuffer(newBuffer, at: nil, options: .init(rawValue: 0), completionHandler: fileBuffererCompletion)
        if isFinalBuffer == true {
            self.finalBufferQueued = true
            self.finalBuffer = false
            nextBufferStartFrame += Int64(newBuffer.frameLength)
            handleCompletion(optionalID: nil)
            //schedule next file
        } else {
            self.finalBufferQueued = false
            self.finalBuffer = false
            nextBufferStartFrame += Int64(newBuffer.frameLength)
        }
        //print("end of file buffer decode callback")
    }
    
    func setUpNextFile(asyncID: Int?) {
        if self.isSeeking != true {
            DispatchQueue.main.async {
                if self.isSeeking != true {
                    guard asyncID == nil || asyncID == self.currentValidQueueEventID else {print("async ID invalid; returning");return}
                    let location = self.currentTrackLocation!
                    let url = URL(string: location)
                    if self.seekInterrupted == true {
                        self.seekInterrupted = false
                    }
                    let fileBufferer = self.createFileBufferer(url: url!)//modify
                    let sampleRate = self.curFile?.processingFormat.sampleRate ?? self.currentFileBufferer!.currentDecodeBuffer.format.sampleRate
                    let length = self.curFile?.length ?? (Int64(self.currentFileBufferer!.totalFrames))
                    let gapless_duration = AVAudioTime(sampleTime: length - Int64(self.track_frame_offset!) + self.total_offset_frames, atRate: sampleRate)
                    let initialBuffer = fileBufferer!.prepareFirstBuffer()
                    self.nextBufferStartFrame += Int64(initialBuffer!.frameLength)
                    print("scheduling initial buffer at frame \(gapless_duration)")
                    self.endOfCurrentTrackFrame = gapless_duration.sampleTime
                    
                    if initialBuffer!.format != self.curPlayerNode.outputFormat(forBus: 0) {
                        print("setting different format")
                        self.nextFileIsDifferentFormat = true
                        self.nextFileInitialBuffer = initialBuffer
                        self.differentFileScheduleTime = gapless_duration
                    } else {
                        self.curPlayerNode.scheduleBuffer(initialBuffer!, at: gapless_duration, options: .init(rawValue: 0), completionHandler: self.fileBuffererCompletion)
                    }
                    
                    let secondsPlayed = Double(self.curPlayerNode.playerTime(forNodeTime: self.curPlayerNode.lastRenderTime!)!.sampleTime) / self.curPlayerNode.lastRenderTime!.sampleRate
                    let delay = ((Double(gapless_duration.sampleTime) / gapless_duration.sampleRate) - secondsPlayed)
                    print("delay set to \(delay)")
                    self.upcomingTrackURL = url
                    let thisChangeEventID = self.changeTrackEventCounter
                    self.changeTrackEventCounter += 1
                    self.currentValidChangeTrackEventID = thisChangeEventID
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                        self.changeTrack(changeEventID: thisChangeEventID)
                    }
                }
            }
        }
    }
    
    func handleCompletion(optionalID: Int?) {
        print("handle completion called")
        switch currentHandlerType {
        case .natural:
            tryGetMoreTracks()
            if networkFlag == true {
                networkFlag = false
                return
            }
            if (currentTrackLocation != nil) {
                print("natural next track")
                setUpNextFile(asyncID: optionalID)
            }
            else {
                print("natural next track, no new tracks")
                let gapless_duration = AVAudioTime(sampleTime: curFile!.length, atRate: curFile!.processingFormat.sampleRate)
                let delay = ((Double(gapless_duration.sampleTime) / gapless_duration.sampleRate) - (Double(curPlayerNode.lastRenderTime!.sampleTime)/(self.curPlayerNode.lastRenderTime?.sampleRate)!))
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
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
            self.lastTrackCompletionType = .natural
        case .seek:
            print("seek completion handler")
            //do nothing
        case .destroy:
            self.lastTrackCompletionType = .skipped
            print("destruction")
            self.total_offset_frames = 0
            self.total_offset_seconds = 0
            self.track_frame_offset = 0
            //do nothing
        }
    }
    
    func skip() {
        tryGetMoreTracks()
        if networkFlag == true {
            currentHandlerType = .natural
            networkFlag = false
            return
        }
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
        if (currentTrackLocation != nil) {
            print("skipping to new track")
            playImmediatelyNoObservers(currentTrackLocation!)
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
    
    func seek(_ frac: Double) {
        guard isSeeking != true else {
            print("is seeking;returning");
            return
        }
        self.isSeeking = true
        var frame = Int64(frac * Double(duration_frames!))
        if frame >= self.duration_frames! {
            frame = duration_frames! - 1
        }
        if frame <= 0 {
            frame = 1
        }
        print("seeking to frame \(frame) of \(duration_frames)")
        track_frame_offset = Double(frame)
        currentHandlerType = .seek
        currentFileBufferer!.seek(to: frame)//can take place on multiple threads, do not set isSeeking to false yet
        //ends up at self.fileBuffererSeekDecodeCallback
    }
    
    func seekCallback() {
        
    }
    
    func resetValues() {
        if (curFile != nil) {
            self.duration_seconds = Double((curFile?.length)!) / (curFile?.processingFormat.sampleRate)!
            self.duration_frames = curFile?.length
        } else if self.currentFileBufferer!.bufferA != nil {
            self.duration_frames = Int64(self.currentFileBufferer!.totalFrames)
            self.duration_seconds = Double(self.duration_frames!) / self.currentFileBufferer!.bufferA.format.sampleRate
        }
    }
    
    
    func play() {
        guard fileManager.fileExists(atPath: URL(string: currentTrackLocation!)!.path) else {return}
        is_paused = false
        if audioEngine.isRunning == true {
            curPlayerNode.play()
        } else {
            audioEngine.prepare()
            do {
                try audioEngine.start()
                curPlayerNode.play()
            } catch {
                print(error)
            }
        }
        if upcomingTrackURL != nil && self.endOfCurrentTrackFrame != nil {
            changeTrack(changeEventID: self.currentValidChangeTrackEventID)
        }
        self.lastRenderedFrame = nil

    }
    func pause() {
        is_paused = true
        self.lastRenderedFrame = self.curPlayerNode.playerTime(forNodeTime: self.curPlayerNode.lastRenderTime!)!.sampleTime
        curPlayerNode.pause()
    }
}
