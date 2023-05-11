//
//  SleepStages+CoreDataProperties.swift
//  SMIOS
//
//  Created by Sebastian Sigurdarson on 7.4.2023.
//
//

import Foundation
import CoreData


extension SleepStages {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SleepStages> {
        return NSFetchRequest<SleepStages>(entityName: "SleepStages")
    }

    @NSManaged public var uuid: UUID?
    @NSManaged public var stages: [Int]? //[NSObject]?

}

extension SleepStages : Identifiable {

}
