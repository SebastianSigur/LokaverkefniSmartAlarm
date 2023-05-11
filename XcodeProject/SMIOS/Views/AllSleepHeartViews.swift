//
//  AllSleepHeartViews.swift
//  SAIOS
//
//  Created by Sebastian Sigurdarson on 20.3.2023.
//

import SwiftUI
import HealthKit


enum TimeFilter: Hashable {
    case lastDays(Int)
    case lastWeek
    case lastMonth
    case lastYear
    case all
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .lastDays(let days):
            hasher.combine("lastDays")
            hasher.combine(days)
        case .lastWeek:
            hasher.combine("lastWeek")
        case .lastMonth:
            hasher.combine("lastMonth")
        case .lastYear:
            hasher.combine("lastYear")
        case .all:
            hasher.combine("all")
        }
    }
}

struct AllSleepHeartViews: View {
    let healthStore : HKHealthStore
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NewSleep.beginDate, ascending: false)],
        animation: .default)
    private var sleeps: FetchedResults<NewSleep>
    
    // Set the minimum duration for a sleep (in seconds)
    private let minimumSleepDuration: TimeInterval = 60*5
    
    // Set the time range for each filter
    private let lastDaysFilterRange: TimeInterval = 24 * 60 * 60
    
    // Set the current time for calculating filter ranges
    private let now = Date()
    
    // Set the current time zone for calculating filter ranges
    private let timeZone = TimeZone.current
    
    // Set the selected filter
    @State private var selectedFilter: TimeFilter = .all
    
    var body: some View {
        VStack {
            Picker("Time Filter", selection: $selectedFilter) {
                Text("Last 7 Days").tag(TimeFilter.lastDays(7))
                Text("Last 30 Days").tag(TimeFilter.lastDays(30))
                Text("Last Year").tag(TimeFilter.lastYear)
                Text("All Time").tag(TimeFilter.all)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            ScrollView {
                ForEach(removeDuplicateUUIDs(from: sleeps), id: \.self) { sleep in
                    if let duration = sleep.endDate?.timeIntervalSince(sleep.beginDate!),
                           duration >= minimumSleepDuration,
                           duration <= (24 * 60 * 60),
                       sleepInRange(sleep, for: selectedFilter) {
                        VStack {
                            Text("\(formatDate(sleep.beginDate!)) - \(formatDate(sleep.endDate!))")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue)
                            heartRateChartView(
                                healthStore: healthStore,
                                beginDate: sleep.beginDate,
                                endDate: sleep.endDate,
                                uuid: UUID(uuidString: sleep.rating ?? "NIL")
                            )
                            .frame(height: 500)
                            .cornerRadius(10)
                            .padding(20)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .onAppear {
                            print("MYDEBUG: Rating is \(sleep.rating ?? "NIL")")
                        }
                        
                    }
                }
            }
            
            
        }
    }
    func removeDuplicateUUIDs(from sleeps: FetchedResults<NewSleep>) -> [NewSleep] {
        var uniqueSleeps: [NewSleep] = []
        var uuidSet: Set<String> = []
        
        for sleep in sleeps {
            if let uuid = sleep.rating,
               !uuidSet.contains(uuid),
               UUID(uuidString: uuid) != nil {
                uuidSet.insert(uuid)
                uniqueSleeps.append(sleep)
            }
        }
        
        return uniqueSleeps
    }
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d h:mm a"
        return dateFormatter.string(from: date)
    }
    
    func sleepInRange(_ sleep: NewSleep, for filter: TimeFilter) -> Bool {
        switch filter {
        case .lastDays(let days):
            guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: now) else {
                return false
            }
            return sleep.beginDate! >= startDate
            
        case .lastWeek:
            guard let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now) else {
                return false
            }
            return sleep.beginDate! >= startDate
            
        case .lastMonth:
            guard let startDate = Calendar.current.date(byAdding: .month, value: -1, to: now) else {
                return false
            }
            return sleep.beginDate! >= startDate
            
        case .lastYear:
            guard let startDate = Calendar.current.date(byAdding: .year, value: -1, to: now) else {
                return false
            }
            return sleep.beginDate! >= startDate
            
        case .all:
            return true
        }
    }
}
