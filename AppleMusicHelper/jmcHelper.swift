//
//  jmcHelper.swift
//  AppleMusicHelper
//
//  Created by John Moody on 8/22/22.
//  Copyright © 2022 John Moody. All rights reserved.
//

import Foundation

class jmcHelper: NSObject, jmcHelperProtocol {
    func test(input: String, reply: (String) -> Void) {
        reply(input)
    }
}
