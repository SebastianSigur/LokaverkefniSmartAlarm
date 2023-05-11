//
//  StatsView.swift
//  S-AIOS
//
//  Created by Sebastian Sigurdarson on 8.2.2023.
//

import SwiftUI
import HealthKit
import LineChartView
import Charts

struct StatsView: View {
    
    let MINSLEEP = 1 // 60*5
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NewSleep.beginDate, ascending: true)],
        animation: .default)
    private var sleeps: FetchedResults<NewSleep>
    @State private var showTutorial = false
    let healthStore = HKHealthStore()
    func printSleepEndDates(sleeps: FetchedResults<NewSleep>) {
        for sleep in sleeps {
            if let endDate = sleep.beginDate {
                print("MYDEBUG: start data is: \(endDate), startDate is : \(sleep.endDate)")
            } else {
                print("MYDEBUG: No start")
            }
        }
    }
    func sleepText(sleep: NewSleep) -> String {
        guard let beginDate = sleep.beginDate, let endDate = sleep.endDate else {
            return "No sleep data available"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        return "Sleep from \(dateFormatter.string(from: beginDate)) to \(dateFormatter.string(from: endDate))"
    }
    var body: some View {
        NavigationView {
            VStack {
               
                Spacer().frame(height: 10)
                ScrollView {
                    LastHeartRate(healthStore: healthStore)
                    if !sleeps.isEmpty {
                        if let lastSleepWithDurationGreaterThanT = getLastSleepWithDurationGreaterThanT(from: sleeps, minimumDuration: TimeInterval(MINSLEEP)) {
                            
                            VStack {
                                Text("Last Sleep Cycle")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .init(red: 0.2, green: 0.2, blue: 0.9)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomLeading
                                        )
                                    )
                                    
                               
                                heartRateChartView(
                                    healthStore: healthStore,
                                    beginDate: lastSleepWithDurationGreaterThanT.beginDate,
                                    endDate: lastSleepWithDurationGreaterThanT.endDate,
                                    uuid: UUID(uuidString: lastSleepWithDurationGreaterThanT.rating ?? "NIL")
                                )
                                .frame(height: 500)
                                .cornerRadius(20)
                                .padding(20)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal, 20) // Add horizontal padding here to the whole VStack
                           
                            Spacer()
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "zzz")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.gray)
                                    .frame(width: 50, height: 50)
                                Text("No reliable sleep data available")
                                    .foregroundColor(.gray)
                                    .font(.headline)
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "zzz")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.gray)
                                .frame(width: 50, height: 50)
                            Text("No sleep data available")
                                .foregroundColor(.gray)
                                .font(.headline)
                        }
                    }
                    
                    NavigationLink(destination: AllSleepHeartViews(healthStore: healthStore)) {
                        Text("Check out your sleep cycles")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.vertical, 20)
                    
                    SleepTips()
                    Button("Show Tutorial") {
                        self.showTutorial = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
            }
            .sheet(isPresented: $showTutorial) {
                        TutorialView(showTutorial: $showTutorial)
                    }
        }
        .onAppear{
            printSleepEndDates(sleeps: sleeps)
        }

    }


    
    
    
   

    
    

    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d - h:mm a"
        return dateFormatter.string(from: date)
    }
    
    func getLastSleepWithDurationGreaterThanT(from sleeps: FetchedResults<NewSleep>, minimumDuration T: TimeInterval) -> NewSleep? {
        let filteredSleeps = sleeps.filter { sleep in
            let duration = sleep.endDate?.timeIntervalSince(sleep.beginDate!)

            return duration ?? -Double.infinity >= T
        }
        
        return filteredSleeps.last
    }


    
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}

