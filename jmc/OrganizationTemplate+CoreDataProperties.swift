//
//  OrganizationTemplate+CoreDataProperties.swift
//  jmc
//
//  Created by John Moody on 6/10/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


extension OrganizationTemplate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrganizationTemplate> {
        return NSFetchRequest<OrganizationTemplate>(entityName: "OrganizationTemplate")
    }

    @NSManaged public var predicate: NSObject?
    @NSManaged public var tokens: NSObject?
    @NSManaged public var base_url_string: String?
    @NSManaged public var bundle: OrganizationTemplateBundle?
    @NSManaged public var bundle_multiple: OrganizationTemplateBundle?

}
