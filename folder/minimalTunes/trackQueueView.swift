//
//  trackQueueView.swift
//  minimalTunes
//
//  Created by John Moody on 6/23/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

enum TrackQueueViewType {
    case pastTrack
    case currentTrack
    case futureTrack
    case source
}

class TrackQueueView: NSObject {

    var track: Track?
    var source: String?
    var viewType: TrackQueueViewType?
    
}


