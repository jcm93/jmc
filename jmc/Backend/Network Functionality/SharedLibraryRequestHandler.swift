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
    
    func getSourceList() -> [NSMutableDictionary]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SourceListItem")
        let predicate = NSPredicate(format: "(playlist != nil) AND (is_network == nil OR is_network == false)")
        fetchRequest.predicate = predicate
        var results: [SourceListItem]?
        do {
            results = try privateQueueParentContext.fetch(fetchRequest) as? [SourceListItem]
        }catch {
            print("error: \(error)")
        }
        guard results != nil else {return nil}
        var serializedResults = [NSMutableDictionary]()
        for item in results! {
            serializedResults.append(item.dictRepresentation())
        }
        return serializedResults
        var finalObject: Data?
        do {
            finalObject = try JSONSerialization.data(withJSONObject: serializedResults, options: JSONSerialization.WritingOptions.prettyPrinted)
        } catch {
            print("error: \(error)")
        }
        //return finalObject
    }
    
    func getPlaylist(_ id: Int, fields: [String]) -> NSDictionary? {
        //sends a dictionary containing JSON tracks and artists etc., and cached sort orders for the important sorts
        let playlistDictionary = NSMutableDictionary()
        let playlistRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SongCollection")
        let playlistPredicate = NSPredicate(format: "id = '\(id)'")
        playlistRequest.predicate = playlistPredicate
        let result: SongCollection? = {
            do {
                let thing = try privateQueueParentContext.fetch(playlistRequest) as! [SongCollection]
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
        let playlistSongsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
        let id_array = [Int]()
        guard id_array != nil else {return nil}
        let playlistSongsPredicate = NSPredicate(format: "id in %@", id_array)
        playlistSongsRequest.predicate = playlistSongsPredicate
        let results: [Track]? = {
            do {
                let thing = try privateQueueParentContext.fetch(playlistSongsRequest) as! [Track]
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
        playlistDictionary["orders"] = getCachedOrders(fields, id_array: id_array )
        return playlistDictionary
    }
    
    func getAllMetadataForTrack(_ trackID: Int) -> NSDictionary? {
        let trackFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
        let trackFetchPredicate = NSPredicate(format: "id == \(trackID)")
        trackFetchRequest.predicate = trackFetchPredicate
        let track: Track? = {() -> Track? in
            do {
                let result = try privateQueueParentContext.fetch(trackFetchRequest) as! [Track]
                return result[0]
            } catch {
                print("error: \(error)")
                return nil
            }
        }()!
        let fields = Array(DEFAULT_COLUMN_VISIBILITY_DICTIONARY.keys)
        let metadata = track?.dictRepresentation(fields)
        return metadata
    }
    
    func getCachedOrders(_ fields: [String], id_array: [Int]) -> [NSDictionary]? {
        //takes an array of track IDs about to be sent over the wire, and compiles the cached orders for sorting them, filtered according to what fields are displayed in the peer's table.
        //returns array of dictionaries, whose gots arrays of ints insides em
        var cachedOrdersDictionary = [NSDictionary]()
        let filterDictionary = NSMutableDictionary()
        for id in id_array {
            filterDictionary[id] = true
        }
        let cachedOrders: [CachedOrder] = {
            let fetch_request = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedOrder")
            let result = [CachedOrder]()
            do {
                let thing = try privateQueueParentContext.fetch(fetch_request) as! [CachedOrder]
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
    
    func getSong(_ id: Int) -> Data? {
        let songRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
        let songPredicate = NSPredicate(format: "id = %i", id)
        songRequest.predicate = songPredicate
        let result: Track? = {
            do {
                let thing = try privateQueueParentContext.fetch(songRequest) as! [Track]
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
        let trackURL = URL(string: result!.location!)
        let trackData = try? Data(contentsOf: trackURL!)
        return trackData
    }
}
