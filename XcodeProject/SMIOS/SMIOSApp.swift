//
//  SMIOSApp.swift
//  SMIOS
//
//  Created by Sebastian Sigurdarson on 23.3.2023.
//

import SwiftUI

@main
struct SMIOSApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var alarmManager = AlarmManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(alarmManager)
                .preferredColorScheme(.dark) // Force dark mode
        }
    }
}
