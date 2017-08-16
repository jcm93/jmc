//
//  LastFMDelegate.swift
//  jmc
//
//  Created by John Moody on 7/26/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

class LastFMDelegate: NSObject {
    
    var apiKey: String = "9aa5793d5daf443fcf79972e6e3f2975"
    var apiSecret: String = "91d7f5dc1f622d90b5949741021d4869"
    var baseURL = URL(string: "https://ws.audioscrobbler.com/2.0/?")!
    var token: String = ""
    var sessionKey = globalRootLibrary!.last_fm_session_key ?? ""
    var scrobbles = UserDefaults.standard.bool(forKey: DEFAULTS_SCROBBLES)
    
    var callback: ((String) -> Void)?
    
    var authenticationBaseURL = URL(string: "https://www.last.fm/api/auth/")!
    
    override init() {
        super.init()
    }
    
    func setup() {
        if globalRootLibrary?.last_fm_session_key == nil {
            let methodParameter = URLQueryItem(name: "method", value: "auth.getToken")
            let apiKeyParameter = URLQueryItem(name: "api_key", value: apiKey)
            let formatParameter = URLQueryItem(name: "format", value: "json")
            var tokenRequestURLComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            tokenRequestURLComponents!.queryItems = [methodParameter, apiKeyParameter, formatParameter]
            let task = URLSession.shared.dataTask(with: tokenRequestURLComponents!.url!, completionHandler: handleGetAuthTokenResponse)
            task.resume()
        }
    }
    
    func handleGetAuthTokenResponse(data: Data?, response: URLResponse?, err: Error?) {
        print("got auth token response")
        do {
            let responseData = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
            let token = responseData["token"] as? String
            self.token = token!
        } catch {
            print(error)
        }
    }
    
    func launchAuthentication() {
        guard self.token != "" else { return }
        var authenticationURLComponents = URLComponents(url: authenticationBaseURL, resolvingAgainstBaseURL: false)!
        let apiKeyParameter = URLQueryItem(name: "api_key", value: apiKey)
        let tokenParameter = URLQueryItem(name: "token", value: self.token)
        authenticationURLComponents.queryItems = [apiKeyParameter, tokenParameter]
        NSWorkspace.shared().open(authenticationURLComponents.url!)
    }
    
    func getSessionKey(callback: ((String) -> Void)?) {
        guard self.token != "" else { return }
        var sessionKeyURLComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        let tokenParameter = URLQueryItem(name: "token", value: self.token)
        let methodParameter = URLQueryItem(name: "method", value: "auth.getSession")
        let apiKeyParameter = URLQueryItem(name: "api_key", value: self.apiKey)
        let formatParameter = URLQueryItem(name: "format", value: "json")
        sessionKeyURLComponents.queryItems = [methodParameter, tokenParameter, apiKeyParameter]
        let stupidSignature = getStupidSignature(urlComponents: sessionKeyURLComponents)
        let apiSigParameter = URLQueryItem(name: "api_sig", value: stupidSignature)
        sessionKeyURLComponents.queryItems!.append(contentsOf: [formatParameter, apiSigParameter])
        let task = URLSession.shared.dataTask(with: sessionKeyURLComponents.url!, completionHandler: handleSessionKeyResponse)
        self.callback = callback
        task.resume()
    }
    
    func handleSessionKeyResponse(data: Data?, response: URLResponse?, err: Error?) {
        print("got session key response")
        var name = ""
        defer {
            DispatchQueue.main.async {
                self.callback?(name)
            }
        }
        do {
            let responseData = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
            guard let session = responseData["session"] as? NSDictionary else { print("couldn't get session"); return }
            guard let key = session["key"] as? String else { print("couldn't get session key"); return }
            globalRootLibrary?.last_fm_session_key = key
            name = session["name"] as? String ?? ""
            globalRootLibrary?.last_fm_username = name
        } catch {
            print(error)
        }
    }
    
    func getStupidSignature(urlComponents: URLComponents) -> String {
        let queryItems = urlComponents.queryItems!.sorted(by: {return $0.name < $1.name})
        let ordered = queryItems.map({return "\($0.name)\($0.value!)"}).joined().appending(self.apiSecret)
        let signature = createThirtyTwoCharacterMD5HashOf(data: ordered.data(using: .utf8)!)
        return signature
    }
    
    func scrobble(track: Track, timestamp: Date) {
        guard self.scrobbles, self.sessionKey != "" else { return }
        guard track.artist?.name != nil , track.name != nil else { print("can't scrobble nil track"); return }
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        var parameters = [
            URLQueryItem(name: "method", value: "track.scrobble"),
            URLQueryItem(name: "api_key", value: self.apiKey),
            URLQueryItem(name: "sk", value: globalRootLibrary!.last_fm_session_key!),
            URLQueryItem(name: "track", value: track.name!),
            URLQueryItem(name: "artist", value: track.artist!.name!),
            URLQueryItem(name: "duration", value: String(track.time!.intValue / 1000)),
            URLQueryItem(name: "timestamp", value: timestamp.timeIntervalSince1970.description)
        ]
        if let album = track.album?.name { parameters.append(URLQueryItem(name: "album", value: album)) }
        if let trackNumber = track.track_num?.stringValue { parameters.append(URLQueryItem(name: "trackNumber", value: trackNumber)) }
        if let albumArtist = track.album?.album_artist?.name, albumArtist != track.artist!.name! { parameters.append(URLQueryItem(name: "albumArtist", value: albumArtist)) }
        var urlComponents = URLComponents()
        urlComponents.queryItems = parameters
        parameters.append(URLQueryItem(name: "api_sig", value: getStupidSignature(urlComponents: urlComponents)))
        parameters.append(URLQueryItem(name: "format", value: "json"))
        request.httpBody = parameters.map({return $0.description}).joined(separator: "&").data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request, completionHandler: scrobbleResponse)
        task.resume()
        print("sending scrobble")
    }
    
    func scrobbleResponse(data: Data?, response: URLResponse?, err: Error?) {
        print("got scrobble response")
        print(response)
        do {
            let responseData = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
            print(responseData)
        } catch {
            print(error)
        }
    }
    
    func updateNowPlaying(track: Track) {
        
    }
    
}
