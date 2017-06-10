//
//  OrganizationTemplateBundle+CoreDataProperties.swift
//  jmc
//
//  Created by John Moody on 6/10/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation
import CoreData


extension OrganizationTemplateBundle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrganizationTemplateBundle> {
        return NSFetchRequest<OrganizationTemplateBundle>(entityName: "OrganizationTemplateBundle")
    }

    @NSManaged public var other_templates: NSSet?
    @NSManaged public var default_template: OrganizationTemplate?
    @NSManaged public var library: Library?

}

// MARK: Generated accessors for other_templates
extension OrganizationTemplateBundle {

    @objc(addOther_templatesObject:)
    @NSManaged public func addToOther_templates(_ value: OrganizationTemplate)

    @objc(removeOther_templatesObject:)
    @NSManaged public func removeFromOther_templates(_ value: OrganizationTemplate)

    @objc(addOther_templates:)
    @NSManaged public func addToOther_templates(_ values: NSSet)

    @objc(removeOther_templates:)
    @NSManaged public func removeFromOther_templates(_ values: NSSet)

}
