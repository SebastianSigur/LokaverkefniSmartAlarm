//
//  ContentView.swift
//  S-AwatchOS Watch App
//
//  Created by Sebastian Sigurdarson on 8.2.2023.
//

import SwiftUI
import HealthKit
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Alarm.hm, ascending: true)],
        animation: .default)
    private var alarms: FetchedResults<Alarm>
    
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var alarmManager: AlarmManager
    @State var isAlarmOn: Int64 = 23*10+59+1 //Used to indenitfy alarm. Cannot be over 23*10+59+1 which means no alarm


    var body: some View {
        
        TabView() {
            
            AlarmsViewMini()
                .tabItem(){
                    
                    
                }
            SleepProcessView()
                .environmentObject(workoutManager)
            /*
            HeartRateView()
                .environmentObject(workoutManager)
                .onAppear{
                    print("MYDEBUG:START")
                    workoutManager.requestAuthorization(beginAsSoonAsPossible: true)
                    
                }
                .onDisappear{
                    workoutManager.endWorkout()
                }
                .tabItem(){
                    
                    
                }
             */
            
        }
   
        
    }



    
}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {

        ContentView()
    }
}
