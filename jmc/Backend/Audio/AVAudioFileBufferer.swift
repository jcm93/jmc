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
    var isCurrentlyDecoding = false
    var needsSeek = false
    var frameToSeekTo: Int64 = 0
    var format: AVAudioFormat
    
    init(file: AVAudioFile, audioModule: AudioModule) {
        self.bufferA = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: bufferFrameLength)!
        self.bufferB = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: bufferFrameLength)!
        self.currentDecodeBuffer = bufferA
        self.audioModule = audioModule
        self.format = file.processingFormat
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
                if self.audioModule.currentFileBufferer! as! AVAudioFileBufferer == self && self.isSeeking != true && self.needsSeek != true && self.isCurrentlyDecoding != true {
                    self.isCurrentlyDecoding = true
                    //print("is currently decoding set to true")
                    try self.file.read(into: self.currentDecodeBuffer, frameCount: self.bufferFrameLength)
                    self.isCurrentlyDecoding = false
                    //print("done decoding")
                    if self.needsSeek == true {
                        //print("calling needs seek callback")
                        self.needsSeekCallback()
                        return
                    }
                    //print("actual reading of file from completion has completed, about to call decode callback")
                    self.lastFrameDecoded += self.bufferFrameLength
                    let lastBuffer = self.lastFrameDecoded >= UInt32(self.file.length)
                    //print("lastBuffer is \(lastBuffer)")
                    self.audioModule.fileBuffererDecodeCallback(isFinalBuffer: lastBuffer)
                }
            } catch {
                self.isCurrentlyDecoding = false
                print(error)
            }
        }
    }
    
    func needsSeekCallback() {
        seek(to: self.frameToSeekTo)
        self.needsSeek = false
    }
    
    func seek(to frame: Int64) {
        self.isSeeking = true
        print("seeking")
        do {
            if self.isCurrentlyDecoding == false {
                print("not currently decoding, co-opting buffer, seeking to frame \(frame) of \(self.totalFrames)")
                self.file.framePosition = frame
                self.lastFrameDecoded = UInt32(frame)
                self.isCurrentlyDecoding = true
                print("is currently decoding set to true seek")
                try self.file.read(into: self.currentDecodeBuffer, frameCount: self.bufferFrameLength)
                self.isCurrentlyDecoding = false
                print("done decoding seek")
                self.isSeeking = false
                self.lastFrameDecoded += self.bufferFrameLength
                let lastBuffer = self.lastFrameDecoded >= UInt32(self.file.length)
                print("lastBuffer is \(lastBuffer)")
                self.audioModule.fileBuffererSeekDecodeCallback(isFinalBuffer: lastBuffer)
                self.audioModule.seekCallback()
            } else {
                print("currently decoding, setting seek break")
                self.needsSeek = true
                self.frameToSeekTo = frame
            }
        } catch {
            self.isCurrentlyDecoding = false
            print(error)
        }
    }
    
    func prepareFirstBuffer() -> AVAudioPCMBuffer? {
        self.currentBufferSampleIndex = 0
        do {
            self.isCurrentlyDecoding = true
            try self.file.read(into: self.currentDecodeBuffer, frameCount: self.bufferFrameLength)
            self.isCurrentlyDecoding = false
            self.lastFrameDecoded += self.bufferFrameLength
            return currentDecodeBuffer
        } catch {
            self.isCurrentlyDecoding = false
            print(error)
        }
        return nil
    }
}
