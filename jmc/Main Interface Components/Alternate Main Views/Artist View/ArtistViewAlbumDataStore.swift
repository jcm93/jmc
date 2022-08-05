//
//  ArtistViewAlbumDataStorage.swift
//  jmc
//
//  Created by John Moody on 8/5/22.
//  Copyright © 2022 John Moody. All rights reserved.
//

import Cocoa

class ArtistViewAlbumDataStore: NSObject {
    @objc dynamic var selectionIndexes: IndexSet! = IndexSet()
    var album: Album!
    var row: Int!
}
