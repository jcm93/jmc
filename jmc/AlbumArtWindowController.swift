//
//  AlbumArtWindowController.swift
//  jmc
//
//  Created by John Moody on 5/18/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class AlbumArtWindowController: NSWindowController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    
    @IBOutlet weak var otherArtBox: NSBox!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var collectionView: NSCollectionView!
    
    var track: Track?
    var otherArtImages = [NSImage]()
    var timer: Timer?
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return otherArtImages.count
    }
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let view = collectionView.makeItem(withIdentifier: "image", for: indexPath)
        let index = indexPath.last
        view.imageView!.image = otherArtImages[index!]
        return view
    }
    
    override func mouseMoved(with event: NSEvent) {
        if self.timer != nil {
            self.timer?.invalidate()
        }
        self.window!.standardWindowButton(.closeButton)!.superview!.animator().alphaValue = 1
        self.timer = Timer.scheduledTimer(timeInterval: 0.9, target: self, selector: #selector(fadeOutTitleBar), userInfo: nil, repeats: false)
    }
    
    override func mouseExited(with event: NSEvent) {
        fadeOutTitleBar()
    }
    
    func fadeOutTitleBar() {
        self.window!.standardWindowButton(.closeButton)!.superview!.animator().alphaValue = 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, shouldSelectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath> {
        print("should select items called")
        if indexPaths.count == 1 {
            print("initialzing new primary image")
            let viewItem = collectionView.item(at: indexPaths.first!)
            self.imageView.image = viewItem!.imageView!.image!
            //self.initializePrimaryImage()
        }
        return indexPaths
    }
    
    func collectionView(_ collectionView: NSCollectionView, shouldChangeItemsAt indexPaths: Set<IndexPath>, to highlightState: NSCollectionViewItemHighlightState) -> Set<IndexPath> {
        print("should change items called")
        return indexPaths
    }
    
    func initializePrimaryImage() {
        let aspectRatio = imageView.image!.size.height / imageView.image!.size.width
        let constraint = self.imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: aspectRatio)
        let otherConstraint = NSLayoutConstraint(item: self.imageView, attribute: .width, relatedBy: .equal, toItem: self.window!.contentView, attribute: .width, multiplier: 1.0, constant: 0.0)
        NSLayoutConstraint.activate([constraint, otherConstraint])
    }
    

    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.register(ImageCollectionViewItem.self, forItemWithIdentifier: "image")
        self.collectionView.wantsLayer = true
        //self.collectionView.layer?.backgroundColor = NSColor.gray.cgColor
        let trackingArea = NSTrackingArea(rect: self.window!.frame, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited, .mouseMoved], owner: self, userInfo: nil)
        self.window?.contentView?.addTrackingArea(trackingArea)
        self.window?.isMovableByWindowBackground = true

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        if let album = track?.album {
            self.window?.title = album.name!
            if let primaryArt = album.primary_art {
                let imageURL = URL(string: primaryArt.artwork_location!)!
                let image = NSImage(byReferencing: imageURL)
                self.imageView.image = image
                self.otherArtImages.append(image)
                initializePrimaryImage()
            }
            
            if let otherArt = album.other_art, otherArt.count > 0 {
                print("other art count nonzero")
                otherArtBox.isHidden = false
                for thing in otherArt {
                    let art = thing as! AlbumArtwork
                    let imageURL = URL(string: art.artwork_location!)!
                    let image = NSImage(byReferencing: imageURL)
                    otherArtImages.append(image)
                }
                collectionView.reloadData()
            } else {
                otherArtBox.isHidden = true
            }
        }
    }
    
}
