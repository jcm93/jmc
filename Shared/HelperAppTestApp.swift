//
//  HelperAppTestApp.swift
//  Shared
//
//  Created by John Moody on 8/23/22.
//  Copyright © 2022 John Moody. All rights reserved.
//

import SwiftUI

@main
class HelperAppTestApp: App {
    
    
    
    var connectionHandler: ConnectionHandler!
    var musicKitPlayer: MusicKitPlayer!
    var body: some Scene {
        WindowGroup {
            //ContentView()
        }
    }
    
    
    required init() {
        self.connectionHandler = ConnectionHandler()
        self.musicKitPlayer = MusicKitPlayer()
        print("poop")
        self.connectionHandler.listener.resume()
        //self.body = fatalError()
        //self.body = fatalError()
    }
    

    /*var body: some Scene {
        WindowGroup {
            //ContentView()
        }
    }*/
}
