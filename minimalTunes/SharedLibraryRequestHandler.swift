//
//  SharedLibraryRequestHandler.swift
//  minimalTunes
//
//  Created by John Moody on 9/5/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
import CoreData

class SharedLibraryRequestHandler {
    
    var server: P2PServer?
    
    func getSourceList() -> [NSMutableDictionary]? {
        let fetchRequest = NSFetchRequest(entityName: "SourceListItem")
        let predicate = NSPredicate(format: "(playlist != nil)")
        fetchRequest.predicate = predicate
        var results: [SourceListItem]?
        do {
            results = try managedContext.executeFetchRequest(fetchRequest) as? [SourceListItem]
        }catch {
            print("error: \(error)")
        }
        guard results != nil else {return nil}
        var serializedResults = [NSMutableDictionary]()
        for item in results! {
            serializedResults.append(item.dictRepresentation())
        }
        return serializedResults
        var finalObject: NSData?
        do {
            finalObject = try NSJSONSerialization.dataWithJSONObject(serializedResults, options: NSJSONWritingOptions.PrettyPrinted)
        } catch {
            print("error: \(error)")
        }
        //return finalObject
    }
    
    func getPlaylist(id: Int, fields: [String]) -> NSDictionary? {
        //sends a dictionary containing JSON tracks and artists etc., and cached sort orders for the important sorts
        let playlistDictionary = NSMutableDictionary()
        let playlistRequest = NSFetchRequest(entityName: "SongCollection")
        let playlistPredicate = NSPredicate(format: "id = '\(id)'")
        playlistRequest.predicate = playlistPredicate
        let result: SongCollection? = {
            do {
                let thing = try managedContext.executeFetchRequest(playlistRequest) as! [SongCollection]
                if thing.count > 0 {
                    return thing[0]
                } else {
                    return nil
                }
            } catch {
                print("error: \(error)")
            }
            return nil
        }()
        print(result)
        guard result != nil else {return nil}
        let playlistSongsRequest = NSFetchRequest(entityName: "Track")
        let id_array = result?.track_id_list
        let playlistSongsPredicate = NSPredicate(format: "id in %@", id_array!)
        playlistSongsRequest.predicate = playlistSongsPredicate
        let results: [Track]? = {
            do {
                let thing = try managedContext.executeFetchRequest(playlistSongsRequest) as! [Track]
                if thing.count > 0 {
                    return thing
                } else {
                    return nil
                }
            } catch {
                print("error: \(error)")
            }
            return nil
        }()
        print(results)
        guard results != nil else {return nil}
        var serializedTracks = [NSDictionary]()
        for track in results! {
            serializedTracks.append(track.dictRepresentation(fields))
        }
        playlistDictionary["playlist"] = serializedTracks
        playlistDictionary["orders"] = getCachedOrders(fields, id_array: id_array as! [Int])
        return playlistDictionary
    }
    
    func getCachedOrders(fields: [String], id_array: [Int]) -> [NSDictionary]? {
        //takes an array of track IDs about to be sent over the wire, and compiles the cached orders for sorting them, filtered according to what fields are displayed in the peer's table.
        //returns array of dictionaries, whose gots arrays of ints insides em
        var cachedOrdersDictionary = [NSDictionary]()
        let filterDictionary = NSMutableDictionary()
        for id in id_array {
            filterDictionary[id] = true
        }
        let cachedOrders: [CachedOrder] = {
            let fetch_request = NSFetchRequest(entityName: "CachedOrder")
            let result = [CachedOrder]()
            do {
                let thing = try managedContext.executeFetchRequest(fetch_request) as! [CachedOrder]
                if thing.count != 0 {
                    return thing
                }
            }
            catch {
                print("err")
            }
            return result
        }()
        
        let filteredOrderNames: [String] = {
            var names = [String]()
            for field in fields {
                if let cachedName = fieldsToCachedOrdersDictionary[field] as? String {
                    names.append(cachedName)
                }
            }
            return names
        }()
        
        let filteredOrders = cachedOrders.filter({return filteredOrderNames.contains($0.order!)})
        
        for order in filteredOrders {
            let cachedOrderDictionary = NSMutableDictionary()
            let array = (order.track_views?.array as! [TrackView]).map({return $0.track!.id!}).filter({return filterDictionary[$0] as? Bool == true})
            cachedOrderDictionary["name"] = order.order
            cachedOrderDictionary["tracks"] = array
            cachedOrdersDictionary.append(cachedOrderDictionary)
        }
        return cachedOrdersDictionary
    }
    
    func getSong(id: Int) -> NSData? {
        let songRequest = NSFetchRequest(entityName: "Track")
        let songPredicate = NSPredicate(format: "id = %i", id)
        songRequest.predicate = songPredicate
        let result: Track? = {
            do {
                let thing = try managedContext.executeFetchRequest(songRequest) as! [Track]
                if thing.count > 0 {
                    return thing[0]
                } else {
                    return nil
                }
            } catch {
                print(error)
            }
            return nil
        }()
        guard result != nil else {return nil}
        let trackURL = NSURL(string: result!.location!)
        let trackData = NSData(contentsOfURL: trackURL!)
        return trackData
    }
}
