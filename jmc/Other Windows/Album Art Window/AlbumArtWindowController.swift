//
//  AlbumArtWindowController.swift
//  jmc
//
//  Created by John Moody on 5/18/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa
import Quartz

class AlbumArtWindowController: NSWindowController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    
    @IBOutlet weak var boxView: NSView!
    @IBOutlet weak var otherArtBox: NSBox!
    @IBOutlet weak var imageView: AlbumArtImageView!
    @IBOutlet weak var collectionView: AlbumArtCollectionView!
    @IBOutlet weak var pdfViewer: AlbumArtPDFView!
    
    var track: Track?
    var otherArtImages = [AlbumArtwork]()
    var timer: Timer?
    let defaultImageWidthPixels: CGFloat = 500
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return otherArtImages.count
    }
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let view = collectionView.makeItem(withIdentifier: "image", for: indexPath) as! ImageCollectionViewItem
        let index = indexPath.last
        let imageURL = URL(string: otherArtImages[index!].artwork_location!)
        let image = NSImage(byReferencing: imageURL!)
        view.imageView!.image = image
        view.imageURL = imageURL
        view.textField!.stringValue = otherArtImages[index!].art_name ?? "Art Image"
        return view
    }
    
    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, index: Int, dropOperation: NSCollectionViewDropOperation) -> Bool {
        print("accepting drop")
        return true
    }
    
    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndex proposedDropIndex: UnsafeMutablePointer<Int>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionViewDropOperation>) -> NSDragOperation {
        print("validating drop")
        return .move
    }
    
    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool {
        print("can drag items")
        return true
    }
    
    func collectionView(_ collectionView: NSCollectionView, writeItemsAt indexes: IndexSet, to pasteboard: NSPasteboard) -> Bool {
        print("writing ot pasteboard")
        return true
    }
    
    func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        let item = collectionView.item(at: indexPath) as! ImageCollectionViewItem
        return item.imageURL! as NSURL
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
            let viewItem = collectionView.item(at: indexPaths.first!) as! ImageCollectionViewItem
            changePrimaryImage(imageURL: viewItem.imageURL!)
        }
        return indexPaths
    }
    
    func collectionView(_ collectionView: NSCollectionView, shouldChangeItemsAt indexPaths: Set<IndexPath>, to highlightState: NSCollectionViewItemHighlightState) -> Set<IndexPath> {
        print("should change items called")
        return indexPaths
    }
    
    func initializePrimaryImageConstraint() {
        let imageViewConstraints = imageView.constraints
        let heightConstraint = imageViewConstraints.filter({return $0.firstAttribute == .height && $0.secondAttribute == .width})
        NSLayoutConstraint.deactivate(heightConstraint)
        let aspectRatio = imageView.image!.size.height / imageView.image!.size.width
        let constraint = NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: imageView, attribute: .width, multiplier: aspectRatio, constant: 5.0)
        //let otherConstraint = NSLayoutConstraint(item: self.imageView, attribute: .width, relatedBy: .equal, toItem: self.window!.frame, attribute: .width, multiplier: 1.0, constant: 0.0)
        NSLayoutConstraint.activate([constraint])
        imageView.imageScaling = .scaleProportionallyUpOrDown
        
    }
    
    func changePrimaryImage(imageURL: URL) {
        if UTTypeConformsTo(getUTIFrom(url: imageURL)!, kUTTypePDF) {
            let pdfDocument = PDFDocument(url: imageURL)!
            pdfViewer.document = pdfDocument
            self.imageView.isHidden = true
            self.pdfViewer.isHidden = false
            let width = pdfViewer.documentView!.frame.width
            let height = pdfViewer.documentView!.frame.height / CGFloat(pdfDocument.pageCount)
            let newRect = NSRect(x: window!.frame.origin.x, y: window!.frame.origin.y, width: width, height: 800)
            self.window!.animator().setFrame(newRect, display: true)
        } else {
            let image = NSImage(byReferencing: imageURL)
            self.imageView.image = image
            self.imageView.imageScaling = .scaleProportionallyUpOrDown
            self.pdfViewer.isHidden = true
            self.imageView.isHidden = false
            let aspectRatio = image.size.height / image.size.width
            let heightAddendum = otherArtImages.count > 1 ? otherArtBox.frame.height : 0
            let newHeight = defaultImageWidthPixels * aspectRatio + heightAddendum
            let newRect = NSRect(x: window!.frame.origin.x, y: window!.frame.origin.y, width: defaultImageWidthPixels, height: newHeight)
            initializePrimaryImageConstraint()
            print("resizing to \(newRect)")
            self.window!.animator().setFrame(newRect, display: true)
        }
    }
    

    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.register(ImageCollectionViewItem.self, forItemWithIdentifier: "image")
        self.collectionView.wantsLayer = true
        self.collectionView.register(forDraggedTypes: [NSURLPboardType])
        self.collectionView.setDraggingSourceOperationMask(.every, forLocal: true)
        self.collectionView.setDraggingSourceOperationMask(.every, forLocal: false)
        let trackingArea = NSTrackingArea(rect: self.window!.frame, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited, .mouseMoved], owner: self, userInfo: nil)
        self.otherArtBox.wantsLayer = true
        boxView.wantsLayer = true
        self.window?.contentView?.addTrackingArea(trackingArea)
        //self.window?.contentView?.translatesAutoresizingMaskIntoConstraints = false
        self.window?.isMovableByWindowBackground = true

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        if let album = track?.album {
            var imageURL: URL? = nil
            self.window?.title = album.name!
            if let primaryArt = album.primary_art {
                imageURL = URL(string: primaryArt.artwork_location!)!
                self.otherArtImages.append(primaryArt)
            }
            if let otherArt = album.other_art, otherArt.count > 0 {
                print("other art count nonzero")
                otherArtBox.isHidden = false
                for thing in otherArt {
                    let art = thing as! AlbumArtwork
                    otherArtImages.append(art)
                }
                collectionView.reloadData()
            } else {
                otherArtBox.isHidden = true
            }
            if imageURL != nil {
                changePrimaryImage(imageURL: imageURL!)
                initializePrimaryImageConstraint()
            }
        }
    }
    
}
