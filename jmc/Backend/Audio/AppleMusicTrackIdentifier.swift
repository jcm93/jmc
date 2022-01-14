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
    
    func requestResource(track: String) async -> String {
        let percentEncodedString = track.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        let urlString = "https://api.music.apple.com/v1/me/library/search?term=\(percentEncodedString!)&types=library-songs&limit=10"
        let requestURL = URL(string: urlString)!
        let urlRequest = URLRequest(url: requestURL)
        do {
            //form url
            let request = MusicDataRequest(urlRequest: urlRequest)
            let status = try await request.response()
            let trackID = self.determineTrackIDToPlay(response: status, track: track)
            return trackID
        } catch {
            print("error making api request")
            return ""
        }
    }
        
    func determineTrackIDToPlay(response: MusicDataResponse, track: String) -> String {
        print("patooties")
        do {
            //let's just take the top response for now
            let jsonObject = try JSONSerialization.jsonObject(with: response.data, options: [])
            let songsArray = ((((jsonObject as! NSDictionary)["results"] as! NSDictionary)["library-songs"] as! NSDictionary)["data"] as! NSArray)
            let firstResult = songsArray[0] as! NSDictionary
            let resultID = firstResult["id"] as! String
            return resultID
        } catch {
            return ""
        }
    }
    
    
}
