//
//  JMPlayer.swift
//  jmc
//
//  Created by John Moody on 1/14/22.
//  Copyright © 2022 John Moody. All rights reserved.
//

import Cocoa
import AVFoundation

class JMPlayer: AVQueuePlayer {
    
    var isPlayingNetworkTrack: Bool = false
    
    //player that behaves like AVQueuePlayer from the outside but might instead be interfacing with MusicKitPlayer to access Apple Music tracks
    
    //does this make sense? pause could be synchronous or async
    //whats the best way to organize this

}
