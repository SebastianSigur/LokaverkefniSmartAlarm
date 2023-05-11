//
//  SleepConfigurations+CoreDataProperties.swift
//  SMIOS
//
//  Created by Sebastian Sigurdarson on 23.3.2023.
//
//

import Foundation
import CoreData


extension SleepConfigurations {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SleepConfigurations> {
        return NSFetchRequest<SleepConfigurations>(entityName: "SleepConfigurations")
    }

    @NSManaged public var alarm: String?
    @NSManaged public var isSleeping: Bool
    @NSManaged public var startSleep: Date?
    @NSManaged public var uuid: UUID?

}

extension SleepConfigurations : Identifiable {

}
