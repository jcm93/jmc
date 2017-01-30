//
//  AlbumArtArrayController.swift
//  minimalTunes
//
//  Created by John Moody on 7/19/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

/*class AlbumArtArrayController: NSArrayController, NSCollectionViewDataSource {
    
    var artSet: AlbumArtworkCollection?
    
    func numberOfSectionsInCollectionView(collectionView: NSCollectionView) -> Int {
        return 1
    }
    func collectionView(collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if artSet != nil {
            return artSet!.art!.count
        }
        else {
            return 0
        }
    }
    /*func collectionView(collectionView: NSCollectionView, itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath) -> NSCollectionViewItem {
        let index = indexPath.indexAtPosition(indexPath.length - 1)
        let artArray = artSet!.art!.mutableCopy().array as! [AlbumArtwork]
        let collectionViewItem = NSCollectionViewItem()
        let image = NSImage(contentsOfFile: artArray[index].artwork_location as! String)
        let viewItem = collectionView.makeItemWithIdentifier(<#T##identifier: String##String#>, forIndexPath: <#T##NSIndexPath#>)
    }*/

}*/
