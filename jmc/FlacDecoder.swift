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
    var blockBuffer = [Int32]()
    
    private var my_client_data = 0
    
    
    let flacReadCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafeMutablePointer<UInt8>>, Optional<UnsafeMutablePointer<Int>>, Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderReadStatus = { (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, blockBuffer: Optional<UnsafeMutablePointer<UInt8>>, bytes: Optional<UnsafeMutablePointer<Int>>, client_data: Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderReadStatus in
        print("flac read callback")
        return FLAC__STREAM_DECODER_READ_STATUS_CONTINUE
    }
    
    let flacSeekCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, UInt64, Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderSeekStatus = { (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, absolute_byte_offset: UInt64, client_data: Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderSeekStatus in
    }
    
    let flacTellCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafeMutablePointer<UInt64>>, Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderTellStatus = { (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, absolute_byte_offset: Optional<UnsafeMutablePointer<UInt64>>, client_data: Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderTellStatus in
        
    }
    
    let flacEOFCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafeMutableRawPointer>) -> Int32 = { (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, client_data: Optional<UnsafeMutableRawPointer>) -> Int32 in
        
        
    }
    
    let flacLengthCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafeMutablePointer<UInt64>>, Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderLengthStatus = { (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, stream_length: Optional<UnsafeMutablePointer<UInt64>>, client_data: Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderLengthStatus in
        
    }
    
    let flacWriteCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafePointer<FLAC__Frame>>, Optional<UnsafePointer<Optional<UnsafePointer<Int32>>>>, Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderWriteStatus = {
        (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, frame: Optional<UnsafePointer<FLAC__Frame>>, buffer: Optional<UnsafePointer<Optional<UnsafePointer<Int32>>>>, client_data: Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderWriteStatus in
        
        let flacDecoder = Unmanaged<FlacDecoder>.fromOpaque(client_data!).takeUnretainedValue()
        let blockBuffer = flacDecoder.blockBuffer
        
        let numSamples = frame!.pointee.header.blocksize
        let numChannels = frame!.pointee.header.channels
        for sampleIndex in 0...numSamples {
            for channelIndex in 0...numChannels {
                blockBuffer.append(buffer![channelIndex]![sampleIndex])
            }
        }
        return FLAC__STREAM_DECODER_WRITE_STATUS_CONTINUE
    }
    
    let flacMetadataCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafePointer<FLAC__StreamMetadata>>, Optional<UnsafeMutableRawPointer>) -> () = {
        (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, metadata: Optional<UnsafePointer<FLAC__StreamMetadata>>, client_data: Optional<UnsafeMutableRawPointer>) in
        
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
    
    func readFLAC(file: URL) -> NSData? {
        if createFLACStreamDecoder(file: file) == true {
            FLAC__stream_decoder_process_until_end_of_stream(&self.decoder!)
            let buffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat.init(commonFormat: AVAudioCommonFormat.pcmFormatInt32, sampleRate: <#T##Double#>, channels: <#T##AVAudioChannelCount#>, interleaved: <#T##Bool#>), frameCapacity: <#T##AVAudioFrameCount#>)
        } else {
            print("failure")
            return nil
        }
        
    }
}
