//
//  EqualizerWindowController.swift
//  minimalTunes
//
//  Created by John Moody on 8/26/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class EqualizerWindowController: NSWindowController {
    
    var mainWindowController: MainWindowController?
    
    @IBOutlet weak var eqToggle: NSButton!
    
    @IBAction func equalizerToggled(sender: AnyObject) {
        let state = eqToggle.state
        self.mainWindowController?.queue.toggleEqualizer(state)
    }
    
    @IBAction func gainSliderDidChange(sender: AnyObject) {
        let slider = sender as! NSSlider
        let value = slider.floatValue
        self.mainWindowController?.queue.adjustGain(value)
    }
    @IBAction func eqSliderDidChange(sender: AnyObject) {
        let slider = sender as! NSSlider
        let band = Int(slider.identifier!)!
        let value = slider.floatValue
        self.mainWindowController?.queue.adjustEqualizer(band, value: value)
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
