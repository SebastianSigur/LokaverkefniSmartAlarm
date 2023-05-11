//
//  SMWatchAppApp.swift
//  SMWatchApp Watch App
//
//  Created by Sebastian Sigurdarson on 23.3.2023.
//

import SwiftUI

@main
struct SMWatchApp_Watch_AppApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var workoutManager = WorkoutManager()
    @StateObject var alarmManager = AlarmManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext).environmentObject(workoutManager).environmentObject(alarmManager)
            
        }
    }
}
