//
//  LastHeartRate.swift
//  SAIOS
//
//  Created by Sebastian Sigurdarson on 18.3.2023.
//

import SwiftUI
import HealthKit
import Combine
struct LastHeartRate: View {
    let healthStore : HKHealthStore
    
    @State private var lastHeartRate: String = "Fetching heart rate..."
    @State private var lastHeartRateDate: Date?
    @State private var cancellables = Set<AnyCancellable>()
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Stats")
                .font(.largeTitle)
                .fontWeight(.bold)
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title)
                VStack(alignment: .leading) {
                    //Text("Last heart rate")
                    //    .font(.headline)
                    Text(lastHeartRate)
                        .font(.system(size: 30))
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(.bottom, 4)
                    if let lastDate = lastHeartRateDate {
                        Text("Last measured \(formattedDate(lastDate))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                Button(action: openInfoWebsite) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.title)
                        .padding(10)
                }
            }
            
        }
        .padding()
        .onAppear(perform: {
            fetchLastHeartRate()
            // Schedule the timer to execute the fetchLastHeartRate function every 10 seconds
            Timer.publish(every: 10, on: .main, in: .common).autoconnect()
                .sink { _ in
                    fetchLastHeartRate()
                }
                .store(in: &cancellables)
        })
    }

    private func fetchLastHeartRate() {
        let sampleType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Requesting authorization to access heart rate data
        healthStore.requestAuthorization(toShare: [], read: [sampleType]) { success, error in
            guard success else {
                print("Authorization failed for heart rate data.")
                return
            }
            
            // Create the sample query to fetch the most recent heart rate sample
            let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { query, results, error in
                if let sample = results?.first as? HKQuantitySample {
                    let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    DispatchQueue.main.async {
                        lastHeartRate = String(format: "%.0f BPM", heartRate)
                        lastHeartRateDate = sample.endDate
                    }
                } else {
                    print("No heart rate samples found.")
                }
            }
            
            // Execute the sample query
            healthStore.execute(query)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        if calendar.isDateInToday(date) {
            formatter.dateTimeStyle = .named
            formatter.formattingContext = .beginningOfSentence
        }
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatDateAsTimeAgo(_ date: Date) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        let now = Date()
        if let timeAgo = formatter.string(from: date, to: now) {
            return "\(timeAgo) ago"
        } else {
            return ""
        }
    }
    
    private func openInfoWebsite() {
        if let url = URL(string: "https://www.heart.org/en/healthy-living/fitness/fitness-basics/target-heart-rates") {
            UIApplication.shared.open(url)
        }
    }
}
