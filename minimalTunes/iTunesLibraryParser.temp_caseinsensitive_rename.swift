//
//  itunesLibraryParser.swift
//  minimalTunes
//
//  Created by John Moody on 5/29/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Foundation
import CoreData

class iTunesLibraryParser {
    let libDict = NSMutableDictionary(contentsOfFile: "/Volumes/Macintosh HD/CS/shittyTunes/shitTunes/shitTunes/iTunes Library.xml")
    let masterArray = NSArray()
    let trackDict = NSDictionary()
    var masterPlaylistDictList = [NSDictionary()]
    let poop = 
    
    func makeLibrary() -> Array<AnyObject> {
        var result = Array<AnyObject>()
        let library = Library()
        let playlistArray = libDict!.objectForKey("Playlists") as! NSArray
        let masterDict = playlistArray[0] as! NSDictionary
        let masterArray = masterDict.objectForKey("Playlist Items") as! NSArray
        let trackDict = libDict!.objectForKey("Tracks") as! NSDictionary
        for item in masterArray {
            let id = item.objectForKey("Track ID")?.description
            let individualTrackDict = trackDict.objectForKey(id!)
            masterPlaylistDictList.append(individualTrackDict as! NSDictionary)
            var name, sort_name, artist, sort_artist, composer, sort_composer, album, sort_album, file_kind, genre, kind, comments, search_field, album_artist: String
            var track_id, track_num, time, size, bit_rate, sample_rate, play_count, skip_count, rating: Int
            var date_released, date_modified, date_added, date_last_played, date_last_skipped: NSDate
            var status, compilation: Bool
            var location: NSURL
            if (individualTrackDict!.objectForKey("Track ID") != nil) {
                track_id = individualTrackDict!.objectForKey("Track ID") as! Int
            }
            else {
                track_id = 0
            }
            if (individualTrackDict!.objectForKey("Track Type") != nil) {
                kind = individualTrackDict!.objectForKey("Track Type") as! String
            }
            else {
                kind = ""
            }
            if (individualTrackDict!.objectForKey("Skip Date") != nil) {
                date_last_skipped = individualTrackDict!.objectForKey("Skip Date") as! NSDate
            }
            else {
                date_last_skipped = NSDate.distantPast()
            }
            if (individualTrackDict!.objectForKey("Sample Rate") != nil) {
                sample_rate = individualTrackDict!.objectForKey("Sample Rate") as! Int
            }
            else {
                sample_rate = 0
            }
            if (individualTrackDict!.objectForKey("Kind") != nil) {
                file_kind = individualTrackDict!.objectForKey("Kind") as! String
            }
            else {
                file_kind = ""
            }
            if (individualTrackDict!.objectForKey("Comments") != nil) {
                comments = individualTrackDict!.objectForKey("Comments") as! String
            }
            else {
                comments = ""
            }
            if (individualTrackDict!.objectForKey("Play Date UTC") != nil) {
                date_last_played = individualTrackDict!.objectForKey("Play Date UTC") as! NSDate
            }
            else if (individualTrackDict!.objectForKey("Play Date") != nil) {
                date_last_played = individualTrackDict!.objectForKey("Play Date") as! NSDate
            }
            else {
                date_last_played = NSDate.distantPast()
            }
            if (individualTrackDict!.objectForKey("Track Number") != nil) {
                track_num = individualTrackDict!.objectForKey("Track Number") as! Int
            }
            else {
                track_num = 0
            }
            if (individualTrackDict!.objectForKey("Date Added") != nil) {
                date_added = individualTrackDict!.objectForKey("Date Added") as! NSDate
            }
            else {
                date_added = NSDate.distantPast()
            }
            if (individualTrackDict!.objectForKey("Name") != nil) {
                name = individualTrackDict!.objectForKey("Name") as! String
            }
            else {
                name = ""
            }
            if (individualTrackDict!.objectForKey("Size") != nil) {
                size = individualTrackDict!.objectForKey("Size") as! Int
            }
            else {
                size = 0
            }
            if (individualTrackDict!.objectForKey("Location") != nil) {
                location = NSURL(string: individualTrackDict?.objectForKey("Location") as! String)!
            }
            else {
                location = NSURL(fileURLWithPath: "/")
            }
            if (individualTrackDict!.objectForKey("Artist") != nil) {
                artist = individualTrackDict!.objectForKey("Artist") as! String
            }
            else {
                artist = ""
            }
            if (individualTrackDict!.objectForKey("Album Artist") != nil) {
                album_artist = individualTrackDict!.objectForKey("Album Artist") as! String
            }
            else {
                album_artist = ""
            }
            if (individualTrackDict!.objectForKey("Skip Count") != nil) {
                skip_count = individualTrackDict!.objectForKey("Skip Count") as! Int
            }
            else {
                skip_count = 0
            }
            if (individualTrackDict!.objectForKey("Play Count") != nil) {
                play_count = individualTrackDict!.objectForKey("Play Count") as! Int
            }
            else {
                play_count = 0
            }
            if (individualTrackDict!.objectForKey("Bit Rate") != nil) {
                bit_rate = individualTrackDict!.objectForKey("Bit Rate") as! Int
            }
            else {
                bit_rate = 0
            }
            if (individualTrackDict!.objectForKey("Total Time") != nil) {
                time = individualTrackDict!.objectForKey("Total Time") as! Int
            }
            else {
                time = 0
            }
            if (individualTrackDict!.objectForKey("Date Modified") != nil) {
                date_modified = individualTrackDict!.objectForKey("Date Modified") as! NSDate
            }
            else {
                date_modified = NSDate.distantPast()
            }
            if (individualTrackDict!.objectForKey("Album") != nil) {
                album = individualTrackDict!.objectForKey("Album") as! String
            }
            else {
                album = ""
            }
            if (individualTrackDict!.objectForKey("Sort Album") != nil) {
                sort_album = individualTrackDict!.objectForKey("Sort Album") as! String
            }
            else {
                sort_album = album
            }
            if (individualTrackDict!.objectForKey("Genre") != nil) {
                genre = individualTrackDict!.objectForKey("Genre") as! String
            }
            else {
                genre = ""
            }
            if (individualTrackDict!.objectForKey("Rating") != nil) {
                rating = individualTrackDict!.objectForKey("Rating") as! Int
            }
            else {
                rating = 0
            }
            if (individualTrackDict!.objectForKey("Sort Name") != nil) {
                sort_name = individualTrackDict!.objectForKey("Sort Name") as! String
            }
            else {
                sort_name = name
            }
            if (individualTrackDict!.objectForKey("Release Date") != nil) {
                date_released = individualTrackDict!.objectForKey("Release Date") as! NSDate
            }
            else {
                date_released = NSDate.distantPast()
            }
            if (individualTrackDict!.objectForKey("Composer") != nil) {
                composer = individualTrackDict!.objectForKey("Composer") as! String
            }
            else {
                composer = ""
            }
            if (individualTrackDict!.objectForKey("Sort Composer") != nil) {
                sort_composer = individualTrackDict!.objectForKey("Sort Composer") as! String
            }
            else {
                sort_composer = ""
            }
            if (individualTrackDict!.objectForKey("Disabled") != nil) {
                status = individualTrackDict!.objectForKey("Disabled") as! Bool
            }
            else {
                status = true
            }
            if (individualTrackDict!.objectForKey("Sort Artist") != nil) {
                sort_artist = individualTrackDict!.objectForKey("Sort Artist") as! String
            }
            else {
                sort_artist = artist
            }
            if (individualTrackDict!.objectForKey("Compilation") != nil) {
                compilation = individualTrackDict!.objectForKey("Compilation") as! Bool
            }
            else {
                compilation = false
            }
            search_field = ""
            let the_song = Track(id: track_id, name: name, sort_name: sort_name, artist: artist, sort_artist: sort_artist, composer: composer, sort_composer: sort_composer, album: album, sort_album: sort_album, track_num: track_num, album_artist: album_artist, time: time, release_date: date_released, date_modified: date_modified, date_added: date_added, last_played_date: date_last_played, last_skipped_date: date_last_skipped, size: size, bit_rate: bit_rate, sample_rate: sample_rate, file_kind: file_kind, play_count: play_count, skip_count: skip_count, genre: genre, kind: kind, rating: rating, comments: comments, search_field: search_field, location: location, status: status, compilation: compilation)
            library.songs.append(the_song)
        }
        result.append(library)
        for playlist_item in playlistArray {
            var ids = [Int]()
            if (playlist_item.valueForKey("Playlist Items") != nil) {
                let thePlaylistArray = playlist_item.valueForKey("Playlist Items") as! NSArray
                for stupidDict in thePlaylistArray {
                    let id = stupidDict["Track ID"] as! Int
                    ids.append(id)
                }
            }
            else {
                let thePlaylistArray = []
            }
            let playlist_name = playlist_item.valueForKey("Name") as! String
            let playlist_id = playlist_item.valueForKey("Playlist ID") as! Int
            let the_playlist = Playlist(id: playlist_id, name: playlist_name, ids: ids)
            playlists.append(the_playlist)
            
        }
        result.append(playlists)
        return result
    }
}