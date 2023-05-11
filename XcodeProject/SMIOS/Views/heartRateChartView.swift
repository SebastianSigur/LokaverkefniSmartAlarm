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
extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        let sum = reduce(0, +)
        return Double(sum) / Double(count)
    }
}
enum SleepStage: Int {
    case inBed = 0
    case asleep = 1
    case awake = 2
    case REM = 3
    case light = 4
    case deep = 5
}

struct heartRateChartView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SleepStages.uuid, ascending: true)],
        animation: .default)
    private var sleepStages: FetchedResults<SleepStages>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \User.sleepGoal, ascending: true)],
        animation: .default)
    private var users: FetchedResults<User>
    
    
    let healthStore : HKHealthStore
    let beginDate : Date?
    let endDate : Date?
    let uuid : UUID?
    @State var isSaving = false //Used to prevent saving data recursivly
    @State var heartRateSamples: [Double] = []
    @State var heartRateDates: [Date] = []
    @State var showDataOption1 = true
    @State var sleepSamples: [HKCategorySample] = []
    @State var currentSleepStages: [Int] = []
    
    //let apiUrlString = "http://89.160.211.107:5002/get_sleep_pattern"
   // let apiUrlString = "http://89.160.211.107:5002/get_sleep_pattern"
    let apiUrlString = "http://89.17.149.66:5002/get_sleep_pattern"
    var body: some View {
        let zipSequence = zip(heartRateSamples, heartRateDates)
        VStack {
            Spacer()
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            // Toggle the showBlueButton boolean when the red button is pressed
                            if !showDataOption1{
                                showDataOption1.toggle()
                            }
                            
                        }) {
                            Text("Heart Rate")
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(30)
                            
                        }
                        .opacity(showDataOption1 ? 1.0 : 0.3)
                        
                        Button(action: {
                            if showDataOption1{
                                showDataOption1.toggle()
                            }
                        }) {
                            currentSleepStages.isEmpty ?
                            Text("Loading")
                           
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(30)
                            :
                            Text("Sleep Cycle")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(30)
                        }
                        .opacity(showDataOption1 ? 0.3 : 1)
                        Spacer()
                    }
                }
                ZStack{
                    
                    
                    
                    
                    LineChartView(lineChartParameters: chartParameters)
                        .padding()
                        .frame(height: geometry.size.height)
                    
                        .zIndex(showDataOption1 ? 3 : 2)
                        .opacity(showDataOption1 ? 1.0 : 0.3)
                    
                    LineChartView(lineChartParameters: chartParametersBackground)
                        .padding()
                        .frame(height: geometry.size.height)
                        .opacity(showDataOption1 ? 0.3 : 1)
                        .zIndex(showDataOption1 ? 2 : 3)
                    
                }
                .padding(.top)
                
                
                
            }
            
            
            Spacer()
            
            VStack {
                HStack {
                    Text(dateFormatter.string(from: heartRateDates.first ?? Date()))
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(dateFormatter.string(from: heartRateDates.last ?? Date()))
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            Spacer()
            HStack {
                VStack {
                    HStack {
                        Text("Avg:")
                            .foregroundColor(.orange)
                            .font(.subheadline)
                        Text("\(Int(heartRateSamples.average ?? 0)) bpm")
                            .font(.subheadline)
                    }
                    HStack {
                        Text("Peak:")
                            .foregroundColor(.green)
                            .font(.subheadline)
                        Text("\(Int(heartRateSamples.max() ?? 0)) bpm")
                            .font(.subheadline)
                    }
                    HStack {
                        Text("Lowest:")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                        Text("\(Int(heartRateSamples.min() ?? 0)) bpm")
                            .font(.subheadline)
                    }
                    HStack {
                        Text("Highest:")
                            .foregroundColor(.purple)
                            .font(.subheadline)
                        Text("\(Int(heartRateSamples.max() ?? 0)) bpm")
                            .font(.subheadline)
                    }
                    
                }
                
                Spacer()
                
                VStack {
                    HStack {
                        Text("Duration:")
                            .foregroundColor(.pink)
                            .font(.subheadline)
                        Text("\(Int((endDate?.timeIntervalSince(beginDate!) ?? 0) / 60.rounded())) min")
                        
                            .font(.subheadline)
                    }
                    HStack {
                        
                        Text("Rating:")
                            .foregroundColor(.red)
                            .font(.subheadline)
                        
                        Text("4 stars").font(.subheadline)
                    
                    }

                    
                }
            }
            Spacer()
            
            
        }
        .onAppear {
            queryHeartRateSamples(startDate: beginDate!, endDate: endDate ?? Date())
            
        }
    }
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        return df
    }
    var chartParameters: LineChartParameters {
        
        let zipSequence = zip(heartRateSamples, heartRateDates)
        let df = DateFormatter()
        df.dateFormat = "MMM d, HH:mm"
        
        let MAXPOINTS = 100;
        
        let count = zipSequence.reduce(0) { count, _ in count + 1 }
        var points: [LineChartData];
        print("MYDEBUG: count is \(count)")
        if count <= MAXPOINTS{
            
            points = zipSequence.map {(v1, v2) in
                LineChartData(v1,timestamp: v2, label: df.string(from: v2))
            }
        }
        else{
            let stepSize = count / MAXPOINTS
            let filteredSequence = zipSequence.enumerated().filter { (index, _) in
                index % stepSize == 0
            }
            points = filteredSequence.map { (_, arg1) in
                
                let (v1, v2) = arg1
                return LineChartData(v1, timestamp: v2, label: df.string(from: v2))
            }
            print("MYDEBUG modifies points are: ",points.count)
        }

        return LineChartParameters(
            data:points,
            dataPrecisionLength: 0,
            dataSuffix: " bpm",
            indicatorPointColor: .blue,
            indicatorPointSize: 20,
            lineColor:.red,
            lineSecondColor:.orange,
            dotsWidth: 8,
            hapticFeedback: true

        )
    }
    var chartParametersBackground: LineChartParameters {

        let zipSequence = zip(currentSleepStages , heartRateDates)
        let sleepStages = ["Awake", "Light", "REM", "Deep"]
        let df = DateFormatter()
        df.dateFormat = "MMM d, HH:mm"
        
        let MAXPOINTS = 100;
        
        let count = zipSequence.reduce(0) { count, _ in count + 1 }
        var points: [LineChartData];
        print("MYDEBUG: count is \(count)")
        if count <= MAXPOINTS{
            let startDate = heartRateDates.first ?? Date()
            let endDate = startDate.addingTimeInterval(30 * 60)
            
            
            points = zipSequence.map {(v1, v2) in
                let stage = sleepStages[v1]
                if v2 <= endDate {
                    return LineChartData(Double(3), timestamp: v2, label: "\(df.string(from: v2)) - \(stage)")
                } else {
                    return LineChartData(Double(3-v1), timestamp: v2, label: "\(df.string(from: v2)) - \(stage)")
                }
               
            }
            print("MYDEBUG: \(startDate)")
        }
        else{
            let stepSize = count / MAXPOINTS
            let filteredSequence = zipSequence.enumerated().filter { (index, _) in
                index % stepSize == 0
            }
            let startDate = heartRateDates.first ?? Date()
            let endDate = startDate.addingTimeInterval(30 * 60)
            points = filteredSequence.map { (_, arg1) in
                
                let (v1, v2) = arg1
                let stage = sleepStages[v1]
                if v2 <= endDate {
                    return LineChartData(3,timestamp: v2, label: "\(df.string(from: v2)) - \(stage)")
                } else {
                    return LineChartData(Double(3-v1),timestamp: v2, label: "\(df.string(from: v2)) - \(stage)")
                }
               
            }
            print("MYDEBUG modifies points are: ",points.count)
        }

        return LineChartParameters(
            data: points,
            dataPrecisionLength: 0,
            dataSuffix: "",
            indicatorPointColor: .blue,
            indicatorPointSize: 20,
            lineColor: .blue,
            lineSecondColor: .purple,
            dotsWidth: 1,
            hapticFeedback: false)
    }

            
            
    

   
    private func queryHeartRateSamples(startDate: Date, endDate: Date) {
        DispatchQueue.global(qos: .background).async {
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
                        
                        // Move the API request code here
                        let heartRateDatesStrings = heartRateDates.map { dateFormatter.string(from: $0) }
                        let requestData = ["startDate": dateFormatter.string(from:(beginDate!)),
                                           "heartRateSamples": Array(heartRateSamples),
                                           "heartRateDates": Array(heartRateDatesStrings),
                        ] as [String : Any]
                        
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
                            
                            guard let data = data else {
                                print("Error: No data received")
                                return
                            }
                            
                            if let httpResponse = response as? HTTPURLResponse {
                                print("MYDEBUG: Response: \(httpResponse)")
                                let currentMinute = Calendar.current.component(.minute, from: Date())
                                print("MYDEBUG: Response: \(httpResponse)")
                            }
                            
                            do {
                                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                    if let result = json["pred"] as? [Int] {
                                        currentSleepStages = result
                                        
                                        
                                    }
                                    else{
                                        print("MYDEBUG:ERROR; Not able to print")
                                    }
                                }
                            } catch let error {
                                print("Error: \(error.localizedDescription)")
                            }
                        }
                        task.resume()
                    }
                }
            }
            
            healthStore.execute(query)
            
        }
    }
    
}


