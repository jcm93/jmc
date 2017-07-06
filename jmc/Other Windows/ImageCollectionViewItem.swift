//
//  ImageCollectionViewItem.swift
//  jmc
//
//  Created by John Moody on 5/16/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class ImageCollectionViewItem: NSCollectionViewItem {
    
    
    @IBOutlet weak var shadowView: NSView!
    var imageURL: URL?
    
    @IBAction func textFieldWasEdited(_ sender: Any) {
        if let object = self.representedObject as? AlbumFile {
            object.file_description = self.textField?.stringValue
        } else if let object = self.representedObject as? AlbumArtwork {
            object.art_name = self.textField?.stringValue
        }
    }
    override var isSelected: Bool {
        didSet {
            view.layer?.backgroundColor = isSelected ? NSColor.selectedMenuItemColor.cgColor : NSColor.clear.cgColor
            self.textField?.textColor = isSelected ? NSColor.white : NSColor.textColor
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
        self.textField?.wantsLayer = false
    }
    
}
