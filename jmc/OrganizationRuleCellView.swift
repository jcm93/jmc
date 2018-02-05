//
//  OrganizationRuleCellView.swift
//  jmc
//
//  Created by John Moody on 6/14/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class OrganizationRuleCellView: NSTableCellView {
    
    @IBOutlet var organizationView: NSView?
    
    var viewController: OrganizationRuleViewController?
    
    override func mouseDown(with event: NSEvent) {
        Swift.print("called")
    }

    func initializeForController(_ vc: OrganizationRuleViewController) {
        self.viewController = vc
        for view in organizationView!.subviews {
            view.removeFromSuperview()
        }
        organizationView?.addSubview(viewController!.view)
        viewController?.nextResponder = self
        //newViewController.view.frame = view.bounds
        //if viewController!.constraintsAreActive != true {
        viewController?.view.frame = self.bounds
        viewController!.view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        viewController!.view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        viewController!.view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        viewController!.view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        self.wantsLayer = true
        self.layer?.cornerRadius = 20.0
            //viewController!.constraintsAreActive = true
        //}
        //newViewController.viewDidLoad()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
