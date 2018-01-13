//
//  ErrorHandler.swift
//  jmc
//
//  Created by John Moody on 12/28/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class ErrorHandler: NSObject {
    
    var errors = [Error]()
    var delegate: AppDelegate!
    
    func addError(error: Error) {
        self.errors.append(error)
    }
    
    func presentErrors() {
        
    }
}

class SaveErrorHandler: ErrorHandler {
    override func presentErrors() {
        if errors.count > 0 {
            self.delegate.presentSevereErrors(self.errors)
        }
    }
}
