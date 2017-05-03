//
//  JMTextField.swift
//  jmc
//
//  Created by John Moody on 4/27/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class JMTagNumberTextField: NSTextField {
    
    override func textDidChange(_ notification: Notification) {
        let textWidth = self.attributedStringValue.size().width
        if textWidth <= 17.0 {
            let currentWidthConstraint = self.constraints.filter({return $0.firstAttribute == NSLayoutAttribute.width})
            NSLayoutConstraint.deactivate(currentWidthConstraint)
            let constraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 26.0)
            NSLayoutConstraint.activate([constraint])
        } else {
            let currentWidthConstraint = self.constraints.filter({return $0.firstAttribute == NSLayoutAttribute.width})
            NSLayoutConstraint.deactivate(currentWidthConstraint)
            let constraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: textWidth + 10.0)
            NSLayoutConstraint.activate([constraint])
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
