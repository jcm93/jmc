//
//  MissingFilesViewController.swift
//  jmc
//
//  Created by John Moody on 6/16/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa


class PathNode: NSObject {
    
    var pathComponent: String
    var children = [PathNode]()
    var parent: PathNode?
    
    init(pathComponent: String, parent: PathNode? = nil) {
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
        let path = pathComponents.joined(separator: "/")
        return path
    }
}

class PathTree: NSObject {
    
    var rootNode: PathNode
    
    func createNode(with pathComponents: inout [String], under parentOrRoot: PathNode? = nil) {
        guard pathComponents.count > 0 else { return }
        let currentNode = parentOrRoot ?? rootNode
        let nextPathComponent = pathComponents.removeFirst()
        if let nextNode = currentNode.children.first(where: {$0.pathComponent == nextPathComponent}) {
            createNode(with: &pathComponents, under: nextNode)
        } else {
            let newNode = PathNode(pathComponent: nextPathComponent, parent: currentNode)
            if pathComponents.count > 0 {
                createNode(with: &pathComponents, under: newNode)
            } else {
                return
            }
        }
    }
    
    init(with URLs: [URL]) {
        self.rootNode = PathNode(pathComponent: "/")
        super.init()
        for url in URLs {
            var path = url.path.components(separatedBy: "/").filter({$0 != ""})
            createNode(with: &path)
        }
    }
}

class MissingFilesViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var folderColumn: NSTableColumn!
    @IBOutlet weak var itemsColumn: NSTableColumn!
    var pathTree: PathTree
    var fileManager = FileManager.default
    
    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, URLs: [URL]) {
        self.pathTree = PathTree(with: URLs)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let node = item as? PathNode else { return 1 }
        return node.children.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? PathNode else { return true }
        return node.children.count > 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? PathNode {
            return node.children[index]
        } else {
            return self.pathTree.rootNode
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? PathNode else { return  nil }
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
                view.imageView?.image = node.children.count > 0 ? NSImage(named: "NSFolder") : NSWorkspace.shared().icon(forFileType: UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, url.pathExtension as CFString, nil)!.takeRetainedValue() as String)
                //print(error)
            }
            return view
        default:
            let numberBeneath = node.numberBeneath()
            let url = URL(fileURLWithPath: node.completePathRepresentation())
            if url.lastPathComponent == "Are We There" {
                print("donguirew")
            }
            let numberCheck = numberBeneath
            if numberBeneath == numberCheck {
                let view = outlineView.make(withIdentifier: "ItemNumberNotFoundView", owner: node) as! MissingFileTableCellView
                view.textField?.stringValue = numberBeneath == 0 ? "" : "\(String(describing: numberBeneath)) \(numberBeneath == 1 ? "item" : "items")"
                view.locateButton.stringValue = "Locate File"
                return view
            } else {
                let view = outlineView.make(withIdentifier: "ItemNumberView", owner: node) as! NSTableCellView
                view.textField?.stringValue = numberBeneath == 0 ? "" : "\(String(describing: numberBeneath)) \(numberBeneath == 1 ? "item" : "items")"
                return view
            }
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.outlineView.expandItem(nil, expandChildren: true)
    }
    
}
