//
//  OrganizationTemplateBundle+CoreDataClass.swift
//  jmc
//
//  Created by John Moody on 6/10/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


public class OrganizationTemplateBundle: NSManagedObject {
    
    func match(_ file: AnyObject) -> OrganizationTemplate {
        switch file {
        case let file as Track:
            let organizationTemplate = self.other_templates?.first(where: {(($0 as! OrganizationTemplate).predicate as! NSPredicate).evaluate(with: file)})
            return organizationTemplate as? OrganizationTemplate ?? self.default_template!
        case let file as AlbumFile:
            //uh
            
            let organizationTemplate = self.other_templates?.first(where: {(($0 as! OrganizationTemplate).predicate as! NSPredicate).evaluate(with: file.album?.tracks?.anyObject() as? Track)})
            return organizationTemplate as? OrganizationTemplate ?? self.default_template!
        default:
            return self.default_template!
        }
    }
    
    func match(wholeAlbum album: Album) -> [NSObject : URL] {
        var directoryURLs = Set<URL>()
        let trackURLs = (album.tracks as! Set<Track>).map({track -> URL in
            let template = self.match(track)
            let url = template.getURL(for: track, withExtension: nil)!
            directoryURLs.insert(url.deletingLastPathComponent())
            return url
        })
        
    }
    
    func initializeWithDefaults(centralFolder: URL) {
        let defaultTemplate = NSEntityDescription.insertNewObject(forEntityName: "OrganizationTemplate", into: managedContext) as! OrganizationTemplate
        defaultTemplate.base_url_string = centralFolder.absoluteString
        defaultTemplate.tokens = DEFAULT_TEMPLATE_TOKEN_ARRAY as NSArray
        self.default_template = defaultTemplate
        
        let compilationRule = NSEntityDescription.insertNewObject(forEntityName: "OrganizationTemplate", into: managedContext) as! OrganizationTemplate
        compilationRule.base_url_string = centralFolder.absoluteString
        compilationRule.predicate = COMPILATION_PREDICATE
        compilationRule.tokens = COMPILATION_TOKEN_ARRAY as NSArray
        let otherTemplates = self.other_templates?.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
        otherTemplates.add(compilationRule)
        self.other_templates = otherTemplates as NSOrderedSet
    }

}
