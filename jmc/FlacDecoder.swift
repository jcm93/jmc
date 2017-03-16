//
//  FlacDecoder.swift
//  jmc
//
//  Created by John Moody on 2/15/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import AVFoundation

class FlacDecoder {
    
    var decoder: FLAC__StreamDecoder?
    var blockBuffer = [[Float32]]()
    var sampleRate: UInt32?
    var channels: UInt32?
    var bitsPerSample: UInt32?
    var totalFrames: UInt64?
    var currentBufferSampleIndex: UInt32?
    var currentTrackSampleIndex: UInt32?
    var blockSize: UInt32?
    //uses twin buffers for FLAC decoding, one for playing, and one for filling with the next frames of decoded audio
    var bufferA: AVAudioPCMBuffer?
    var bufferB: AVAudioPCMBuffer?
    var currentDecodeBuffer: AVAudioPCMBuffer?
    let FLAC_DECODER_TWIN_BUFFER_NUM_FRAMES: UInt32 = 15
    let NUM_FRAMES_IN_ADVANCE_TO_SCHEDULE_NEXT_FILE: UInt32 = 10
    var audioModule: AudioModule?
    var hasScheduled: Bool? = false
    
    
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
                let value = Float32(buffer![Int(chan)]![Int(sample)]) / scaleFactor
                flacDecoder.currentDecodeBuffer!.floatChannelData![Int(chan)][Int(flacDecoder.currentBufferSampleIndex!)] = value
            }
            flacDecoder.currentBufferSampleIndex! += 1
            flacDecoder.currentTrackSampleIndex! += 1
        }
        if flacDecoder.currentTrackSampleIndex! >= (UInt32(flacDecoder.totalFrames!) - flacDecoder.NUM_FRAMES_IN_ADVANCE_TO_SCHEDULE_NEXT_FILE * flacDecoder.blockSize!) && flacDecoder.hasScheduled != true {
            print("getting ready to schedule next file")
            flacDecoder.audioModule!.completionTest()
            flacDecoder.hasScheduled = true
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
            flacDecoder.totalFrames = meta.data.stream_info.total_samples
            for chan in 0..<flacDecoder.channels! {
                flacDecoder.blockBuffer.append([Float32]())
            }
        default:
            print("doingus")
        }
    }
    
    func seek(point: Float) {
        let frame = UInt64((point / 100) * Float(self.totalFrames!))
        FLAC__stream_decoder_seek_absolute(&self.decoder!, frame)
    }
    
    let flacErrorCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, FLAC__StreamDecoderErrorStatus, Optional<UnsafeMutableRawPointer>) -> () = {
        (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, status: FLAC__StreamDecoderErrorStatus, client_data: Optional<UnsafeMutableRawPointer>) in
        print("error called")
        print(status)
        
    }
    
    func fillNextBuffer() {
        //swap decode buffer
        self.currentBufferSampleIndex = 0
        self.currentDecodeBuffer = self.currentDecodeBuffer == self.bufferA ? self.bufferB : self.bufferA
        DispatchQueue.global(qos: .default).async {
            for _ in 1...self.FLAC_DECODER_TWIN_BUFFER_NUM_FRAMES {
                FLAC__stream_decoder_process_single(&self.decoder!)
            }
            if UInt64(self.currentTrackSampleIndex!) >= self.totalFrames! {
                self.currentDecodeBuffer?.frameLength = (UInt32(self.totalFrames!) % self.currentDecodeBuffer!.frameLength)
                print("last decoded sample index: \(self.currentTrackSampleIndex!), total number of frames: \(self.totalFrames!)")
            }
            self.audioModule!.flacBufferDecodeCallback()
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
            FLAC__stream_decoder_process_until_end_of_metadata(flacStreamDecoder)
            return true
        } else {
            print(initResult)
            return false
        }
    }
    
    func readFLAC(file: URL) -> Bool {
        if createFLACStreamDecoder(file: file) == true {
            FLAC__stream_decoder_process_until_end_of_metadata(&self.decoder!)//populates self.sampleRate, self.channels, self.bitsPerSample
            let format = AVAudioFormat.init(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: Double(self.sampleRate!), channels: self.channels!, interleaved: false)
            print(format.formatDescription)
            self.bufferA = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(self.FLAC_DECODER_TWIN_BUFFER_NUM_FRAMES) * self.blockSize!)
            self.bufferA!.frameLength = self.bufferA!.frameCapacity
            self.bufferB = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(self.FLAC_DECODER_TWIN_BUFFER_NUM_FRAMES) * self.blockSize!)
            self.bufferB!.frameLength = self.bufferB!.frameCapacity
            self.currentDecodeBuffer = self.bufferA
            for i in 1...FLAC_DECODER_TWIN_BUFFER_NUM_FRAMES {
                FLAC__stream_decoder_process_single(&self.decoder!)
            }
            DispatchQueue.global(qos: .default).async {
                self.fillNextBuffer()
            }
            return true
        } else {
            print("failure")
            return false
        }
    }
}
