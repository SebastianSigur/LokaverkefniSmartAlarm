//
//  AlarmsViewMini.swift
//  S-AwatchOS Watch App
//
//  Created by Sebastian Sigurdarson on 14.2.2023.
//

import SwiftUI

struct AlarmsViewMini: View {
    @EnvironmentObject var alarmManager: AlarmManager
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Alarm.hm, ascending: true)],
        animation: .default)
    private var alarms: FetchedResults<Alarm>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NewSleep.endDate, ascending: true)],
        animation: .default)
    private var newSleeps: FetchedResults<NewSleep>
    
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NewSleep.beginDate, ascending: true)],
        animation: .default)
    private var sleeps: FetchedResults<NewSleep>
  
    func sleepText(sleep: NewSleep) -> String {
        guard let beginDate = sleep.beginDate, let endDate = sleep.endDate else {
            return "No sleep data available"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        return "Sleep from \(dateFormatter.string(from: beginDate)) to \(dateFormatter.string(from: endDate))"
    }
    
    
    
    func checkAndAddDeleteNotiffication(alarm: Alarm){
        //Define uniqur strings if they are empty
        if alarm.uuidWatch1.isEmpty{
            alarm.uuidWatch1 = UUID().uuidString
        }
        if alarm.uuidWatch2.isEmpty{
            alarm.uuidWatch2 = UUID().uuidString
        }
        if alarm.on{
            alarmManager.configureAlarm(hour: Int(alarm.hour), minute: Int(alarm.minute), uuid: alarm.uuidWatch1)
        }
        else{
            alarmManager.removeNotification(uuidString: alarm.uuidWatch1)
            alarmManager.removeNotification(uuidString: alarm.uuidWatch2)
        }
        
        
    }
    var body: some View{
        VStack{
           
            List{
                HStack{
                    Text("Alarms").font(.largeTitle).foregroundColor(.red)
                }
                ForEach(alarms){alarm in
                    VStack(alignment: .leading, spacing: 0){
                        
                        Toggle(isOn: alarm.on ? .constant(true): .constant(false)){
                            VStack{
                                let s = alarm.hour<10 && alarm.minute<10 ? "0\(alarm.hour) : 0\(alarm.minute)" : alarm.hour < 10 ? "0\(alarm.hour) : \(alarm.minute)" : alarm.minute<10 ? "\(alarm.hour) : 0\(alarm.minute)": "\(alarm.hour) : \(alarm.minute)"
                                Text(s).font(.title2
                                ).bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                VStack{
                                    HStack{
                                        Text(alarm.name!).font(.footnote)
                                        Spacer()
                                    }
                                    HStack{
                                        Text(alarm.gentleWake ? "Smart" : "Normal ").font(.caption2)
                                        Spacer()
                                    }
                                    
                                }
                            }
                            .onAppear{
                                checkAndAddDeleteNotiffication(alarm: alarm)
                            }
                            
                        }
                        .onTapGesture {
                            alarm.on = !alarm.on
                            do {
                                try viewContext.save()
                            }
                            catch{
                                let nsError = error as NSError
                                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                            }
                        }
                    }
                    .onAppear{
                        
                    }
                    .padding([.top, .bottom, .trailing], 20.0)
                    .frame(height:80)
                    
                    
                }
            }
        }
       
    }
}

struct AlarmsViewMini_Previews: PreviewProvider {
    static var previews: some View {
        AlarmsViewMini()
    }
}
