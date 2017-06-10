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

    @NSManaged public var other_templates: NSOrderedSet?
    @NSManaged public var default_template: OrganizationTemplate?
    @NSManaged public var library: Library?

}

// MARK: Generated accessors for other_templates
extension OrganizationTemplateBundle {

    @objc(insertObject:inOther_templatesAtIndex:)
    @NSManaged public func insertIntoOther_templates(_ value: OrganizationTemplate, at idx: Int)

    @objc(removeObjectFromOther_templatesAtIndex:)
    @NSManaged public func removeFromOther_templates(at idx: Int)

    @objc(insertOther_templates:atIndexes:)
    @NSManaged public func insertIntoOther_templates(_ values: [OrganizationTemplate], at indexes: NSIndexSet)

    @objc(removeOther_templatesAtIndexes:)
    @NSManaged public func removeFromOther_templates(at indexes: NSIndexSet)

    @objc(replaceObjectInOther_templatesAtIndex:withObject:)
    @NSManaged public func replaceOther_templates(at idx: Int, with value: OrganizationTemplate)

    @objc(replaceOther_templatesAtIndexes:withOther_templates:)
    @NSManaged public func replaceOther_templates(at indexes: NSIndexSet, with values: [OrganizationTemplate])

    @objc(addOther_templatesObject:)
    @NSManaged public func addToOther_templates(_ value: OrganizationTemplate)

    @objc(removeOther_templatesObject:)
    @NSManaged public func removeFromOther_templates(_ value: OrganizationTemplate)

    @objc(addOther_templates:)
    @NSManaged public func addToOther_templates(_ values: NSOrderedSet)

    @objc(removeOther_templates:)
    @NSManaged public func removeFromOther_templates(_ values: NSOrderedSet)

}
