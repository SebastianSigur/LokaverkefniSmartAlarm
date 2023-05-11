//
//  ContentView.swift
//  SmartAlarm IOS
//
//  Created by Sebastian Sigurdarson on 7.2.2023.
//

import SwiftUI
import CoreData
import HealthKit
struct ContentView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)],
        animation: .default)
    private var users: FetchedResults<User>
    
    @EnvironmentObject var alarmManager: AlarmManager
    @State private var isFirstLaunch = true
    @State private var selectedTab = 1
    @State var showTutorial = true
    var body: some View {

        
        ZStack{
            TabView() {
                AlarmView()
                    .environmentObject(alarmManager)
                    .tabItem(){
                        Image(systemName: "alarm")
                        Text("Alarms")
                        
                    }
                    .tag(1)
                StatsView()
                    .tabItem(){
                        Image(systemName: "heart")
                        Text("Stats")
                        
                        
                    }
                    .tag(0)
                
                ProfileView()
                    .tabItem(){
                        Image(systemName: "person")
                        Text("Profile")
                        
                    }
                    .tag(2)
                
                
            }
            .onAppear{
                let healthStore = HKHealthStore()
                let typesToShare: Set = [
                    HKQuantityType.workoutType()
                ]
                
                let typesToRead: Set = [
                    HKQuantityType.quantityType(forIdentifier: .heartRate)!,
                ]
                healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
                    // Handle errors here.
                    if (success){
                        print("MYDEBUG: Success requesting health")
                    }
                    else{
                        print("MYDEBUG: \(String(describing: error)) \(success)")
                    }
                }
                if isFirstLaunch {
                    isFirstLaunch = false
                    selectedTab = 1
                }
            }
            .padding(.bottom, 16)
            .edgesIgnoringSafeArea(.bottom)  edge of the view
            
            if users.isEmpty || users[0].name == "Tutorial"{
            
                if(showTutorial){
                    TutorialView(showTutorial: $showTutorial)
                }
            }
        }
        

    }
}

