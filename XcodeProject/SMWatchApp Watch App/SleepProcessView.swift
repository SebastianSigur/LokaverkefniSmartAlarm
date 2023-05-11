//
//  SleepProcessView.swift
//  SAOS Watch App
//
//  Created by Sebastian Sigurdarson on 28.2.2023.
//

import SwiftUI
import CoreMotion
import HealthKit
import os.log

struct SleepProcessView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NewSleep.beginDate, ascending: true)],
        animation: .default)
    private var sleeps: FetchedResults<NewSleep>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SleepConfigurations.isSleeping, ascending: true)],
        animation: .default)
    private var sleepConfigurations: FetchedResults<SleepConfigurations>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Alarm.hm, ascending: true)],
        animation: .default)
    private var alarms: FetchedResults<Alarm>
    @State private var showWakeUpView = true
    @State private var alarmMessage: String = ""
    @State private var isQueryPaused = true
    let healthStore = HKHealthStore()
    @State private var isSleeping = false
    @State private var showStartSleepingAlert = false
    @State private var showStopSleepingAlert = false
    @State var currentSleep: NewSleep?
    @State var heartRateDates: [Date] = []
    @State var heartRateSamples: [Double] = []
    
    let apiUrlString = "http://89.17.149.66:5002/predict"
    @State var sleepUUID: UUID?
    @State var laststing = ""
    
    @State var giveFront:Int64?
    @State var giveBack:Int64?
    @State var hm: Int64?
    
    @Environment(\.presentationMode) var presentationMode
    @State private var isPlaying = true
    @State var timer: Timer?
    @State var extendedRuntimeSession: WKExtendedRuntimeSession?
    private func startTimer() {
        guard timer == nil else { return }
        
        // Start the extended runtime session.
        extendedRuntimeSession = WKExtendedRuntimeSession()
        extendedRuntimeSession?.start()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            WKInterfaceDevice.current().play(.success)
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    private func queryHeartRateSamples(startDate: Date, endDate: Date) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let typesToRead: Set = [heartRateType]
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                // Access granted
            } else {
                print("MYDEBUG ACCESS DENIED IN HEALTH STORE")
                // Access denied
            }
        }
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictEndDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { query, results, error in
            if let samples = results as? [HKQuantitySample] {
                let heartRateValues = samples.map {
                    $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                }
                let dates = samples.map { $0.startDate }
                DispatchQueue.main.async {
                    heartRateSamples = heartRateValues
                    heartRateDates = dates
                }
            }
        }

        healthStore.execute(query)
    }
    func printSleepEndDates(sleeps: FetchedResults<NewSleep>) {
        for sleep in sleeps {
            if let endDate = sleep.beginDate {
                print("MYDEBUG: start data is: \(endDate)")
            } else {
                print("MYDEBUG: No start")
            }
        }
    }
    func parseAlarm(alarmString: String) -> (Int, Int)? {
        let components = alarmString.split(separator: ":")
        if components.count == 2, let hour = Int(components[0]), let minute = Int(components[1]) {
            return (hour, minute)
        }
        return nil
    }
    private func startMotionQuery() {
        //Checks to see if data was stored in container
        let currentDate = Date()
        let calendar = Calendar.current
        let currentMinute = calendar.component(.minute, from: currentDate)
        var found = false
        for sleep in sleeps {
            if let startDate = sleep.beginDate {
                if(calendar.component(.minute, from: startDate) == currentMinute){
                    print("MYDEBUG:sleepconf: \(sleepConfigurations[0])")
                    found = true
                    print()
                }
            }
        }
        if(!found){
            print("MYDEBUG:ERROR, NOT FOUND")
            toggleSleep()
            return
        }
        
        let updater = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            let currentDate = Date()
            let calendar = Calendar.current
            let currentHour = calendar.component(.hour, from: currentDate)
            let currentMinute = calendar.component(.minute, from: currentDate)
            print("MYDEBUG STARTING UPDATE")
            let alarmString = findAlarm()
            
           
                if let (alarmHour, alarmMinute) = parseAlarm(alarmString: alarmString) {
                    let adjustedAlarmMinute = alarmMinute + Int(giveFront!)
                    let adjustedAlarmHour = adjustedAlarmMinute >= 60 ? alarmHour + 1 : alarmHour
                    print("MYDEBUG\(alarmString)")
                    print("MYDEBUG\(adjustedAlarmMinute)")
                    print("MYDEBUG:GiveFront is\(alarmHour) and \(alarmMinute)")
                    print("MYDEBUG:other is\(giveFront)")
                    if (adjustedAlarmHour < currentHour || (adjustedAlarmHour == currentHour && adjustedAlarmMinute <= currentMinute)) && abs(adjustedAlarmHour - currentHour) < 2 {
                        DispatchQueue.main.async {
                            if isSleeping {
                                startTimer()
                            }
                        }
                    }
                }

                
            
            
            queryHeartRateSamples(startDate: (currentSleep?.beginDate)!, endDate: Date())
            let urlSession = URLSession.shared
            guard let url = URL(string: apiUrlString) else {
                print("MYDEBUG:Invalid URL")
                return
            }
            let dateFormatter = ISO8601DateFormatter()
            let heartRateDatesStrings = heartRateDates.map { dateFormatter.string(from: $0) }
            let uuidString = sleepUUID
            
            let N = 150
            let requestData = ["startDate": dateFormatter.string(from:(currentSleep?.beginDate)!),
                               "heartRateSamples": Array(heartRateSamples.suffix(N)),
                               "heartRateDates": Array(heartRateDatesStrings.suffix(N)),
                               "NHeart": min(heartRateSamples.count, N),
                               "uuid":uuidString?.uuidString as Any,
                               "alarm":findAlarm(),
                               "giveBack":giveBack as Any,
                               "giveFront":giveFront as Any,
            ]
            print("MYDEBUG: Sending POST")
            let jsonData = try? JSONSerialization.data(withJSONObject: requestData)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
                
            let task = urlSession.dataTask(with: request) { data, response, error in
                print("MYDEBUG: Request sent")
                guard error == nil else {
                    print("Error: \(error!.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("Error: No data received")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("MYDEBUG: Response: \(httpResponse)")
                    let currentMinute = Calendar.current.component(.minute, from: Date())
                    laststing = "\(httpResponse.statusCode) at \(currentMinute)"
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let result = json["NewAlarm"] as? String {
                            print("MYDEBUG: newAlarm is \(result)")
                            
                            let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            
                            if let newAlarmDate = dateFormatter.date(from: result) {
                                let calendar = Calendar.current
                                let alarmHour = calendar.component(.hour, from: newAlarmDate)
                                let alarmMinute = calendar.component(.minute, from: newAlarmDate)
                                let currentHour = calendar.component(.hour, from: Date())
                                let currentMinute = calendar.component(.minute, from: Date())
                                
                                if (alarmHour < currentHour || (alarmHour == currentHour && alarmMinute <= currentMinute)) &&  abs(alarmHour-currentHour) < 2{
                                    
                                    DispatchQueue.main.async {
                                        if isSleeping{
                                            startTimer()
                                        }
                                       
                                    }
                                }
                            }
                        }
                    }
                } catch let error {
                    print("Error: \(error.localizedDescription)")
                }
            }
            task.resume()
        }
        updater.fire()
    }
    func toggleSleep(){
         
        print("MYDEBUG: toggleSleep is pressed. isSleeping is: \(isSleeping)")
        if(isSleeping == false){
            //begin sleeping sleep
            let nextAlarmString = findAlarm()
            isQueryPaused.toggle()
            workoutManager.requestAuthorization(beginAsSoonAsPossible: true)
            let newSleep = NewSleep(context: viewContext)
            let newD = Date()
            newSleep.beginDate = newD
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            sleepConfigurations[0].isSleeping = true
            sleepUUID = UUID()
            sleepConfigurations[0].uuid = sleepUUID
            sleepConfigurations[0].startSleep = newD
        
            print("MYDEBUG: \(nextAlarmString)")
            sleepConfigurations[0].alarm = nextAlarmString
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            isSleeping = true
            
            self.currentSleep = newSleep
            laststing = "startMotionQuery"
            print("MYDEBUG: currentSleep has been set, calling startMotionQuery")
            startMotionQuery()
        }
        else{
            isQueryPaused.toggle()
            for sleep in sleeps{
                if (sleep.endDate == nil){
                    sleep.endDate = Date()
                    sleep.rating = UUID().uuidString
                    do {
                        try viewContext.save()
                    } catch {
                        let nsError = error as NSError
                        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                    }
                }
            }
            
            sleepConfigurations[0].isSleeping = false
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            isSleeping = false
            workoutManager.endWorkout()
            stopTimer()
        }
        
        
       
    }
    func findAlarm() -> String{
        //Find the closest alarm that is available. Returns empty string () ""if no alarm is set
        let currentDate = Date()
        let currentHour = Calendar.current.component(.hour, from: currentDate)
        let currentMinute = Calendar.current.component(.minute, from: currentDate)
        
        for alarm in alarms {
            if alarm.on && (alarm.hour > currentHour || (alarm.hour == currentHour && alarm.minute > currentMinute)) {
                hm = alarm.hm
                giveFront = alarm.giveFront
                giveBack = alarm.giveBack
                if alarm.hour < 10{
                    if alarm.minute < 10{
                        return "0\(alarm.hour):0\(alarm.minute)"
                    }
                    else{
                        return "0\(alarm.hour):\(alarm.minute)"
                    }
                    
                }
                else{
                    if alarm.minute < 10{
                        return "\(alarm.hour):0\(alarm.minute)"
                    }
                    else{
                        return "\(alarm.hour):\(alarm.minute)"
                    }
                }
                
            }
        }
        for alarm in alarms {
            if alarm.on && (alarm.hour < currentHour || (alarm.hour == currentHour && alarm.minute < currentMinute)) {
                hm = alarm.hm
                giveFront = alarm.giveFront
                giveBack = alarm.giveBack
                if alarm.hour < 10{
                    if alarm.minute < 10{
                        return "0\(alarm.hour):0\(alarm.minute)"
                    }
                    else{
                        return "0\(alarm.hour):\(alarm.minute)"
                    }
                    
                }
                else{
                    if alarm.minute < 10{
                        return "\(alarm.hour):0\(alarm.minute)"
                    }
                    else{
                        return "\(alarm.hour):\(alarm.minute)"
                    }
                }
                
            }
        }
        return ""
    }
    var body: some View {
        NavigationView{
            VStack {
                Text("Good Night")
                    .font(.title)
                Image(systemName: "bed.double.fill")
                    .font(.largeTitle)
                    .padding()
                Text((alarmMessage == "No alarm set") ? "" : alarmMessage)
                Button(action: {
                    if isSleeping {
                        showStopSleepingAlert = true
                    } else {
                        
                        let nextAlarmString = findAlarm()
                        if !nextAlarmString.isEmpty{
                            showStartSleepingAlert = true
                        }
                        
                    }
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: isSleeping ? "moon.stars.fill" : "moon.stars")
                            .font(.headline)
                            .foregroundColor(isSleeping ? .red : .green)
                        Text((alarmMessage == "No alarm set") ? alarmMessage: (isSleeping ? "Stop Sleeping" : "Start Sleeping"))
                            .font(.subheadline)
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(20)
                    
                }
            }
            .onAppear{
                printSleepEndDates(sleeps: sleeps)
                print("MYDEBUG: Requesting HealthKit-authorization")
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
                        print("MYDEBUG: \(error) \(success)")
                    }
                }
                printSleepEndDates(sleeps: sleeps)
                //Check if alarm is set
                let nextAlarmString = findAlarm()
                if nextAlarmString.isEmpty {
                    alarmMessage = "No alarm set"
                } else {
                    // Set the alarmMessage to display the next alarm time or any other relevant information
                    alarmMessage = "Next alarm: \(nextAlarmString)"
                }
                
                if(sleepConfigurations.count) == 0{
                    let newConfigurations = SleepConfigurations(context: viewContext)
                    newConfigurations.isSleeping = false
                    do {
                        try viewContext.save()
                    } catch {
                        let nsError = error as NSError
                        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                    }
                    
                }
                isSleeping = sleepConfigurations[0].isSleeping
                if(isSleeping == true){
                    workoutManager.requestAuthorization(beginAsSoonAsPossible: true)
                }
                
            }
            .sheet(isPresented: $showStartSleepingAlert, content: {
                SleepExplanationView(showStartSleepingAlert: $showStartSleepingAlert, toggleSleep: toggleSleep)
            })
            .sheet(isPresented: $showStopSleepingAlert, content: {
                CancelSleepView(showStopSleepingAlert: $showStopSleepingAlert, toggleSleep: toggleSleep)
            })
        }
    }
    
}
struct ProgressCircle: View {
    @Binding var progress: Double

