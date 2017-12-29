//
//  Library+CoreDataClass.swift
//  jmc
//
//  Created by John Moody on 6/9/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


public class Library: NSManagedObject {
    
    func getCentralMediaFolder() -> URL? {
        let templateBundle = self.organization_template
        let defaultTemplate = templateBundle?.default_template
        return URL(string: defaultTemplate!.base_url_string!)
    }
    
    func someRootChanged(newURL: URL, oldURL: URL) {
        let oldString = oldURL.absoluteString
        let newString = newURL.absoluteString
        self.watch_dirs = (self.watch_dirs as! [URL]).map({(url: URL) in
            return URL(string: url.absoluteString.replacingOccurrences(of: oldString, with: newString, options: .anchored, range: nil))
        }) as NSArray
        self.organization_template?.default_template?.base_url_string = self.organization_template?.default_template?.base_url_string?.replacingOccurrences(of: oldString, with: newString, options: .anchored, range: nil)
        for template in self.organization_template!.other_templates! {
            (template as! OrganizationTemplate).base_url_string = (template as! OrganizationTemplate).base_url_string?.replacingOccurrences(of: oldString, with: newString, options: .anchored, range: nil)
        }
        for track in (self.tracks as! Set<Track>) {
            track.location = track.location?.replacingOccurrences(of: oldString, with: newString, options: .anchored, range: nil)
        }
    }
    
    func changeCentralFolderLocation(newURL: URL) {
        let oldString = self.organization_template!.default_template!.base_url_string!
        let newString = newURL.absoluteString
        self.organization_template?.default_template?.base_url_string = self.organization_template?.default_template?.base_url_string?.replacingOccurrences(of: oldString, with: newString, options: .anchored, range: nil)
        for objCTemplate in self.organization_template!.other_templates! {
            guard let template = objCTemplate as? OrganizationTemplate else { continue }
            template.base_url_string = template.base_url_string?.replacingOccurrences(of: oldString, with: newString, options: .anchored, range: nil)
        }
        if var watchDirs = self.watch_dirs as? [URL] {
            let oldCentralFolder = URL(string: oldString)!
            var indexesToReplace = [Int]()
            for (index, url) in watchDirs.enumerated() {
                if url == oldCentralFolder {
                    indexesToReplace.append(index)
                }
            }
            for index in indexesToReplace {
                watchDirs[index] = newURL
            }
            self.watch_dirs = watchDirs as NSArray
        }

    }
    
    func initialSetup(withCentralDirectory url: URL, organizationType: Int, renamesFiles: Bool) {
        let newTemplateBundle = NSEntityDescription.insertNewObject(forEntityName: "OrganizationTemplateBundle", into: privateQueueParentContext) as! OrganizationTemplateBundle
        newTemplateBundle.initializeWithDefaults(centralFolder: url)
        self.organization_template = newTemplateBundle
        self.name = NSFullUserName() + "'s library"
        self.parent = nil
        self.is_active = true
        self.renames_files = renamesFiles as NSNumber
        var urlArray = [URL]()
        urlArray.append(url)
        self.watch_dirs = urlArray as NSArray
        self.finds_artwork = true as NSNumber
        self.monitors_directories_for_new = false
        self.organization_type = organizationType as NSNumber
        self.keeps_track_of_files = organizationType != 0 ? true as NSNumber : false as NSNumber
    }
    
}
