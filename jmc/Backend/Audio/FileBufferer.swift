//
//  FileBufferer.swift
//  jmc
//
//  Created by John Moody on 3/16/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import AVFoundation

protocol FileBufferer {
    
    var bufferA: AVAudioPCMBuffer { get set }
    var bufferB: AVAudioPCMBuffer { get set }
    var currentDecodeBuffer: AVAudioPCMBuffer { get set }
    var bufferFrameLength: UInt32 { get set }
    var totalFrames: UInt32 { get set }
    var isSeeking: Bool { get set }
    var format: AVAudioFormat { get set }
    
    func fillNextBuffer() -> Void
    
    func prepareFirstBuffer() -> AVAudioPCMBuffer?
    
    func seek(to frame: Int64) -> Void
}
