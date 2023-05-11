//
//  NewSleep+CoreDataProperties.swift
//  SMIOS
//
//  Created by Sebastian Sigurdarson on 23.3.2023.
//
//

import Foundation
import CoreData


extension NewSleep {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewSleep> {
        return NSFetchRequest<NewSleep>(entityName: "NewSleep")
    }

    @NSManaged public var beginDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var rating: String? // used as uuid

}

extension NewSleep : Identifiable {

}
