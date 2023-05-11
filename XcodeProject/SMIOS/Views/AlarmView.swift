//
//  AlarmView.swift
//  Smart Watch IOS
//
//  Created by Sebastian Sigurdarson on 7.2.2023.
//

import SwiftUI

struct AlarmView: View {
    
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Alarm.hm, ascending: true)],
        animation: .default)
    private var alarms: FetchedResults<Alarm>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NewSleep.endDate, ascending: true)],
        animation: .default)
    private var newSleeps: FetchedResults<NewSleep>
    
    
    @EnvironmentObject var alarmManager: AlarmManager
    @State var change = false
    @State var text = "no"
    
    
    func deleteDuplicateSleeps() {
        let calendar = Calendar.current
        
        var seenSleeps: [Date: NewSleep] = [:]
        
        for sleep in newSleeps {
            guard let endDate = sleep.endDate else { continue }
            
            let sleepComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: endDate)
            
            if let existingSleep = seenSleeps[endDate] {
                // If there's a sleep object with the same date and minute, delete it
                viewContext.delete(existingSleep)
            } else {
                // Otherwise, add it to the seenSleeps dictionary
                seenSleeps[endDate] = sleep
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving context after deleting duplicate sleeps: \(error)")
        }
    }
    func checkAndAddDeleteNotiffication(alarm: Alarm){
        //Define uniqur strings if they are empty
        if alarm.uuidPhone.isEmpty{
            alarm.uuidPhone = UUID().uuidString
            
        }
        if alarm.on{
            print("MYDEBUG alarm next is \(alarm.giveFront)")
            var hour = Int(alarm.minute) + Int(alarm.giveFront) >= 60 ? Int(alarm.hour) + 1: Int(alarm.hour)
            hour = hour == 24 ? 0 : hour
            
            let minute = Int(alarm.minute) + Int(alarm.giveFront) >= 60 ? Int(alarm.minute) + Int(alarm.giveFront) - 60 : Int(alarm.minute) + Int(alarm.giveFront)
            print("MYDEBUG Backup is set at hour \(hour) and minute \(minute)")
            alarmManager.configureAlarm(hour: hour, minute: minute, uuid: alarm.uuidPhone)
        }
        else{
            alarmManager.removeNotification(uuidString: alarm.uuidPhone)
        }
        
        
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { alarms[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    var body: some View {

        NavigationView(){
            
            VStack{
                
                List{
                    HStack{
                        Label("", systemImage: "alarm").foregroundColor(.white)
                        
                        
                        
                       
                        Text("Alarms").font(.largeTitle).foregroundColor(.white)
                     

                    }
                    
                    ForEach(alarms){alarm in
                        VStack(alignment: .leading, spacing: 0){
                            
                            Toggle(isOn: alarm.on ? .constant(true): .constant(false)){
                                VStack{
                                    let s = alarm.hour<10 && alarm.minute<10 ? "0\(alarm.hour) : 0\(alarm.minute)" : alarm.hour < 10 ? "0\(alarm.hour) : \(alarm.minute)" : alarm.minute<10 ? "\(alarm.hour) : 0\(alarm.minute)": "\(alarm.hour) : \(alarm.minute)"
                                    Text(s).font(.title).bold()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundColor(.white)
                                    HStack{
                                        Text(alarm.name!).font(.footnote).foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                    
                                      Text("Adaptive Wake: \(alarm.giveBack) ~ \(alarm.giveFront)")
                                        .font(.footnote)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundColor(.white)
                                      
                                     
                                }
                                .foregroundColor(.gray)
                                .onAppear{
                                    checkAndAddDeleteNotiffication(alarm: alarm)
                                }

                            }
                            
                            .onTapGesture {
                                if alarm.on{
                                    alarmManager.removeNotification(uuidString: alarm.uuidPhone)
                                }
                                alarm.on = !alarm.on
                                do{
                                    try viewContext.save()
                                }
                                catch{
                             
                                }
                                
                            }
                        }
                        .padding(.all, 20.0)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.gray.opacity(0.01), !alarm.on ? Color.gray.opacity(0.2) : .init(red:0.1, green:0.15, blue: 0.1)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )

                        )
                        .foregroundColor(.gray)
                        .cornerRadius(10)
                    }
                    .onDelete(perform: deleteItems)
                    .listRowBackground(Color.gray.opacity(0.1))
                }
            }
            .toolbar {
                ToolbarItem {
                    NavigationLink{
                        AddAlarmView(isEditing:true)
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                
            }

            
        }
        .navigationBarHidden(true)
        .onAppear{
            deleteDuplicateSleeps()
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            center.removeAllDeliveredNotifications()
        }

       
        
    }
    
}

struct AlarmView_Previews: PreviewProvider {

    static var previews: some View {
        AlarmView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
