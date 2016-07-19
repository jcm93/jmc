//
//  ImportWindowcontroller.swift
//  minimalTunes
//
//  Created by John Moody on 7/10/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class ImportWindowController: NSWindowController {
    
    @IBOutlet weak var OKButton: NSButton!
    @IBOutlet weak var keepDirectoryRadioButton: NSButton!
    @IBOutlet weak var moveFilesRadioButton: NSButton!
    @IBOutlet weak var pathField: NSTextField!
    var path: String?
    var iTunesParser: iTunesLibraryParser?
    var mainWindowController: MainWindowController?
    
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
        /*let appDelegate = (NSApplication.sharedApplication().delegate as! AppDelegate)
        appDelegate.iTunesParser = iTunesParser
        appDelegate.initializeProgressBarWindow()
        
        NSUserDefaults.standardUserDefaults().setObject(pathURL.path, forKey: "libraryPath")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            appDelegate.importProgressBar?.doStuff()
            dispatch_async(dispatch_get_main_queue()) {
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasMusic")
                self.completionHandler()
            }
        }*/
        var pathURL = NSURL(fileURLWithPath: path!)
        pathURL = pathURL.URLByDeletingLastPathComponent!
        pathURL = pathURL.URLByAppendingPathComponent("iTunes Music", isDirectory: true)
        NSUserDefaults.standardUserDefaults().setObject(pathURL.path, forKey: "libraryPath")
        do {iTunesParser = try iTunesLibraryParser(path: path!)}catch{print("Error")}
        iTunesParser?.makeLibrary()
        completionHandler()
        self.window?.close()
    }
    
    func completionHandler() {
        let managedContext: NSManagedObjectContext = {
            return (NSApplication.sharedApplication().delegate
                as? AppDelegate)?.managedObjectContext }()!
        //do { try managedContext.save() } catch {print("\(error)")}
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasMusic")
        self.mainWindowController?.libraryTableScrollView.hidden = false
        self.mainWindowController?.noMusicView.hidden = true
        self.mainWindowController?.sourceListView.hidden = false
        self.mainWindowController?.expandSourceView()
        
    }
    func openFile() {
        
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        myFileDialog.runModal()
        
        // Get the path to the file chosen in the NSOpenPanel
        if myFileDialog.URL!.path != nil {
            path = myFileDialog.URL!.path!
            pathField.stringValue = path!
        }
        do {
            iTunesParser = try iTunesLibraryParser(path: path!)
        } catch {
            pathField.stringValue = "Invalid iTunes Library file."
            OKButton.enabled = false
        }
        
        // Make sure that a path was chosen
        if (path != nil) {
            let err = NSError?()
        }
        
    }
    
}
