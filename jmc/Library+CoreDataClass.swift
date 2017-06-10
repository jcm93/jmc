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
        let templateBundle = self.organization_templates as? LibraryOrganizationTemplateBundle
        let defaultTemplate = templateBundle?.defaultTemplate
        return defaultTemplate?.baseURL
    }
}
