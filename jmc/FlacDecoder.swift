//
//  FlacDecoder.swift
//  jmc
//
//  Created by John Moody on 2/15/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation

class FlacDecoder {
    var decoder: FLAC__StreamDecoder?
    var blockBuffer: UnsafeMutableRawPointer?
    
    private var my_client_data = 0
    
    
    let flacReadCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafeMutablePointer<UInt8>>, Optional<UnsafeMutablePointer<Int>>, Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderReadStatus = { (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, blockBuffer: Optional<UnsafeMutablePointer<UInt8>>, bytes: Optional<UnsafeMutablePointer<Int>>, client_data: Optional<UnsafeMutableRawPointer>) -> FLAC__StreamDecoderReadStatus in
        
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
        
    }
    
    let flacMetadataCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, Optional<UnsafePointer<FLAC__StreamMetadata>>, Optional<UnsafeMutableRawPointer>) -> () = {
        (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, metadata: Optional<UnsafePointer<FLAC__StreamMetadata>>, client_data: Optional<UnsafeMutableRawPointer>) in
        
    }
    
    let flacErrorCallback: @convention(c) (Optional<UnsafePointer<FLAC__StreamDecoder>>, FLAC__StreamDecoderErrorStatus, Optional<UnsafeMutableRawPointer>) -> () = {
        (decoder: Optional<UnsafePointer<FLAC__StreamDecoder>>, status: FLAC__StreamDecoderErrorStatus, client_data: Optional<UnsafeMutableRawPointer>) in
        
    }
    
    func createFLACStreamDecoder(file: URL) {
        let flacStreamDecoder = FLAC__stream_decoder_new()
        FLAC__stream_decoder_set_metadata_respond(flacStreamDecoder, FLAC__METADATA_TYPE_VORBIS_COMMENT)
        FLAC__stream_decoder_set_metadata_respond(flacStreamDecoder, FLAC__METADATA_TYPE_PICTURE)
        
        if FLAC__stream_decoder_init_stream(flacStreamDecoder, flacReadCallback, flacSeekCallback, flacTellCallback, flacLengthCallback, flacEOFCallback, flacWriteCallback, flacMetadataCallback, flacErrorCallback, &my_client_data) != FLAC__STREAM_DECODER_INIT_STATUS_OK {
            
        }
        FLAC__stream_decoder_process_until_end_of_metadata(flacStreamDecoder)
    }
    
    func readFLACAudio(buffer: Optional<UnsafeMutableRawPointer>, frames: UInt32) -> Int {
        var framesRead = 0
        var bytesPerFrame = bitsPerSample/8 * channels
        while (framesRead < frames) {
            
        }
    }
}
