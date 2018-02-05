//
//  OrganizationTemplate.swift
//  jmc
//
//  Created by John Moody on 6/1/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa

enum TokenType: Int {
    case artist, albumartist, album, tracknum, trackname, year, other
}

class OrganizationFieldToken: NSObject, NSCoding {
    
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
        case "Disc-Track #":
            self.tokenType = .tracknum
        case "Title":
            self.tokenType = .trackname
        case "Year":
            self.tokenType = .year
        default:
            self.tokenType = .other
            self.stringIfOther = string
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.stringIfOther = aDecoder.decodeObject(forKey: "stringIfOther") as? String
        self.tokenType = TokenType(rawValue: Int(aDecoder.decodeInt64(forKey: "tokenType")))!
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(stringIfOther, forKey: "stringIfOther")
        aCoder.encode(tokenType.rawValue, forKey: "tokenType")
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
            return "Title"
        case .tracknum:
            return "Disc-Track #"
        case .year:
            return "Year"
        }
    }
}
