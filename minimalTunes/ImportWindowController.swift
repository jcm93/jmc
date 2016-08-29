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
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!
    
    var moveFiles: Bool = true

    @IBAction func browseClicked(sender: AnyObject) {
        openFile()
    }
    
    @IBAction func radioButtonAction(sender: AnyObject) {
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
    
    @IBAction func confirmClicked(sender: AnyObject) {
        var pathURL = NSURL(fileURLWithPath: path!)
        pathURL = pathURL.URLByDeletingLastPathComponent!
        pathURL = pathURL.URLByAppendingPathComponent("iTunes Music", isDirectory: true)
        NSUserDefaults.standardUserDefaults().setObject(pathURL.path, forKey: "libraryPath")
        let appDelegate = (NSApplication.sharedApplication().delegate as! AppDelegate)
        appDelegate.iTunesParser = self.iTunesParser
        appDelegate.initializeProgressBarWindow()
        print("made it here")
        appDelegate.importProgressBar?.doStuff()
        iTunesParser?.addObserver(self, forKeyPath: "doneEverything", options: .New, context: &my_special_context)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "doneEverything" {
            print("window controller here")
            completionHandler()
        }
    }
    
    func completionHandler() {
        print("import window done clause")
        do { try managedContext.save() } catch {print("\(error)")}
        let appDelegate = (NSApplication.sharedApplication().delegate as! AppDelegate)
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasMusic")
        self.mainWindowController?.libraryTableScrollView.hidden = false
        self.mainWindowController?.noMusicView.hidden = true
        self.mainWindowController?.sourceListView.hidden = false
        self.mainWindowController?.expandSourceView()
        appDelegate.importProgressBar?.window?.close()
        self.window?.close()
        self.mainWindowController?.hasMusic = true
        self.mainWindowController?.sourceListTreeController.content = self.mainWindowController?.sourceListHeaderNodes
        self.mainWindowController?.windowDidLoad()
    }
    
    func openFile() {
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        myFileDialog.runModal()
        
        // Get the path to the file chosen in the NSOpenPanel
        if myFileDialog.URL!.path != nil {
            path = myFileDialog.URL!.path!
            pathController.URL = myFileDialog.URL
        }
        do {
            iTunesParser = try iTunesLibraryParser(path: path!)
        } catch {
            OKButton.enabled = false
        }
        
        // Make sure that a path was chosen
        if (path != nil) {
            let err = NSError?()
        }
        
    }
    
}
