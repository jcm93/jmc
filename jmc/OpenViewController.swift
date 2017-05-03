//
//  OpenViewController.swift
//  jmc
//
//  Created by John Moody on 5/1/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class OpenViewController: NSViewController {
    
    @IBOutlet weak var comboBox: NSPopUpButton!
    var managedContext = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
    var currentLibrary: Library?
    var nameLibDict = [String : Library]()

    @IBOutlet weak var orgCheck: NSButton!
    @IBOutlet weak var copyRadio: NSButton!
    @IBOutlet weak var moveRadio: NSButton!
    
    var orgType: Int = 0
    
    @IBAction func comboBoxChangedSelection(_ sender: Any) {
        print("popup changed called")
        self.currentLibrary = self.nameLibDict[self.comboBox.selectedItem!.title]
        self.orgType = currentLibrary?.organization_type?.intValue ?? 0
        if currentLibrary?.organization_type != nil && currentLibrary?.organization_type != 0 {
            orgCheck.state = NSOnState
            if currentLibrary?.organization_type == 1 {
                moveRadio.state = NSOnState
            } else {
                copyRadio.state = NSOnState
            }
        } else {
            orgCheck.state = NSOffState
            moveRadio.isEnabled = false
            copyRadio.isEnabled = false
            if currentLibrary?.central_media_folder_url_string == nil {
                orgCheck.isEnabled = false
            }
        }
    }
    
    @IBAction func orgChecked(_ sender: Any) {
        if orgCheck.state == NSOnState {
            moveRadio.isEnabled = true
            copyRadio.isEnabled = true
            self.orgType = moveRadio.state == NSOnState ? 1 : 2
            self.currentLibrary?.organization_type = self.orgType as NSNumber?
        } else {
            self.orgType = 0
            self.currentLibrary?.organization_type = self.orgType as NSNumber?
            moveRadio.isEnabled = false
            copyRadio.isEnabled = false
        }
    }
    
    @IBAction func radioAction(_ sender: Any) {
        self.orgType = moveRadio.state == NSOnState ? 1 : 2
        self.currentLibrary?.organization_type = self.orgType as NSNumber?
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        let libraries = getAllLibraries()
        for library in libraries! {
            self.nameLibDict[library.name!] = library
        }
        comboBox.addItems(withTitles: nameLibDict.keys.map({return $0}))
        comboBoxChangedSelection(self)
    }
    
}
