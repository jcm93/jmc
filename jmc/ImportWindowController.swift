//
//  ImportWindowcontroller.swift
//  minimalTunes
//
//  Created by John Moody on 7/10/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

private var my_special_context = 0

class ImportWindowController: NSWindowController {
    
    @IBOutlet weak var pathController: NSPathControl!
    @IBOutlet weak var OKButton: NSButton!
    @IBOutlet weak var keepDirectoryRadioButton: NSButton!
    @IBOutlet weak var moveFilesRadioButton: NSButton!
    @IBOutlet weak var pathField: NSTextField!
    var path: String?
    var iTunesParser: iTunesLibraryParser?
    var mainWindowController: MainWindowController?
    
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.shared().delegate
            as? AppDelegate)?.managedObjectContext }()!
    
    var moveFiles: Bool = true

    @IBAction func browseClicked(_ sender: AnyObject) {
        openFile()
    }
    
    @IBAction func radioButtonAction(_ sender: AnyObject) {
        if keepDirectoryRadioButton.state == NSOnState {
            moveFiles = false
        }
        else if moveFilesRadioButton.state == NSOnState {
            moveFiles = true
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func confirmClicked(_ sender: AnyObject) {
        var pathURL = URL(fileURLWithPath: path!)
        pathURL = pathURL.deletingLastPathComponent()
        pathURL = pathURL.appendingPathComponent("iTunes Music", isDirectory: true)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: pathURL.path, isDirectory: nil) == false {
            pathURL = pathURL.deletingLastPathComponent()
            pathURL = pathURL.appendingPathComponent("iTunes Media", isDirectory: true)
        }
        let appDelegate = (NSApplication.shared().delegate as! AppDelegate)
        let library = NSEntityDescription.insertNewObject(forEntityName: "Library", into: managedContext) as! Library
        library.library_location = pathURL.absoluteString
        library.name = pathURL.lastPathComponent
        library.parent = globalRootLibrary
        library.is_active = true
        library.renames_files = 0 as NSNumber
        library.organization_type = 0 as NSNumber
        library.keeps_track_of_files = true
        library.monitors_directories_for_new = true
        let librarySourceListItem = NSEntityDescription.insertNewObject(forEntityName: "SourceListItem", into: managedContext) as! SourceListItem
        librarySourceListItem.library = library
        librarySourceListItem.name = library.name
        globalRootLibrarySourceListItem!.addToChildren(librarySourceListItem)
        let newNode = SourceListNode(item: librarySourceListItem)
        newNode.parent = globalRootLibrarySourceListItem!.node
        globalRootLibrarySourceListItem!.node!.children.append(newNode)

        appDelegate.iTunesParser = self.iTunesParser
        appDelegate.initializeProgressBarWindow()
        print("made it here")
        appDelegate.importProgressBar?.doStuff(library: library)
        iTunesParser?.addObserver(self, forKeyPath: "doneEverything", options: .new, context: &my_special_context)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "doneEverything" {
            print("window controller here")
            completionHandler()
        }
    }
    
    func subContextDidSave(_ notification: Notification) {
        print("main context merging changes, supposedly")
        let selector = #selector(NSManagedObjectContext.mergeChanges(fromContextDidSave:))
        managedContext.performSelector(onMainThread: selector, with: notification, waitUntilDone: true)
    }
    
    func completionHandler() {
        print("import window done clause")
        do { try managedContext.save() } catch {print("\(error)")}
        let appDelegate = (NSApplication.shared().delegate as! AppDelegate)
        UserDefaults.standard.set(true, forKey: "hasMusic")
        appDelegate.importProgressBar?.window?.close()
        self.window?.close()
        self.mainWindowController?.hasMusic = true
        //self.mainWindowController?.sourceListTreeController.content = self.mainWindowController?.sourceListHeaderNodes
        //self.mainWindowController?.windowDidLoad()
        self.mainWindowController?.sourceListViewController?.viewDidLoad()
    }
    
    func openFile() {
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        myFileDialog.runModal()
        
        // Get the path to the file chosen in the NSOpenPanel
        if myFileDialog.url!.path != nil {
            path = myFileDialog.url!.path
            pathController.url = myFileDialog.url
        }
        do {
            iTunesParser = try iTunesLibraryParser(path: path!)
            NotificationCenter.default.addObserver(self, selector: #selector(subContextDidSave), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
        } catch {
            OKButton.isEnabled = false
        }
        
        // Make sure that a path was chosen
        
    }
    
}
