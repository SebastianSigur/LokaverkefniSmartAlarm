//
//  HeartRateView.swift
//  S-AwatchOS Watch App
//
//  Created by Sebastian Sigurdarson on 14.2.2023.
//

import SwiftUI
import HealthKit
import CoreMotion

private struct MetricsTimeLineScheddule: TimelineSchedule{
    var startDate: Date
    
    init(from startDate: Date) {
        self.startDate = startDate
    }
    func entries(from startDate: Date, mode: TimelineScheduleMode) -> PeriodicTimelineSchedule.Entries {
        PeriodicTimelineSchedule(from: self.startDate, by: mode == .lowFrequency ? 1.0 : 1.0 / 30.0).entries(from: startDate, mode: mode)
    }
}
struct HeartRateView: View {

    
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var alarmManager: AlarmManager
    
    @State private var xAcceleration: Double = 0.0
    @State private var yAcceleration: Double = 0.0
    @State private var zAcceleration: Double = 0.0
    let apiUrlString = "https://sebastiansigur.pythonanywhere.com/"
    let motionManager = CMMotionManager()
    
    private func startMotionQuery() {
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if motionManager.isDeviceMotionAvailable {
                motionManager.deviceMotionUpdateInterval = 0.1
                motionManager.startDeviceMotionUpdates(to: .main) { (data, error) in
                    guard let data = data else { return }
                    xAcceleration = data.userAcceleration.x
                    yAcceleration = data.userAcceleration.y
                    zAcceleration = data.userAcceleration.z
                }
            } else {
                print("MYDEBUG: Device motion is not available")
            }
        }
        timer.fire()
    }

    var body: some View {
        TimelineView(
            MetricsTimeLineScheddule(
                from:workoutManager.builder?.startDate ?? Date()
            )
        ){ context in
            VStack{
                Image(systemName: "heart")
                    .frame(width: 20, height: 20)
                    .foregroundColor(.red)
                Text("Current BPM: \(workoutManager.heartRate)")
                
               

                Button(action: {
                    let urlSession = URLSession.shared
                    guard let url = URL(string: apiUrlString) else {
                        print("MYDEBUG:Invalid URL")
                        return
                    }

                    let requestData = ["heartRate": 80]
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
                        }

                        do {
                            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                if let result = json["result"] as? Bool {
                                    
                                }
                            }
                        } catch let error {
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                    task.resume()

                }) {
                    Text("SendData")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .background(Color.blue)
                .cornerRadius(8)
                .background(Color.blue)
                .cornerRadius(8)
                
                workoutManager.lastCheck != nil
                ?
                VStack{
                    Text("Last checked \(workoutManager.getDiff(oldDate: workoutManager.lastCheck!))s ago")
                        
                }
                :
                
                VStack{

                    Text("Measuring...")

                   
                    
                    
                    
                }
            }
            
        }
        .onAppear{
            startMotionQuery()
        }
    }
        
}


