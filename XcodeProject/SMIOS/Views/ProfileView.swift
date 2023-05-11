//
//  ProfileView.swift
//  S-AIOS
//
//  Created by Sebastian Sigurdarson on 8.2.2023.
//

import UserNotifications
import SwiftUI
struct ProfileView: View {
    @State var sleepGoal = 8.0
    @State var darkMode = false
    @State var notifications = true
    @State  var personName = "John Doe"
    // used to measure more accurately sleep cycles
    @State var age: Int64 = 20
    @State var male: Bool = true
    @State var weight: Int64 = 86
    @State var reportBug = ""
    @State var showConfirmation = false
    
    
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)],
        animation: .default)
    private var users: FetchedResults<User>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Alarm.hm, ascending: true)],
        animation: .default)
    private var alarms: FetchedResults<Alarm>
    @EnvironmentObject var alarmManager: AlarmManager
    
    @State var user: User?
    
    func toggleAllAlarmsOff() {
        for alarm in alarms {
            if alarm.on {
                alarmManager.removeNotification(uuidString: alarm.uuidPhone)
                alarm.on = false
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func updateNotificationSettings() {
        let center = UNUserNotificationCenter.current()
        
        if notifications {
            // Requesting notification authorization
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("Error requesting authorization: \(error.localizedDescription)")
                } else {
                    // Enable or disable features based on the authorization
                    DispatchQueue.main.async {
                        notifications = granted
                    }
                }
            }
        } else {
            // Removeing all pending and delivered notifications
            center.removeAllPendingNotificationRequests()
            center.removeAllDeliveredNotifications()
        }
    }
    
    public func report(){
        //let apiUrlString = "http://89.160.211.107:5002/reportBug"
        let apiUrlString = "http://89.17.149.66:5002/reportBug"
        let requestData = ["bug": reportBug] as [String : Any]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: requestData)
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 500
        
        let urlSession = URLSession(configuration: configuration)
        
        guard let url = URL(string: apiUrlString) else {
            print("MYDEBUG:Invalid URL")
            return
        }
        
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
        }
        task.resume()
    }
    public func save(){
        users[0].sleepGoal = sleepGoal
        
        users[0].enableNotifications = notifications
        users[0].name = personName
        // used to measure more accurately sleep cycles
        users[0].age = age
        users[0].weight = weight
        users[0].male = male
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
                
                TextField("Name", text: $personName)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .gesture(self.onTapGestureToEndEditing())
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Sleep Goal")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Hours:")
                            .foregroundColor(.gray)
                        
                        Slider(value: $sleepGoal, in: 1...12, step: 0.5)
                        
                        Text("\(sleepGoal, specifier: "%.1f")")
                            .foregroundColor(.secondary)
                    }
                }
                VStack(alignment: .center, spacing: 10) {
                    Text("Age")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Stepper(value: $age, in: 0...120) {
                        Text("\(age)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                VStack(alignment: .center, spacing: 10) {
                    Text("Weight")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Stepper(value: $weight, in: 0...300, step: 1) {
                        Text("\(weight) kg")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                
                
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Report a bug")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $reportBug)
                        .foregroundColor(.primary)
                        .frame(height: 80)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                        .onTapGesture {
                                    self.endEditing()
                                }
                    Button(action: {
                        // Submit bug report here
                        showConfirmation = true
                        report()
                        reportBug = ""
                        self.endEditing()
                    }) {
                        Text("Submit")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(reportBug.isEmpty)
                    .opacity(reportBug.isEmpty ? 0.5 : 1.0)
                }
                
                Toggle(isOn: $notifications) {
                    Text("Enable Notifications")
                    
                    
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .onChange(of: notifications) { value in
                    if !value {
                        toggleAllAlarmsOff()
                    }
                }
                Text("Toggling this off will also disable all alarms")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding([.top, .leading, .trailing], 20)
        }
        .sheet(isPresented: $showConfirmation) {
            VStack {
                Text("Bug Report Submitted")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.bottom, 20)
                
                Button(action: {
                    showConfirmation = false
                }) {
                    Text("OK")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.3),  Color.black]),
                    startPoint: .top,
                    endPoint: .bottom
                )

        )
        .onAppear{
            if(users.count != 0){
                sleepGoal = users[0].sleepGoal
                
                notifications = users[0].enableNotifications
                personName = users[0].name!
                // used to measure more accurately sleep cycles
                age = users[0].age
                weight = users[0].weight
                male = users[0].male
                
            }
            else{
                let newUser = User(context: viewContext)
                newUser.sleepGoal = sleepGoal
                
                newUser.enableNotifications = notifications
                newUser.name = personName
                // used to measure more accurately sleep cycles
                newUser.age = age
                newUser.weight = weight
                newUser.male = male
                
                do {
                    try viewContext.save()
                } catch {
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
               
        }
        .onChange(of: sleepGoal) { _ in
            save()
        }
        .onChange(of: notifications) { _ in
            save()
            updateNotificationSettings()
        }
        
        .onChange(of: personName) { _ in
            save()
        }
        .onChange(of: age) { _ in
            save()
        }
        .onChange(of: male) { _ in
            save()
        }
        .onChange(of: weight) { _ in
            save()
        }
        
        
    }
        
    
}

extension View {
    func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func onTapGestureToEndEditing() -> some Gesture {
        TapGesture().onEnded { _ in
            self.endEditing()
        }
    }
}
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
