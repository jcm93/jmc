//
//  FlacDecoder.swift
//  jmc
//
//  Created by John Moody on 2/15/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import AVFoundation

class FlacDecoder: NSObject, FileBufferer {
    
    var decoder: FLAC__StreamDecoder?
    var blockBuffer = [[Float32]]()
    var sampleRate: UInt32?
    var channels: UInt32?
    var bitsPerSample: UInt32?
    var totalFrames: UInt32 = 0
    var file: URL
    var currentBufferSampleIndex: UInt32?
    var currentTrackSampleIndex: UInt32?
    var blockSize: UInt32?
    //uses twin buffers for FLAC decoding, one for playing, and one for filling with the next frames of decoded audio
    var bufferA: AVAudioPCMBuffer = AVAudioPCMBuffer()
    var bufferB: AVAudioPCMBuffer = AVAudioPCMBuffer()
    var currentDecodeBuffer: AVAudioPCMBuffer = AVAudioPCMBuffer()
    var bufferFrameLength: UInt32 = 13
    let NUM_FRAMES_IN_ADVANCE_TO_SCHEDULE_NEXT_FILE: UInt32 = 10
    var audioModule: AudioModule
    var hasScheduled: Bool? = false
    var flac_buffer_frames = 0
    var bufferCurrentlyDecoding = false
    var isSeeking = false
    var backgroundDecoderShouldBreak = false
    var seekGuardCheckThing = false
    var decoderBroke = false
    
    init?(file: URL, audioModule: AudioModule) {
        self.audioModule = audioModule
        self.file = file
    }
    
