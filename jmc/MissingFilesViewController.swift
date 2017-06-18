//
//  MissingFilesViewController.swift
//  jmc
//
//  Created by John Moody on 6/16/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa


class MissingTrackPathNode: NSObject {
    
    var pathComponent: String
    var children = [MissingTrackPathNode]()
    var parent: MissingTrackPathNode?
    var missingTracks = Set<Track>()
    var totalTracks = Set<Track>()
    
    
    init(pathComponent: String, parent: MissingTrackPathNode? = nil) {
        self.pathComponent = pathComponent
        self.parent = parent
        super.init()
        if parent != nil {
            parent?.children.append(self)
        }
    }
    
    func numberBeneath() -> Int {
        var sum = 0
        for child in self.children {
            sum += child.numberBeneath()
            if child.children.count == 0 {
                sum += 1
            }
        }
        return sum
    }
    
    func completePathRepresentation() -> String {
        var pathComponents = [self.pathComponent]
        var node = self
        while node.parent != nil {
            node = node.parent!
            pathComponents.append(node.pathComponent)
        }
        pathComponents.reverse()
        let path = "/" + pathComponents.filter({$0 != "" && $0 != "/"}).joined(separator: "/")
        return path
    }
}

class MissingTrackPathTree: NSObject {
    
    var rootNode: MissingTrackPathNode
    
    func createNode(with pathComponents: inout [String], under parentOrRoot: MissingTrackPathNode? = nil, with missingTrack: Track) {
        guard pathComponents.count > 0 else { return }
        
        let currentNode = parentOrRoot ?? rootNode
        currentNode.missingTracks.insert(missingTrack)
        
        let nextPathComponent = pathComponents.removeFirst()
        
        if let nextNode = currentNode.children.first(where: {$0.pathComponent == nextPathComponent}) {
            createNode(with: &pathComponents, under: nextNode, with: missingTrack)
        } else {
            let newNode = MissingTrackPathNode(pathComponent: nextPathComponent, parent: currentNode)
            let nextURLString = URL(fileURLWithPath: newNode.completePathRepresentation()).absoluteString
            let setUnderNextNode = Set(currentNode.totalTracks.filter {$0.location?.hasPrefix(nextURLString) ?? false})
            print("creating node with \(pathComponents), total track count \(setUnderNextNode.count)")
            newNode.totalTracks = setUnderNextNode
            if pathComponents.count > 0 {
                createNode(with: &pathComponents, under: newNode, with: missingTrack)
            } else {
                return
            }
        }
    }
    
    init(with missingTracks: [Track]) {
        self.rootNode = MissingTrackPathNode(pathComponent: "/")
        let allTrackSet = globalRootLibrary!.tracks as! Set<Track>
        self.rootNode.totalTracks = allTrackSet
        super.init()
        for track in missingTracks {
            if let location = track.location, let url = URL(string: location) {
                var path = url.path.components(separatedBy: "/").filter({$0 != ""})
                createNode(with: &path, with: track)
            }
        }
    }
}

class MissingFilesViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var folderColumn: NSTableColumn!
    @IBOutlet weak var itemsColumn: NSTableColumn!
    var pathTree: MissingTrackPathTree
    var fileManager = FileManager.default
    var missingTracks = Set<Track>()
    
    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, tracks: [Track]) {
        self.pathTree = MissingTrackPathTree(with: tracks)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.missingTracks = Set(tracks)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let node = item as? MissingTrackPathNode else { return 1 }
        return node.children.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? MissingTrackPathNode else { return true }
        return node.children.count > 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? MissingTrackPathNode {
            return node.children[index]
        } else {
            return self.pathTree.rootNode
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? MissingTrackPathNode else { return  nil }
        switch tableColumn! {
        case folderColumn:
            let view = outlineView.make(withIdentifier: "PathComponentView", owner: node) as! NSTableCellView
            view.textField?.stringValue = node.pathComponent
            let url = URL(fileURLWithPath: node.completePathRepresentation())
            do {
                let keys = [URLResourceKey.effectiveIconKey, URLResourceKey.customIconKey]
                let values = try url.resourceValues(forKeys: Set(keys))
                view.imageView?.image = values.customIcon ?? values.effectiveIcon as? NSImage
            } catch {
                view.textField?.textColor = NSColor.disabledControlTextColor
                view.imageView?.image = node.children.count > 0 ? NSImage(named: "NSFolder") : NSWorkspace.shared().icon(forFileType: UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, url.pathExtension as CFString, nil)!.takeRetainedValue() as String)
                //print(error)
            }
            return view
        default:
            let numberBeneath = node.missingTracks.count
            let url = URL(fileURLWithPath: node.completePathRepresentation())
            if node.missingTracks.count >= node.totalTracks.count {
                let view = outlineView.make(withIdentifier: "ItemNumberNotFoundView", owner: node) as! MissingFileCellViewWithLocateButton
                let string  = "\(numberBeneath) missing, \(node.totalTracks.count) total"
                view.textField?.stringValue = string
                view.representedNode = node
                view.locateButton.action = #selector(locateButtonPressed)
                return view
            } else {
                let view = outlineView.make(withIdentifier: "ItemNumberView", owner: node) as! MissingFileTableCellView
                let string  = "\(numberBeneath) missing, \(node.totalTracks.count) total"
                view.textField?.stringValue = string
                view.representedNode = node
                return view
            }
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        return true
    }
    @IBAction func locateButtonPressed(_ sender: Any) {
        let view = (sender as! NSButton).superview! as! MissingFileTableCellView
        let node = view.representedNode
        let fileModal = NSOpenPanel()
        fileModal.canChooseDirectories = true
        fileModal.runModal()
        let url = fileModal.url
        let oldAbsoluteString = URL(fileURLWithPath: node!.completePathRepresentation()).absoluteString
        let newAbsoluteString = url!.absoluteString
        for track in node!.missingTracks {
            track.location = track.location!.replacingOccurrences(of: oldAbsoluteString, with: newAbsoluteString, options: .anchored, range: nil)
            if fileManager.fileExists(atPath: URL(string: track.location!)!.path) {
                self.missingTracks.remove(track)
            }
        }
        self.pathTree = MissingTrackPathTree(with: Array(self.missingTracks))
        outlineView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.outlineView.expandItem(nil, expandChildren: true)
    }
    
}
