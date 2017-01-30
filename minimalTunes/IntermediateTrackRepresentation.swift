//
//  IntermediateTrackRepresentation.swift
//  minimalTunes
//
//  Created by John Moody on 12/7/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class IntermediateTrackRepresentation: NSObject {
    
    init(tv: Track) {
        self.track = tv
    }
    
    var track: Track
    
    var artist: String? {
        if track.sort_artist != nil {
            return track.sort_artist
        } else {
            return track.artist?.name
        }
    }
    
    var album: String? {
        if track.sort_album != nil {
            return track.sort_album
        } else {
            return track.album?.name
        }
    }
    
}
