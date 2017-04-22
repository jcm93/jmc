//
//  NewSourceSheetController.swift
//  jmc
//
//  Created by John Moody on 2/22/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class NewSourceSheetController: NSWindowController, NSTableViewDelegate {
    
    @IBOutlet weak var okButton: NSButton!
    @IBOutlet var volumeArrayController: NSArrayController!
    @IBOutlet weak var sourceExistsTextField: NSTextField!
    let databaseManager = DatabaseManager()
    let fileManager = FileManager.default
    var url: URL?
    var libSelector: LibraryManagerSourceSelector?
    
    var volumeArray = [URL]()
    
    func initializeForSelection(url: URL) {
        self.url = url
        do {
            let key = URLResourceKey.volumeURLKey
            let resourceValues = try url.resourceValues(forKeys: Set([key]))
            let volURL = resourceValues.volume
            self.url = volURL
        } catch {
            print(error)
            fatalError()
        }
        let urls = getAllLibraries()!.map({return URL(string: $0.volume_url_string!)!})
        let urlSet = Set(urls)
        if !urlSet.contains(self.url!) {
            //ok
            self.okButton.isEnabled = true
            self.sourceExistsTextField.isHidden = true
        } else {
            //not ok
            self.okButton.isEnabled = false
            self.sourceExistsTextField.isHidden = false
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        let volume = (volumeArrayController.arrangedObjects as! NSArray)[row] as! URL
        self.initializeForSelection(url: volume)
        return true
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.window?.close()
    }
    
    @IBAction func okButtonPressed(_ sender: Any) {
        databaseManager.createNewSource(url: self.url!)
        libSelector?.addSourceModalComplete(response: NSModalResponseOK)
        self.window?.close()
    }
    
    override func windowDidLoad() {
        let volumesDirURL = URL(fileURLWithPath: "/Volumes/")
        do {
            let volumeURLS = try fileManager.contentsOfDirectory(at: volumesDirURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
            self.volumeArray = volumeURLS
            volumeArrayController.content = self.volumeArray
        } catch {
            print(error)
        }
        super.windowDidLoad()
    }
    
}
