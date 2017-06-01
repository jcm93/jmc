//
//  OrganizationTemplate.swift
//  jmc
//
//  Created by John Moody on 6/1/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

enum TokenType {
    case artist, albumartist, album, tracknum, trackname, year, other
}

struct OrganizationFieldToken {
    
    var stringIfOther: String?
    var tokenType: TokenType
    
    init(string: String) {
        switch string {
        case "Artist":
            self.tokenType = .artist
        case "Album Artist":
            self.tokenType = .albumartist
        case "Album":
            self.tokenType = .album
        case "Track #":
            self.tokenType = .tracknum
        case "Track Name":
            self.tokenType = .trackname
        case "Year":
            self.tokenType = .year
        default:
            self.tokenType = .other
            self.stringIfOther = string
        }
    }
    func stringRepresentation() -> String {
        switch self.tokenType {
        case .album:
            return "Album"
        case .albumartist:
            return "Album Artist"
        case .artist:
            return "Artist"
        case .other:
            return self.stringIfOther!
        case .trackname:
            return "Track Name"
        case .tracknum:
            return "Track #"
        case .year:
            return "Year"
        }
    }
}

class OrganizationTemplate: NSObject {

    var baseURL: URL
    var template: [OrganizationFieldToken]
    
    init(templateString: [OrganizationFieldToken], baseURL: URL) {
        self.template = templateString
        self.baseURL = baseURL
    }
    
    func validateTemplate() -> Bool {
//      every template should be technically valid, but for the sake of convenience, we probably want to mandate that templates have at least one token, and contain a trackname token, at the very least
//      very "at own risk"
        guard self.template.contains(where: {$0.tokenType != .other}) else { return false }
        guard self.template.contains(where: {$0.tokenType == .trackname}) else { return false }
        return true
    }
    
    func getURL(for track: Track, withExtension pathExtension: String) -> URL? {
        let urlPathComponents = self.template.map({return transformToPathComponent(token: $0, track: track)}).joined().components(separatedBy: "/")
        for component in urlPathComponents {
            self.baseURL = self.baseURL.appendingPathComponent(component)
        }
        return self.baseURL.appendingPathExtension(pathExtension)
    }
    
    func transformToPathComponent(token: OrganizationFieldToken, track: Track) -> String {
        switch token.tokenType {
        case .album:
            return track.album?.name ?? UNKNOWN_ALBUM_STRING
        case .albumartist:
            return track.album?.album_artist?.name ?? track.artist?.name ?? UNKNOWN_ARTIST_STRING
        case .artist:
            return track.artist?.name ?? UNKNOWN_ARTIST_STRING
        case .other:
            return token.stringIfOther!
        case .trackname:
            return track.name ?? ""
        case .tracknum:
            return track.track_num?.stringValue ?? ""
        case .year:
            return track.album?.release_date?.description ?? ""
        }
    }
}
