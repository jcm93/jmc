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
        appDelegate.iTunesParser = self.iTunesParser
        appDelegate.launchAddFilesDialog()
        DispatchQueue.global(qos: .default).async {
            appDelegate.iTunesParser?.makeLibrary(parentLibrary: globalRootLibrary, visualUpdateHandler: appDelegate.backgroundAddFilesHandler)
        }
        self.window?.close()
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
        } catch {
            OKButton.isEnabled = false
        }
        
        // Make sure that a path was chosen
        
    }
    
}
