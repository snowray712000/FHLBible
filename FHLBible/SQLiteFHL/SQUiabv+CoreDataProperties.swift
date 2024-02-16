//
//  SQUiabv+CoreDataProperties.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/29.
//
//

import Foundation
import CoreData


extension SQUiabv {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SQUiabv> {
        return NSFetchRequest<SQUiabv>(entityName: "SQUiabv")
    }

    @NSManaged public var book: String?
    @NSManaged public var cname: String?
    @NSManaged public var version: String?
    @NSManaged public var cnameGB: String?

}

extension SQUiabv : Identifiable {

}
