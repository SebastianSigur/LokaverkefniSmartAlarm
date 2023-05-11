//
//  AddAlarmView.swift
//  SmartAlarm IOS
//
//  Created by Sebastian Sigurdarson on 8.2.2023.
//

import SwiftUI
struct SleepIntervalView: View {
    var clockSize: CGFloat
    var sleepStart: Double
    var sleepEnd: Double
    var giveFront: Int64
    var giveBack: Int64
    var body: some View {
        ZStack {
            if timeDiff > 12.0 {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: clockSize, height: clockSize)
            } else {
                let centerPoint = CGPoint(x: clockSize/2, y: clockSize/2)
                let startAngle = Angle(degrees: (sleepStart / 12.0) * 360.0 - 90.0)
                let endAngle = Angle(degrees: (sleepEnd / 12.0) * 360.0 - 90.0)
                
                Path { path in
                    path.addArc(center: centerPoint,
                                radius: clockSize/2,
                                startAngle: endAngle,
                                endAngle: startAngle,
                                clockwise: true)
                    path.addLine(to: centerPoint)
                }
                .fill(Color.blue.opacity(0.2))
                
                if giveFront >= 0 && giveBack >= 0 {
                    let centerPoint = CGPoint(x: clockSize/2, y: clockSize/2)
                    let giveFrontAngle = Angle(degrees: ((sleepEnd+Double(giveFront)/60.0) / 12.0) * 360.0 - 90.0)
                    let giveBackAngle = Angle(degrees: ((sleepEnd-Double(giveBack)/60.0) / 12.0) * 360.0 - 90.0)
                    
                    Path { path in
                        path.addArc(center: centerPoint,
                                    radius: clockSize/2,
                                    startAngle: giveFrontAngle,
                                    endAngle: giveBackAngle,
                                    clockwise: true )
                        path.addLine(to: centerPoint)
                    }
                    .fill(Color.red.opacity(0.2))
                }
            }
        }
    }
    
    private var timeDiff: Double {
        let diff = sleepEnd - sleepStart
        return diff < 0 ? diff + 24 : diff
    }
}

struct ClockHand: Shape {
    var angle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let endPoint = CGPoint(x: center.x + radius * CGFloat(cos(angle.radians - .pi / 2)),
                               y: center.y + radius * CGFloat(sin(angle.radians - .pi / 2)))
        
        path.move(to: center)
        path.addLine(to: endPoint)
        
        return path
    }
}
struct ClockNumber: View {
    var index: Int
    var clockSize: CGFloat

    var body: some View {
        let hourText = index == 0 ? 12 : index
        let positionX = clockSize / 2 * CGFloat(cos(.pi * 2 * Double(index) / 12 - .pi / 2))
        let positionY = clockSize / 2 * CGFloat(sin(.pi * 2 * Double(index) / 12 - .pi / 2))

        return Text("\(hourText)")
            .font(.system(size: clockSize * 0.08))
            .offset(x: positionX, y: positionY)
    }
}
struct ClockView: View {
    var currentTime: Date
    var selectedTime: Date
    var giveFront: Int64
    var giveBack: Int64
    var clockSize: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2)

            ForEach(0..<12) { index in
                ClockNumber(index: index, clockSize: clockSize*0.8)
            }
            SleepIntervalView(clockSize:clockSize, sleepStart: sleepStart, sleepEnd: sleepEnd, giveFront: giveFront, giveBack: giveBack)
            ClockHand(angle: currentAngle)
                .stroke(Color.gray, lineWidth: 1)
                .offset(x: 0, y: 0)
                .frame(width: clockSize * 0.5, height: clockSize * 0.5)

            ClockHand(angle: selectedAngle)
                .stroke(Color.blue, lineWidth: 3)
                .offset(x: 0, y: 0)
                .frame(width: clockSize * 0.5, height: clockSize * 0.5)

            Circle()
                .fill()
                .frame(width: 6, height: 6)
        }
        .frame(width: clockSize, height: clockSize)
    }
    
    private var sleepStart: Double {
        let hour = Double(Calendar.current.component(.hour, from: currentTime))
        let minute = Double(Calendar.current.component(.minute, from: currentTime))
        return hour + minute / 60.0
    }

    private var sleepEnd: Double {
        let hour = Double(Calendar.current.component(.hour, from: selectedTime))
        let minute = Double(Calendar.current.component(.minute, from: selectedTime))
        return hour + minute / 60.0
    }
    private var currentAngle: Angle {
        .degrees(Double(Calendar.current.component(.hour, from: currentTime)) * 360 / 12 + Double(Calendar.current.component(.minute, from: currentTime)) * 360 / (12 * 60))
    }
    
    private var selectedAngle: Angle {
        .degrees(Double(Calendar.current.component(.hour, from: selectedTime)) * 360 / 12 + Double(Calendar.current.component(.minute, from: selectedTime)) * 360 / (12 * 60))
    }
}

struct MiniClockView: View {
    var currentTime: Date
    var selectedTime: Date
    var giveFront: Int64
    var giveBack: Int64
    var body: some View {
            GeometryReader { geometry in
                let clockSize: CGFloat = min(geometry.size.width, geometry.size.height)
                ClockView(currentTime: currentTime, selectedTime: selectedTime, giveFront: giveFront, giveBack: giveBack, clockSize: clockSize)
            }
        }
}


