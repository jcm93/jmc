//
//  jmcHelperProtocol.swift
//  jmc
//
//  Created by John Moody on 8/23/22.
//  Copyright © 2022 John Moody. All rights reserved.
//

import Foundation


import Foundation

@objc public protocol jmcHelperProtocol {
    func test(input: String, reply: @escaping (String) -> Void)
}
