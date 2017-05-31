//
//  TrackQueueTableView.swift
//  jmc
//
//  Created by John Moody on 5/8/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class TrackQueueTableView: TableViewYouCanPressSpacebarOn {
    
    var minimumNumberVisibleRows: Int = 5
    
    override var frame: NSRect {
        get {
            let currentFrame = super.frame
            var heightAddendum: CGFloat
            if currentFrame.height <= self.enclosingScrollView!.frame.height {
                heightAddendum = CGFloat(numberOfRows - minimumNumberVisibleRows) * rowHeight + CGFloat(numberOfRows * 2) - CGFloat(minimumNumberVisibleRows) - 3
                //add two pixels per row for divider between rows
            } else {
                heightAddendum = self.enclosingScrollView!.frame.height - rowHeight * CGFloat(minimumNumberVisibleRows) - self.headerView!.frame.height - CGFloat(minimumNumberVisibleRows) - 3
                //subtract three pixels for border of table header view, border of first row
            }
            guard heightAddendum > 0 else { return currentFrame }
            let rect = NSRect(x: currentFrame.origin.x, y: currentFrame.origin.y, width: currentFrame.width, height: currentFrame.height + heightAddendum)
            return rect
        } set(newValue) {
            super.frame = newValue
        }
    }
    
    /*override var bounds: NSRect {
        get {
            let currentFrame = super.bounds
            var heightAddendum: CGFloat
            if currentFrame.height <= self.enclosingScrollView!.frame.height {
                heightAddendum = CGFloat(numberOfRows - minimumNumberVisibleRows) * rowHeight + CGFloat(numberOfRows * 2) - CGFloat(minimumNumberVisibleRows) - 3
                //add two pixels per row for divider between rows
            } else {
                heightAddendum = self.enclosingScrollView!.frame.height - rowHeight * CGFloat(minimumNumberVisibleRows) - self.headerView!.frame.height - CGFloat(minimumNumberVisibleRows) - 3
                //subtract three pixels for border of table header view, border of first row
            }
            guard heightAddendum > 0 else { return currentFrame }
            let rect = NSRect(x: currentFrame.origin.x, y: currentFrame.origin.y, width: currentFrame.width, height: currentFrame.height + heightAddendum)
            return rect
        } set {
            Swift.print("set bounds called")
            super.bounds = newValue
        }
    }*/

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
