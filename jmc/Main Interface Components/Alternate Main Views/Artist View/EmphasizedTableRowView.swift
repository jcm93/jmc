//
//  EmphasizedTableRowView.swift
//  jmc
//
//  Created by John Moody on 1/7/22.
//  Copyright © 2022 John Moody. All rights reserved.
//

import Cocoa

class EmphasizedTableRowView: NSTableRowView {
    
    override var isEmphasized: Bool {
        set {
            
        }
        get {
            return true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
