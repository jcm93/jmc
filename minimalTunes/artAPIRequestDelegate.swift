//
//  artAPIRequestDElegate.swift
//  minimalTunes
//
//  Created by John Moody on 8/19/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa

/*class artAPIRequestDelegate {
    
    var dataTask: NSURLSessionDataTask?
    let defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    var requestedTrack: Track?
    
    func artAPIRequest(track: Track) -> String? {
        requestedTrack = track
        let albumName: String?
        if track.album?.name != nil {
            albumName = "\"\(track.album!.name!)\""
            let encodedAlbumName = albumName!.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet())!
            print("searching musicbrainz for \(encodedAlbumName)")
            let requestString = "http://musicbrainz.org/ws/2/release?query=\(encodedAlbumName)&limit=1&fmt=json"
            let requestURL = NSURL(string: requestString)
            dataTask = defaultSession.dataTaskWithURL(requestURL!) {
                data, response, error in
                if error != nil {
                    print("error retrieving id: \(error)")
                } else {
                    if let httpResponse = response as? NSHTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            do {
                                let jsonResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                                let releases = jsonResult["releases"] as? NSArray
                                if releases?.count > 0 {
                                    let firstRelease = releases?[0] as? NSDictionary
                                    let firstReleaseID = firstRelease?["id"] as? String
                                    if firstReleaseID != nil {
                                        self.getArtIDFromAlbumID(firstReleaseID!)
                                    }
                                }
                                } catch {
                                print("error parsing musicbrainz response as JSON: \(error)")
                            }
                        }
                        else {
                            
                        }
                    }
                }
            }
            dataTask!.resume()
    }
        return nil
    }
    
    func getArtIDFromAlbumID(id: String) -> String? {
        let encodedID = id.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet())!
        print("searching coverartarchive for \(encodedID)")
        let requestString = "http://coverartarchive.org/release/\(encodedID)/front"
        let requestURL = NSURL(string: requestString)
        dataTask = defaultSession.dataTaskWithURL(requestURL!) {
            data, response, error in
            if error != nil {
                print("error retrieving id: \(error)")
            } else {
                if let httpResponse = response as? NSHTTPURLResponse {
                    let albumDirectoryPath = NSURL(string: self.requestedTrack!.location!)!.URLByDeletingLastPathComponent
                    if addPrimaryArtForTrack(self.requestedTrack!, art: data!) != nil {
                        dispatch_async(dispatch_get_main_queue()) {
                            (NSApplication.sharedApplication().delegate as! AppDelegate).mainWindowController?.albumArtViewController?.initAlbumArt(self.requestedTrack!)
                        }
                    }
                }
                
            }
        }
        dataTask!.resume()
        return nil
        
    }
}*/
