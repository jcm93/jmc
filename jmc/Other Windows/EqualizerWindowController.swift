//
//  EqualizerWindowController.swift
//  minimalTunes
//
//  Created by John Moody on 8/26/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class EqualizerWindowController: NSWindowController {
    
    var audioModule: AudioModule?
    
    @IBOutlet weak var gainSlider: NSSlider!
    @IBOutlet weak var firstSlider: NSSlider!
    @IBOutlet weak var eqToggle: NSButton!
    @IBOutlet weak var secondSlider: NSSlider!
    @IBOutlet weak var thirdSlider: NSSlider!
    @IBOutlet weak var fourthSlider: NSSlider!
    @IBOutlet weak var fifthSlider: NSSlider!
    @IBOutlet weak var sixthSlider: NSSlider!
    @IBOutlet weak var seventhSlider: NSSlider!
    @IBOutlet weak var eighthSlider: NSSlider!
    @IBOutlet weak var ninthSlider: NSSlider!
    @IBOutlet weak var tenthSlider: NSSlider!
    
    @IBAction func equalizerToggled(_ sender: AnyObject) {
        let state = eqToggle.state
        self.audioModule!.toggleEqualizer(state.rawValue)
        UserDefaults.standard.set(eqToggle.state, forKey: DEFAULTS_IS_EQ_ENABLED_STRING)
    }
    
    @IBAction func gainSliderDidChange(_ sender: AnyObject) {
        let slider = sender as! NSSlider
        let value = slider.floatValue
        self.audioModule!.adjustGain(value)
    }
    @IBAction func eqSliderDidChange(_ sender: AnyObject) {
        let slider = sender as! NSSlider
        let band = Int(slider.identifier!.rawValue)!
        let value = slider.floatValue
        self.audioModule!.adjustEqualizer(band, value: value)
    }

    override func windowDidLoad() {
        let bandSliders = [firstSlider, secondSlider, thirdSlider, fourthSlider, fifthSlider, sixthSlider, seventhSlider, eighthSlider, ninthSlider, tenthSlider]
        
        super.windowDidLoad()
        let defaultEQ = UserDefaults.standard.object(forKey: DEFAULTS_CURRENT_EQ_STRING) as? [Float]
        if defaultEQ != nil {
            var index = 0
            for band in defaultEQ! {
                if index == 10 {continue}
                bandSliders[index]?.floatValue = band
                index += 1
            }
            gainSlider.floatValue = defaultEQ![10]
        }
        let eqEnabledState = UserDefaults.standard.integer(forKey: DEFAULTS_IS_EQ_ENABLED_STRING)
        eqToggle.state = NSControl.StateValue(rawValue: eqEnabledState)
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
