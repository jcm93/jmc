//
//  ImageCollectionViewItem.swift
//  jmc
//
//  Created by John Moody on 5/16/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class ImageCollectionViewItem: NSCollectionViewItem {
    
    
    @IBOutlet weak var viewContainingElements: NSView!
    @IBOutlet weak var shadowView: NSView!
    var imageURL: URL?
    
    override var isSelected: Bool {
        didSet {
            view.layer?.backgroundColor = isSelected ? NSColor.selectedMenuItemColor.cgColor : NSColor.clear.cgColor
            view.layer?.cornerRadius = 8.0
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        shadowView?.wantsLayer = true
        shadowView.layer?.shadowOpacity = 0.8
        shadowView.layer?.shadowRadius = 5.0
        shadowView.layer?.shadowColor = NSColor.black.cgColor
        imageView?.wantsLayer = true
        textField?.isEditable = true
        viewContainingElements.wantsLayer = true
        viewContainingElements.layer?.cornerRadius = 7.0
        viewContainingElements.layer?.backgroundColor = NSColor.lightGray.cgColor
    }
    
}
