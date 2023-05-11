//
//  Persistence.swift
//  SMIOS
//
//  Created by Sebastian Sigurdarson on 23.3.2023.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        let newAlarm = Alarm(context: viewContext)
        newAlarm.on = false
        newAlarm.name = "Demo Alarm"
        newAlarm.hour = 12
        newAlarm.minute = 59
        newAlarm.hm = 12+59
        newAlarm.sound = "Radar"
        newAlarm.gentleWake = true
        
        let newSleep = NewSleep(context: viewContext)
        newSleep.beginDate = Date()
        newSleep.endDate = Date()
        
     
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "SMIOS")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
             
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
