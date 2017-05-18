//
//  ImageCollectionViewItem.swift
//  jmc
//
//  Created by John Moody on 5/16/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class ImageCollectionViewItem: NSCollectionViewItem {
    
    override var isSelected: Bool {
        didSet {
            view.layer?.borderWidth = isSelected ? 5.0 : 0.0
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.borderColor = NSColor.gray.cgColor
        view.layer?.borderWidth = 0.0
    }
    
}
