//
//  OrganizationTemplate+CoreDataClass.swift
//  jmc
//
//  Created by John Moody on 6/10/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


public class OrganizationTemplate: NSManagedObject {
    
    func validateTemplate() -> Bool {
        //every template should be technically valid, but for the sake of convenience, we probably want to mandate that templates have at least one token, and contain a trackname token, at the very least
        //very "at own risk"
        guard let template = self.tokens as? [OrganizationFieldToken], template.count > 0 else { return false }
        //guard template.contains(where: {$0.tokenType != .other}) else { return false }
        //guard template.contains(where: {$0.tokenType == .trackname}) else { return false }
        return true
    }
    
    func getURL(for albumFile: AnyObject, withExtension pathExtension: String?) -> URL? {
        let pathExtension = pathExtension ?? URL(string: albumFile.value(forKey: "location") as! String)!.pathExtension
        guard var template = self.tokens as? [OrganizationFieldToken], var baseURL = URL(string: self.base_url_string!) else { return nil }
        let urlPathComponents = {() -> [String] in
            switch albumFile {
            case is Track:
                return template.map({return transformToPathComponent(token: $0, albumFile: albumFile)}).joined().components(separatedBy: "/")
            case let albumFile as AlbumFile:
                template.removeLast()
                var components = template.map({return transformToPathComponent(token: $0, albumFile: albumFile)}).joined().components(separatedBy: "/")
                components.append(albumFile.file_description!)
                return components
            default:
                fatalError()
            }
        }()
        for component in urlPathComponents {
            baseURL.appendPathComponent(component)
        }
        return baseURL.appendingPathExtension(pathExtension).standardizedFileURL
    }
    
    func getValue(for key: OrganizationFieldToken, of file: AnyObject) -> String {
        var string = {() -> String in
            switch file {
            case let file as Track:
                switch key.tokenType {
                case .album:
                    return (file.album?.name ?? UNKNOWN_ALBUM_STRING).replacingOccurrences(of: "/", with: ":")
                case .albumartist:
                    return (file.album?.album_artist?.name ?? file.artist?.name ?? UNKNOWN_ARTIST_STRING).replacingOccurrences(of: "/", with: ":")
                case .artist:
                    return (file.artist?.name ?? UNKNOWN_ARTIST_STRING).replacingOccurrences(of: "/", with: ":")
                case .other:
                    return key.stringIfOther!
                case .trackname:
                    return (file.name ?? "").replacingOccurrences(of: "/", with: ":")
                case .tracknum:
                    var discNumberStringRepresentation: String
                    if file.disc_number != nil {
                        discNumberStringRepresentation = "\(String(describing: file.disc_number!))-"
                    } else {
                        discNumberStringRepresentation = ""
                    }
                    let trackNumberStringRepresentation: String
                    if file.track_num != nil {
                        let trackNumber = Int(file.track_num!)
                        if trackNumber < 10 {
                            trackNumberStringRepresentation = "0\(trackNumber)"
                        } else {
                            trackNumberStringRepresentation = String(trackNumber)
                        }
                    } else {
                        trackNumberStringRepresentation = ""
                        discNumberStringRepresentation = ""
                    }
                    return ("\(discNumberStringRepresentation)\(trackNumberStringRepresentation)").replacingOccurrences(of: "/", with: ":")
                case .year:
                    return (file.album?.release_date?.date.description ?? "").replacingOccurrences(of: "/", with: ":")
                }
            case let file as AlbumFile:
                switch key.tokenType {
                case .album:
                    return (file.album?.name ?? UNKNOWN_ALBUM_STRING).replacingOccurrences(of: "/", with: ":")
                case .albumartist:
                    return (file.album?.album_artist?.name ?? file.album?.album_artist?.name ?? UNKNOWN_ARTIST_STRING).replacingOccurrences(of: "/", with: ":")
                case .artist:
                    return (file.album?.album_artist?.name ?? UNKNOWN_ARTIST_STRING).replacingOccurrences(of: "/", with: ":")
                case .other:
                    return key.stringIfOther!
                case .trackname:
                    return (file.file_description ?? "").replacingOccurrences(of: "/", with: ":")
                case .tracknum:
                    return "shouldn't ever be returned"
                case .year:
                    return (file.album?.release_date?.date.description ?? "").replacingOccurrences(of: "/", with: ":")
                }
            default:
                fatalError()
            }
        }()
        return string
    }
    
    
    
    func transformToPathComponent(token: OrganizationFieldToken, albumFile: AnyObject) -> String {
        return self.getValue(for: token, of: albumFile)
    }

}
