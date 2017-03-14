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
    var currentSampleIndex: UInt32?
    
    let flacWriteCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafePointer<FLAC__Frame>>, Optional<UnsafePointer<Optional<UnsafePointer<Int32>>>>, Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderWriteStatus = {
        (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, frame: Optional<UnsafePointer<FLAC__Frame>>, buffer: Optional<UnsafePointer<Optional<UnsafePointer<Int32>>>>, client_data: Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderWriteStatus in
        
        let flacDecoder = Unmanaged<FlacDecoder>.fromOpaque(client_data!).takeUnretainedValue()
        
        let numSamples = frame!.pointee.header.blocksize
        let numChannels = frame!.pointee.header.channels
        let one: UInt32 = 1
        let scaleFactor =  Float32(one << ((((frame!.pointee.header.bits_per_sample + 7) / 8) * 8) - 1))
        
        for sample in 0..<numSamples {
            for chan in 0..<numChannels {
                let value = Float32(buffer![Int(chan)]![Int(sample)]) / scaleFactor
                flacDecoder.blockBuffer[Int(chan)].append(value)
            }
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
            print("bits per sample \(flacDecoder.bitsPerSample!)")
            flacDecoder.totalFrames = meta.data.stream_info.total_samples
            for chan in 0..<flacDecoder.channels! {
                flacDecoder.blockBuffer.append([Float32]())
            }
        default:
            print("doingus")
        }
        
        
    }
    
    let flacErrorCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, FLAC__StreamDecoderErrorStatus, Optional<UnsafeMutableRawPointer>) -> () = {
        (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, status: FLAC__StreamDecoderErrorStatus, client_data: Optional<UnsafeMutableRawPointer>) in
        
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
    
    func readFLAC(file: URL) -> AVAudioPCMBuffer? {
        if createFLACStreamDecoder(file: file) == true {
            FLAC__stream_decoder_process_until_end_of_metadata(&self.decoder!)//populates self.sampleRate, self.channels, self.bitsPerSample
            let commonFormat = {() -> AVAudioCommonFormat? in
                if self.bitsPerSample == 16 {
                    return AVAudioCommonFormat.pcmFormatInt16
                } else {
                    return nil
                }
                
            }()
            let format = AVAudioFormat.init(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: Double(self.sampleRate!), channels: self.channels!, interleaved: false)
            print(format.formatDescription)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(self.totalFrames!))
            FLAC__stream_decoder_process_until_end_of_stream(&self.decoder!)
            for sample in 0..<self.blockBuffer[0].count {
                for channel in 0..<self.channels! {
                    buffer.floatChannelData![Int(channel)][Int(sample)] = self.blockBuffer[Int(channel)][Int(sample)]
                }
            }
            buffer.frameLength = buffer.frameCapacity
            return buffer
        } else {
            print("failure")
            return nil
        }
    }
}
