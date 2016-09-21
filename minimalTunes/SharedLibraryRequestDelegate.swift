//
//  SharedLibraryRequestDelegate.swift
//  minimalTunes
//
//  Created by John Moody on 9/3/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

class SharedLibraryRequestDelegate {
    
    var dataTask: NSURLSessionDataTask?
    var otherDataTask: NSURLSessionDataTask?
    let defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    var requestedTrack: Track?
    
    func getOnlineFriends() {
        let friends = NSUserDefaults.standardUserDefaults().objectForKey("addedIdentifiers") as! NSArray
        let serverAddress = NSUserDefaults.standardUserDefaults().stringForKey("serverAddress")
        for friend in friends {
            let requestAddress = serverAddress! + "/get_user?user=\(friend)"
            let serverAddressURL = NSURL(string: requestAddress)
            otherDataTask = defaultSession.dataTaskWithURL(serverAddressURL!) {
                data, response, error in
                if error != nil {
                    print("some shit happened, fuck")
                } else {
                    if let httpResponse = response as? NSHTTPURLResponse {
                        print(response)
                        if httpResponse.statusCode == 200 {
                            var responseData: NSDictionary?
                            do {
                                responseData = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
                                let address = responseData!["address"] as! String
                                self.onlineCheck(address)

                            } catch {
                                print("error: \(error)")
                            }
                        }
                    }
                }
            }
            otherDataTask?.resume()
        }
    }
    
    func onlineCheck(addr: String) {
        let requestURL = NSURL(string: addr)
        print("req url is \(requestURL)")
        dataTask = defaultSession.dataTaskWithURL(requestURL!) {
            data, response, error in
            print("badoingle")
            if error != nil {
                print("some kinda error when pinging shared library: \(error)")
            } else {
                if let httpResponse = response as? NSHTTPURLResponse {
                    print(response)
                    if httpResponse.statusCode == 200 {
                        var name: String?
                        do {
                            let responseData = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
                            name = responseData!["name"] as? String
                        } catch {
                            print(error)
                        }
                        dispatch_async(dispatch_get_main_queue()) {
                            (NSApplication.sharedApplication().delegate as! AppDelegate).mainWindowController?.sourceListTreeController.addNetworkedLibrary(name!, address: addr)
                        }
                    }
                }
            }
        }
        dataTask?.resume()
    }
    
    func listRequest(addr: String, parentItem: SourceListItem) {
        let requestURL = NSURL(string: addr)
        dataTask = defaultSession.dataTaskWithURL(requestURL!) {
            data, response, error in
            print("asking for source list")
            if error != nil {
                print("some kinda error when asking for source list: \(error)")
            } else {
                print("response when asking for source list: \(response)")
                if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        var responseData: [NSDictionary]?
                        do {
                            print("source list response data: \(data?.bytes)")
                            responseData = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as? [NSDictionary]
                            dispatch_async(dispatch_get_main_queue()) {
                                (NSApplication.sharedApplication().delegate as! AppDelegate).mainWindowController?.sourceListTreeController.addSourcesForNetworkedLibrary(responseData!, item: parentItem)
                            }
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
        dataTask?.resume()
    }
}