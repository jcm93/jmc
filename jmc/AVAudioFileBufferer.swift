//
//  AVAudioFileBufferer.swift
//  jmc
//
//  Created by John Moody on 3/16/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa
import AVFoundation

class AVAudioFileBufferer: NSObject, FileBufferer {
    
    var bufferA: AVAudioPCMBuffer
    var bufferB: AVAudioPCMBuffer
    var currentDecodeBuffer: AVAudioPCMBuffer
    var bufferFrameLength: UInt32 = 90000
    var file: AVAudioFile
    var currentBufferSampleIndex = 0
    var lastFrameDecoded: UInt32 = 0
    var totalFrames: UInt32
    var audioModule: AudioModule
    var isSeeking = false
    
    init(file: AVAudioFile, audioModule: AudioModule) {
        self.bufferA = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: bufferFrameLength)
        self.bufferB = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: bufferFrameLength)
        self.currentDecodeBuffer = bufferA
        self.audioModule = audioModule
        self.file = file
        self.totalFrames = UInt32(file.length)
    }
    
    func fillNextBuffer() {
        //swap decode buffer
        self.currentBufferSampleIndex = 0
        self.currentDecodeBuffer = self.currentDecodeBuffer == self.bufferA ? self.bufferB : self.bufferA
        DispatchQueue.global(qos: .default).async {
            do {
                //determine if final buffer
                if self.audioModule.currentFileBufferer! as! AVAudioFileBufferer == self && self.isSeeking != true {
                    try self.file.read(into: self.currentDecodeBuffer, frameCount: self.bufferFrameLength)
                    print("actual reading of file from completion has completed, about to call decode callback")
                    self.lastFrameDecoded += self.bufferFrameLength
                    let lastBuffer = self.lastFrameDecoded >= UInt32(self.file.length)
                    self.audioModule.fileBuffererDecodeCallback(isFinalBuffer: lastBuffer)
                }
            } catch {
                print(error)
            }
        }
    }
    
    func seek(to frame: Int64) {
        self.isSeeking = true
        do {
            let url = self.file.url
            self.bufferA = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: bufferFrameLength)
            self.bufferB = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: bufferFrameLength)
            self.currentDecodeBuffer = bufferA
            self.file = try AVAudioFile(forReading: url)
            self.totalFrames = UInt32(file.length)
            self.currentBufferSampleIndex = 0
            self.file.framePosition = frame
            try self.file.read(into: self.currentDecodeBuffer, frameCount: self.bufferFrameLength)
            self.lastFrameDecoded = UInt32(frame)
            let lastBuffer = self.lastFrameDecoded >= UInt32(self.file.length)
            self.audioModule.fileBuffererSeekDecodeCallback(isFinalBuffer: lastBuffer)
        } catch {
            print(error)
        }
        self.isSeeking = false
    }
    
    func prepareFirstBuffer() -> AVAudioPCMBuffer? {
        self.currentBufferSampleIndex = 0
        self.currentDecodeBuffer = self.currentDecodeBuffer == self.bufferA ? self.bufferB : self.bufferA
        do {
            try self.file.read(into: self.currentDecodeBuffer, frameCount: self.bufferFrameLength)
            self.lastFrameDecoded += self.bufferFrameLength
            return currentDecodeBuffer
        } catch {
            print(error)
        }
        return nil
    }
}