    var body: some View {
        ZStack {
           
            Circle()
                .stroke(lineWidth: 2)
                .opacity(0.3)
                .foregroundColor(Color.black)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.red)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
            
        }
    }
}
struct TimerText: View {
    @Binding var timeRemaining: Int

    var body: some View {
        Text("\(Int((ceil(Double(timeRemaining)/10.0))))")
            .font(.system(size: 14))
            .fontWeight(.bold)
            .foregroundColor(Color.white)
    }
}
struct SleepExplanationView: View {
    @Binding var showStartSleepingAlert: Bool
    var toggleSleep: () -> Void

    var body: some View {
        VStack {
            Text("Begin monitoring?")
                .font(.headline)
            Text("This starts a monitoring process to optimize your wake-up time")
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding()
                .font(.system(size: 15))
                .fixedSize(horizontal: false, vertical: true)
            Button(action: {
                toggleSleep()
                showStartSleepingAlert = false
                
            }, label: {
                Text("Start Sleep")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            })
            Spacer()
        }
        
        
    }
    
}

struct CancelSleepView: View {
    @Binding var showStopSleepingAlert: Bool
    
    @State private var progress: Double = 0.0
    @State private var timeRemaining: Int = 100 //module 10 so 100 would be 10 seconds
    
    var toggleSleep: () -> Void
    var body: some View {

        VStack{
            
            Text("Cancel Sleep")
                .font(.title2)
           
            Text("Make sure to turn of Backup alarm on IPhone")
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding()
                .font(.system(size: 13))
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: {
                toggleSleep()
                showStopSleepingAlert = false
            }, label: {
                ZStack{
                    Text("Cancel Sleep")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                    HStack {
                        Spacer()
                        ZStack {
                            ProgressCircle(progress: $progress)
                                .frame(width: 20, height: 20)
                            TimerText(timeRemaining: $timeRemaining)
                        }

                    }
                }
                
            })
            Spacer()
        }
    }
    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 0.01
            timeRemaining -= 1
            if progress >= 1 {
                timer.invalidate()
                showStopSleepingAlert = false
            }
            
        }
    }
}



