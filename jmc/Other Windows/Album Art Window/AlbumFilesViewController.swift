//
//  AlbumArtViewController.swift
//  jmc
//
//  Created by John Moody on 6/26/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa
import Quartz

class AlbumFilesViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    
    @IBOutlet var textViewScrollView: NSScrollView!
    @IBOutlet weak var targetView: NSView!
    @IBOutlet weak var boxView: NSView!
    @IBOutlet weak var otherArtBox: NSBox!
    @IBOutlet var imageView: AlbumArtImageView!
    @IBOutlet weak var collectionView: AlbumArtCollectionView!
    @IBOutlet var pdfViewer: AlbumArtPDFView!
    @IBOutlet var textView: NSTextView!
    
    var track: Track?
    var otherArtImages = [AnyObject]()
    let defaultImageWidthPixels: CGFloat = 500
    var currentActiveView: NSView?
    var windowController: AlbumArtWindowController?
    var initializesPrimaryImageConstraint = true
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return otherArtImages.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let index = indexPath.last
        if let artImage = otherArtImages[index!] as? AlbumArtwork {
            let view = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "image"), for: indexPath) as! ImageCollectionViewItem
            let imageURL = URL(string: artImage.location!)
            let image = NSImage(byReferencing: imageURL!)
            view.imageView!.image = image
            view.imageURL = imageURL
            view.textField!.stringValue = artImage.art_name ?? "Art Image"
            view.representedObject = artImage
            return view
        } else {
            let otherFile = otherArtImages[index!] as! AlbumFile
            let view = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "image"), for: indexPath) as! ImageCollectionViewItem
            let fileURL = URL(string: otherFile.location!)
            let size = NSSize(width: 90, height: 100)
            if let unmanagedImage = QLThumbnailImageCreate(kCFAllocatorDefault, fileURL! as CFURL, size, [:] as CFDictionary) {
                let image = unmanagedImage.takeUnretainedValue()
                view.imageView!.image = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
            }
            view.imageURL = fileURL
            view.textField?.stringValue = otherFile.file_description ?? "Other File"
            view.representedObject = otherFile
            return view
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
        print("accepting drop")
        if let board = draggingInfo.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray {
            let urls = board.map({return URL(fileURLWithPath: $0 as! String)})
            if let currentTrack = self.track {
                let databaseManager = DatabaseManager()
                var results = [AnyObject]()
                for url in urls {
                    if let urlUTI = getUTIFrom(url: url) {
                        if UTTypeConformsTo(urlUTI as CFString, kUTTypeImage) || UTTypeConformsTo(urlUTI as CFString, kUTTypePDF) {
                            if let result = databaseManager.addArtForTrack(currentTrack, from: url, managedContext: managedContext, organizes: true) {
                                results.append(result)
                                otherArtImages.append(result)
                            }
                        } else {
                            if let result = databaseManager.addMiscellaneousFile(forTrack: currentTrack, from: url, managedContext: managedContext, organizes: true) {
                                results.append(result)
                                otherArtImages.append(result)
                            }
                        }
                    }
                }
                collectionView.reloadData()
                return true
            }
            else {
                return false
            }
        }
        return false
    }
    
    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
        print("validating drop")
        return .every
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
    
    func collectionView(_ collectionView: NSCollectionView, shouldSelectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath> {
        print("should select items called")
        if indexPaths.count == 1 {
            print("initialzing new primary image")
            if let viewItem = collectionView.item(at: indexPaths.first!) as? ImageCollectionViewItem {
                if viewItem.imageURL != nil {
                    changePrimaryImage(imageURL: viewItem.imageURL!)
                }
            }
        }
        return indexPaths
    }
    
    func initializePrimaryImageConstraint() {
        if initializesPrimaryImageConstraint {
            let imageViewConstraints = imageView.constraints
            let heightConstraint = imageViewConstraints.filter({return $0.firstAttribute == .height && $0.secondAttribute == .width})
            NSLayoutConstraint.deactivate(heightConstraint)
            let aspectRatio = imageView.image!.size.height / imageView.image!.size.width
            let constraint = NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: imageView, attribute: .width, multiplier: aspectRatio, constant: 5.0)
            //let otherConstraint = NSLayoutConstraint(item: self.imageView, attribute: .width, relatedBy: .equal, toItem: self.window!.frame, attribute: .width, multiplier: 1.0, constant: 0.0)
            NSLayoutConstraint.activate([constraint])
            imageView.imageScaling = .scaleProportionallyUpOrDown
        }
    }
    
    func addSubviewAndInitializeConstraints(view: NSView) {
        self.targetView.addSubview(view)
        view.leadingAnchor.constraint(equalTo: self.targetView.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: self.targetView.trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: self.targetView.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: self.targetView.bottomAnchor).isActive = true
    }
    
    func changePrimaryImage(imageURL: URL) {
        currentActiveView?.removeFromSuperview()
        if let uti = getUTIFrom(url: imageURL) {
            if UTTypeConformsTo(uti as CFString, kUTTypeText) {
                do {
                    self.textView.string = try String(contentsOf: imageURL)
                    addSubviewAndInitializeConstraints(view: self.textViewScrollView)
                    self.currentActiveView = self.textViewScrollView
                    windowController?.resize(newSize: NSSize(width: 500, height: 500))
                } catch {
                    print(error)
                    return
                }
            } else if UTTypeConformsTo(uti as CFString, kUTTypePDF) {
                let pdfDocument = PDFDocument(url: imageURL)!
                pdfViewer.document = pdfDocument
                addSubviewAndInitializeConstraints(view: pdfViewer)
                self.currentActiveView = pdfViewer
                let width = pdfViewer.documentView!.frame.width
                windowController?.resize(newSize: NSSize(width: width, height: 800.0))
            } else if UTTypeConformsTo(uti as CFString, kUTTypeImage) {
                let image = NSImage(byReferencing: imageURL)
                self.imageView.image = image
                self.imageView.imageScaling = .scaleProportionallyUpOrDown
                addSubviewAndInitializeConstraints(view: self.imageView)
                self.currentActiveView = self.imageView
                let aspectRatio = image.size.height / image.size.width
                let heightAddendum = otherArtImages.count > 1 ? otherArtBox.frame.height : 0
                let newHeight = defaultImageWidthPixels * aspectRatio + heightAddendum
                let newSize = NSSize(width: defaultImageWidthPixels, height: newHeight)
                initializePrimaryImageConstraint()
                windowController?.resize(newSize: newSize)
            }
        }
    }

    func deleteSelection() {
        var selectedObjects = [AnyObject]()
        var indices = [Int]()
        for item in collectionView.selectionIndexPaths {
            indices.append(item.last!)
            let object = otherArtImages[item.last!]
            selectedObjects.append(object)
        }
        collectionView.deleteItems(at: collectionView.selectionIndexPaths)
        for index in indices.sorted().reversed() {
            let item = otherArtImages.remove(at: index)
            if let art = item as? AlbumArtwork {
                if art.album != nil {
                    art.album = nil
                } else if art.album_multiple != nil {
                    art.album_multiple = nil
                }
                managedContext.delete(art)
            } else if let file = item as? AlbumFile {
                file.album = nil
                managedContext.delete(file)
            }
        }
        collectionView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.register(ImageCollectionViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier.init("image"))
        //self.collectionView.register(ImageCollectionViewItem.self, forItemWithIdentifier: "image")
        self.collectionView.wantsLayer = true
        self.collectionView.viewController = self
        self.collectionView.registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeURL as String), NSPasteboard.PasteboardType.filePromise])
        self.collectionView.setDraggingSourceOperationMask(.every, forLocal: true)
        self.collectionView.setDraggingSourceOperationMask(.every, forLocal: false)
        //self.textView.translatesAutoresizingMaskIntoConstraints = false
        //self.textViewScrollView.translatesAutoresizingMaskIntoConstraints = false
        self.otherArtBox.wantsLayer = true
        boxView.wantsLayer = true
        if let album = track?.album {
            var imageURL: URL? = nil
            //window.title = album.name!
            if let primaryArt = album.primary_art {
                imageURL = URL(string: primaryArt.location!)!
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
            }
            if let otherFiles = album.other_files, otherFiles.count > 0 {
                print("other files count nonzero")
                otherArtBox.isHidden = false
                for thing in otherFiles {
                    let file = thing as! AlbumFile
                    otherArtImages.append(file)
                }
                collectionView.reloadData()
            }
            if otherArtImages.count < 2 {
                NSLayoutConstraint.deactivate([targetView.bottomAnchor.constraint(equalTo: otherArtBox.topAnchor)])
                otherArtBox.removeFromSuperview()
                targetView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
                
            }
            if imageURL != nil {
                changePrimaryImage(imageURL: imageURL!)
            }
        }
    }
    
}
