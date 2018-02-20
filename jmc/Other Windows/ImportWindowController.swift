//
//  ImportWindowcontroller.swift
//  minimalTunes
//
//  Created by John Moody on 7/10/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

private var my_special_context = 0

class ImportWindowController: NSWindowController, NSTableViewDelegate {
    
    @IBOutlet weak var pathController: NSPathControl!
    @IBOutlet weak var OKButton: NSButton!
    @objc var playlists = [NSDictionary]()
    @IBOutlet var playlistArrayController: NSArrayController!
    @IBOutlet weak var playlistTableView: NSTableView!
    var path: String?
    var iTunesParser: iTunesLibraryParser?
    var mainWindowController: MainWindowController?
    
    let managedContext: NSManagedObjectContext = {
        return (NSApplication.shared.delegate
            as? AppDelegate)?.managedObjectContext }()!
    
    var moveFiles: Bool = true

    @IBAction func browseClicked(_ sender: AnyObject) {
        openFile()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        playlistTableView.delegate = self
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    
    @IBAction func confirmClicked(_ sender: AnyObject) {
        let appDelegate = (NSApplication.shared.delegate as! AppDelegate)
        let set = Set(self.playlistArrayController.selectedObjects.map({return ($0 as! NSDictionary)["name"] as! String}))
        self.iTunesParser?.XMLPlaylistArray = self.iTunesParser!.XMLPlaylistArray.filter({set.contains(($0 as! NSDictionary)["Name"] as! String)}) as NSArray
        appDelegate.iTunesParser = self.iTunesParser
        appDelegate.launchAddFilesDialog()
        let subContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        subContext.parent = managedContext
        subContext.perform {
            appDelegate.iTunesParser?.makeLibrary(parentLibrary: globalRootLibrary, visualUpdateHandler: appDelegate.backgroundAddFilesHandler, subContext: subContext)
        }
        self.iTunesParser = nil
        self.window?.close()
    }
    
    /*func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        let currentSelection = tableView.selectedRowIndexes
        let combined = currentSelection.union(proposedSelectionIndexes)
        let intersection = currentSelection.intersection(proposedSelectionIndexes)
        return combined.subtracting(intersection)
    }*/
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("called")
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
            self.playlists = iTunesParser!.XMLPlaylistArray.map({ (thing: Any) -> NSDictionary in
                guard let dict = thing as? NSDictionary else { return [:] as NSDictionary }
                let playlistName = dict["Name"] as? String
                let numberOfItems = (dict["Playlist Items"] as? NSArray)?.count ?? 0
                return ["name" : playlistName, "items" : numberOfItems] as NSDictionary
            })
            self.playlistArrayController.content = self.playlists
        } catch {
            OKButton.isEnabled = false
        }
        
    }
    
}
