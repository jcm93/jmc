//
//  AppleMusicTrackIdentifier.swift
//  jmc
//
//  Created by John Moody on 1/14/22.
//  Copyright © 2022 John Moody. All rights reserved.
//

import Cocoa
import MusicKit

@available(macOS 12.0, *)
class AppleMusicTrackIdentifier: NSObject {
    
    var status: MusicAuthorization.Status
    
    init(authorizes: Bool) {
        self.status = .notDetermined
        super.init()
        if authorizes {
            authorize()
        }
    }
    
    func authorize() {
        Task {
            let authStatus = await MusicAuthorization.request()
            update(status: authStatus)
        }
    }
    
    func update(status: MusicAuthorization.Status) {
        self.status = status
    }
    
    func requestResource(track: Track) {
            Task {
                do {
                    //form url
                    let requestURL = URL(string: "https://api.music.apple.com/v1/me/library/search?term=\(track.name ?? "")&types=library-songs&limit=10")!
                    let urlRequest = URLRequest(url: requestURL)
                    let request = MusicDataRequest(urlRequest: urlRequest)
                    let status = try await request.response()
                    self.determineTrackIDToPlay(response: status, track: track)
                } catch {
                    print("error making api request")
                }
                
            }
        }
        
    func determineTrackIDToPlay(response: MusicDataResponse, track: Track) {
        print("patooties")
        let poop = String(data: response.data, encoding: .utf8)
        print(poop)
    }
    
    
}