    func actualInitTest() {
        if createFLACStreamDecoder(file: file) == true {
            FLAC__stream_decoder_process_until_end_of_metadata(&self.decoder!)//populates self.sampleRate, self.channels, self.bitsPerSample
            let format = AVAudioFormat.init(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: Double(self.sampleRate!), channels: self.channels!, interleaved: false)
            print(format.formatDescription)
            self.bufferA = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(self.bufferFrameLength) * self.blockSize!)
            self.bufferA.frameLength = self.bufferA.frameCapacity
            self.bufferB = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(self.bufferFrameLength) * self.blockSize!)
            self.bufferB.frameLength = self.bufferB.frameCapacity
            self.currentDecodeBuffer = self.bufferA
        }
    }
    
    
    let flacWriteCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafePointer<FLAC__Frame>>, Optional<UnsafePointer<Optional<UnsafePointer<Int32>>>>, Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderWriteStatus = {
        (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, frame: Optional<UnsafePointer<FLAC__Frame>>, buffer: Optional<UnsafePointer<Optional<UnsafePointer<Int32>>>>, client_data: Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderWriteStatus in
        
        let flacDecoder = Unmanaged<FlacDecoder>.fromOpaque(client_data!).takeUnretainedValue() 
        if flacDecoder.currentBufferSampleIndex == nil {
            flacDecoder.currentBufferSampleIndex = 0
        }
        if flacDecoder.currentTrackSampleIndex == nil {
            flacDecoder.currentTrackSampleIndex = 0
        }
        
        let numSamples = frame!.pointee.header.blocksize
        let numChannels = frame!.pointee.header.channels
        let one: UInt32 = 1
        let scaleFactor =  Float32(one << ((((frame!.pointee.header.bits_per_sample + 7) / 8) * 8) - 1))
        
        for sample in 0..<numSamples {
            for chan in 0..<numChannels {
                guard flacDecoder.backgroundDecoderShouldBreak != true else {print("bailing out");flacDecoder.backgroundDecoderDidBreak();return FLAC__STREAM_DECODER_WRITE_STATUS_CONTINUE}
                let value = Float32(buffer![Int(chan)]![Int(sample)]) / scaleFactor
                if flacDecoder.seekGuardCheckThing != true {
                    flacDecoder.currentDecodeBuffer.floatChannelData![Int(chan)][Int(flacDecoder.currentBufferSampleIndex!)] = value
                }
            }
            flacDecoder.currentBufferSampleIndex! += 1
            flacDecoder.currentTrackSampleIndex! += 1
        }
        return FLAC__STREAM_DECODER_WRITE_STATUS_CONTINUE
    }
    
    let flacMetadataCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafePointer<FLAC__StreamMetadata>>, Optional<UnsafeMutableRawPointer>) -> () = {
        (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, metadata: Optional<UnsafePointer<FLAC__StreamMetadata>>, client_data: Optional<UnsafeMutableRawPointer>) in
        let flacDecoder = Unmanaged<FlacDecoder>.fromOpaque(client_data!).takeUnretainedValue()
        let meta = metadata!.pointee
        switch meta.type {
        case FLAC__METADATA_TYPE_STREAMINFO:
            flacDecoder.channels = meta.data.stream_info.channels
            flacDecoder.sampleRate = meta.data.stream_info.sample_rate
            flacDecoder.bitsPerSample = meta.data.stream_info.bits_per_sample
            print("max block size \(meta.data.stream_info.max_blocksize)")
            print("min block sie \(meta.data.stream_info.min_blocksize)")
            flacDecoder.blockSize = meta.data.stream_info.max_blocksize
            print("bits per sample \(flacDecoder.bitsPerSample!)")
            flacDecoder.totalFrames = UInt32(meta.data.stream_info.total_samples)
            for chan in 0..<flacDecoder.channels! {
                flacDecoder.blockBuffer.append([Float32]())
            }
        default:
            print("doingus")
        }
    }
    
    func seek(to frame: Int64) {
        self.isSeeking = true
        self.seekGuardCheckThing = true
        FLAC__stream_decoder_seek_absolute(&self.decoder!, FLAC__uint64(frame))
        self.seekGuardCheckThing = false
        self.currentTrackSampleIndex = UInt32(frame)
        if self.bufferCurrentlyDecoding == true {
            print("buffer currently decoding, setting break")
            self.backgroundDecoderShouldBreak = true
        } else {
            print("buffer not currently decoding, proceeding directly to co-opt decode buffer")
            fillNextBufferSynchronously()
            self.isSeeking = false
        }
    }
    
    func backgroundDecoderDidBreak() {
        print("background decoder broke, filling next buffer synchronously")
        self.backgroundDecoderShouldBreak = false
        self.decoderBroke = true
        self.fillNextBufferSynchronously()
        self.isSeeking = false
    }
    
    let flacErrorCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, FLAC__StreamDecoderErrorStatus, Optional<UnsafeMutableRawPointer>) -> () = {
        (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, status: FLAC__StreamDecoderErrorStatus, client_data: Optional<UnsafeMutableRawPointer>) in
        print("error called")
        print(status)
        
    }
    
    func fillNextBufferSynchronously() {
        self.currentBufferSampleIndex = 0
        //do not swap decode buffer
        DispatchQueue.main.async {
            self.bufferCurrentlyDecoding = true
            for _ in 1...self.bufferFrameLength {
                FLAC__stream_decoder_process_single(&self.decoder!)
            }
            self.bufferCurrentlyDecoding = false
            let finalBuffer = self.currentTrackSampleIndex! >= self.totalFrames
            //must be responsible for moderating frame length
            if finalBuffer {
                self.currentDecodeBuffer.frameLength = self.currentBufferSampleIndex!
            }
            self.audioModule.fileBuffererSeekDecodeCallback(isFinalBuffer: finalBuffer)
        }
    }
    
    func fillNextBuffer() {
        self.currentBufferSampleIndex = 0
        //swap decode buffer
        self.currentDecodeBuffer = self.currentDecodeBuffer == self.bufferA ? self.bufferB : self.bufferA
        DispatchQueue.global(qos: .default).async {
            self.bufferCurrentlyDecoding = true
            for _ in 1...self.bufferFrameLength {
                if self.decoderBroke != true && self.isSeeking != true {
                    FLAC__stream_decoder_process_single(&self.decoder!)
                } else {
                    self.decoderBroke = false
                    self.bufferCurrentlyDecoding = false
                    return
                }
            }
            self.decoderBroke = false
            self.bufferCurrentlyDecoding = false
            let finalBuffer = self.currentTrackSampleIndex! >= self.totalFrames
            //must be responsible for moderating frame length
            if finalBuffer {
                self.currentDecodeBuffer.frameLength = self.currentBufferSampleIndex!
            }
            self.audioModule.fileBuffererDecodeCallback(isFinalBuffer: finalBuffer)
        }
    }
    
    func createFLACStreamDecoder(file: URL) -> Bool {
        let flacStreamDecoder = FLAC__stream_decoder_new()
        self.decoder = flacStreamDecoder?.pointee
        FLAC__stream_decoder_set_metadata_respond(flacStreamDecoder, FLAC__METADATA_TYPE_VORBIS_COMMENT)
        FLAC__stream_decoder_set_metadata_respond(flacStreamDecoder, FLAC__METADATA_TYPE_PICTURE)
        let pointerToSelf = Unmanaged.passRetained(self).toOpaque()
        let initResult = FLAC__stream_decoder_init_file(flacStreamDecoder, file.path, flacWriteCallback, flacMetadataCallback, flacErrorCallback, pointerToSelf)
        if initResult == FLAC__STREAM_DECODER_INIT_STATUS_OK {
            return true
        } else {
            print(initResult)
            return false
        }
    }
    
    func prepareFirstBuffer() -> AVAudioPCMBuffer? {
        self.currentBufferSampleIndex = 0
        self.bufferCurrentlyDecoding = true
        for _ in 1...self.bufferFrameLength {
            FLAC__stream_decoder_process_single(&self.decoder!)
        }
        self.bufferCurrentlyDecoding = false
        return self.currentDecodeBuffer
    }
}
