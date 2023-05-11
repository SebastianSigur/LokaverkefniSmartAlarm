//
//  Alarm+CoreDataProperties.swift
//  SMIOS
//
//  Created by Sebastian Sigurdarson on 23.3.2023.
//
//

import Foundation
import CoreData


extension Alarm {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Alarm> {
        return NSFetchRequest<Alarm>(entityName: "Alarm")
    }

    @NSManaged public var gentleWake: Bool
    @NSManaged public var hm: Int64
    @NSManaged public var hour: Int64
    @NSManaged public var id: Int64
    @NSManaged public var isNotifying: Bool
    @NSManaged public var minute: Int64
    @NSManaged public var giveFront: Int64
    @NSManaged public var giveBack: Int64
    @NSManaged public var name: String?
    @NSManaged public var on: Bool
    @NSManaged public var sound: String?
    @NSManaged public var uuidWatch2: String
    @NSManaged public var uuidPhone: String
    @NSManaged public var uuidWatch1: String

}

extension Alarm : Identifiable {

}