struct AddAlarmView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Alarm.hm, ascending: true)],
        animation: .default)
    private var alarms: FetchedResults<Alarm>
    
    @State private var currentTime: Date = Date()
    @State private var selectedTime: Date = Date()
        
    @State private var selectedHour: Int64 = Int64(Calendar.current.component(.hour, from: Date()))
    @State private var selectedMinute:Int64 = Int64(Calendar.current.component(.minute, from: Date()))
    @State private var name: String = "My Alarm"
    @State private var selectedSound = "Radar"
    @State private var selectedGentleWake = true
    @State private var giveFront: Int64 = 30
    @State private var giveBack: Int64 = 30
    
    var isEditing: Bool
    
    var hours: [Int64] = Array(0...23)
    var minutes: [Int64] = Array(0...59)
    var sounds = ["Radar", "Apex"]
    var leewayOptions: [Int64] = Array(0...60)
    
    private func addAlarm(name:String, sound: String, hour:Int64, minutes:Int64, on:Bool, wakeUpGently:Bool) {
        var maxid: Int64 = -1
        alarms.forEach { _alarm in
            if(maxid == -1 || _alarm.id>maxid){
                maxid = _alarm.id
            }
        }
        withAnimation {
            let newAlarm = Alarm(context: viewContext)
            newAlarm.hour = hour
            newAlarm.minute = minutes
            newAlarm.hm = hour+minutes
            newAlarm.on = on
            newAlarm.name = name
            newAlarm.id = maxid+1
            newAlarm.isNotifying = false
            newAlarm.gentleWake = wakeUpGently
            
        }
    }
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Alarm Time")) {
                        HStack {
                            HStack {
                                Picker("Hour", selection: $selectedHour) {
                                    ForEach(hours, id: \.self) { value in
                                        Text(String(format: "%02d", value))
                                    }
                                }
                                .onChange(of: selectedHour) { newValue in
                                    selectedTime = Calendar.current.date(bySettingHour: Int(newValue), minute: Int(selectedMinute), second: 0, of: Date()) ?? Date()
                                }
                                .pickerStyle(WheelPickerStyle())
                                .labelsHidden()
                                .frame(width: 100)
                                
                                Text(":")
                                
                                Picker("Minute", selection: $selectedMinute) {
                                    ForEach(minutes, id: \.self) { value in
                                        Text(String(format: "%02d", value))
                                    }
                                }
                                .onChange(of: selectedMinute) { newValue in
                                    selectedTime = Calendar.current.date(bySettingHour: Int(selectedHour), minute: Int(newValue), second: 0, of: Date()) ?? Date()
                                }
                                .pickerStyle(WheelPickerStyle())
                                .labelsHidden()
                                .frame(width: 100)
                            }
                            Spacer()
                            MiniClockView(currentTime: currentTime, selectedTime: selectedTime, giveFront: giveFront, giveBack: giveBack)
                                .frame(width: 100, height: 100)
                        }
                    
                    }

                    Section(header: Text("Alarm Name")) {
                        TextField("Name of Alarm", text: $name)
                    }
                    
                    Section(header: Text("Leeway (minutes)")) {
                        HStack {
                
                            VStack(alignment: .leading) {
                                Text("Give Back")
                                    .font(.headline)
                                Picker("Give Back", selection: $giveBack) {
                                    ForEach(leewayOptions, id: \.self) { value in
                                        Text(String(format: "%02d", value))
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .labelsHidden()
                                .frame(width: 100)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Give Front")
                                    .font(.headline)
                                Picker("Give Front", selection: $giveFront) {
                                    ForEach(leewayOptions, id: \.self) { value in
                                        Text(String(format: "%02d", value))
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .labelsHidden()
                                .frame(width: 100)
                                
                            }
                        }
                    }
                }
                
                Spacer()
                
                HStack {
                    NavigationLink(destination: AlarmView()) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGroupedBackground))
                    }
                   
                    NavigationLink(destination: AlarmView()) {
                        Text("Add")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGroupedBackground))
                    }.simultaneousGesture(TapGesture().onEnded{
                        var maxid: Int64 = -1
                        alarms.forEach { _alarm in
                            
                            if(maxid == -1 || _alarm.id>maxid){
                                maxid = _alarm.id
                            }
                        }
                        withAnimation {
                            let newAlarm = Alarm(context: viewContext)
                            newAlarm.hour = selectedHour
                            newAlarm.minute = selectedMinute
                            newAlarm.hm = selectedHour*100+selectedMinute
                            newAlarm.on = true
                            newAlarm.name = name
                            newAlarm.id = maxid+1
                            newAlarm.gentleWake = selectedGentleWake
                            newAlarm.giveFront = giveFront
                            newAlarm.giveBack = giveBack
                            do {
                                try viewContext.save()
                            } catch {
                                let nsError = error as NSError
                                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                            }
                        }
                    })

                }
            }
            .navigationTitle("New Alarm")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct AddAlarmView_Previews: PreviewProvider {
    static var previews: some View {
        AddAlarmView(isEditing: true)
    }
}
