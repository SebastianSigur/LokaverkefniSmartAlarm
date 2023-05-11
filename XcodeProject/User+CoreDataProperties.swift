//
//  User+CoreDataProperties.swift
//  SMIOS
//
//  Created by Sebastian Sigurdarson on 5.4.2023.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var name: String?
    @NSManaged public var sleepGoal: Double
    @NSManaged public var age: Int64
    @NSManaged public var weight: Int64
    @NSManaged public var enableNotifications: Bool
    @NSManaged public var male: Bool

}

extension User : Identifiable {

}
