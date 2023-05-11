//
//  WorkoutManager.swift
//  SAOS Watch App
//
//  Created by Sebastian Sigurdarson on 14.2.2023.
//

import Foundation
import HealthKit
import SwiftUI

class WorkoutManager: NSObject, ObservableObject{
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    func startWorkout(){
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .unknown
        
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            print("MYDEBUG:Unable to connect")
            return
        }
        
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                          workoutConfiguration: configuration)
        
        session?.delegate = self
        builder?.delegate = self
        
        //Finally, start the session and the builder.
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            
            guard success else {
                print("MYDEBUG:beginCollectionNotStarted")
                print("MYDEBUG:\(String(describing: error))")
                // Handle errors.
                return
            }
            print("MYDEBUG:HasStarted")
            // Indicate that the session has started.
            
        }
        print("MYDEBUG:STARTWORKOUT")
    }
    
    func requestAuthorization(beginAsSoonAsPossible: Bool){
        print("MYDEBUG:AUT")
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            // Handle errors here.
            if (success && beginAsSoonAsPossible){
                self.startWorkout()
            }
            else{
                print("MYDEBUG: \(error) \(success)")
            }
        }
        
    }
    
    

    @Published var running = false
    
    func pause(){
        session?.pause()
    }
    func resume(){
        session?.resume()
    }
    
    
    func endWorkout(){
        self.session!.end() //Crashes here if there is no session started.
        self.builder!.endCollection(withEnd: Date()) { (success, error) in
            
            guard success else {
                // Handle errors.
                return
            }
            
            self.builder!.finishWorkout { (workout, error) in
                
                guard workout != nil else {
                    // Handle errors.
                    return
                }
                
                DispatchQueue.main.async() {
                    // Update the user interface.
                    
                }
            }
        }
    }
    
    @Published var heartRate: Double = 0
    @Published var lastCheck: Date?

    func getDiff(oldDate: Date) -> Int{
        let elapsed = Date().timeIntervalSince(oldDate)
        let duration = Int(elapsed)
        return duration
        
    }
    
    func updateForStatistics(_ statistics: HKStatistics?){
        guard let statistics = statistics else {return}
        
        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.lastCheck = Date()
               
            default:
                return
            }
        }
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate{
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async{
            self.running = toState == .running
        }
        if toState == .ended{
            builder?.endCollection(withEnd: date){ (success, error) in
                self.builder?.finishWorkout{(workout, error) in
                    
                }
                
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
    
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate{
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        
        let lastEvent = workoutBuilder.workoutEvents.last
        
        DispatchQueue.main.async() {
            // Update the user interface here.
            
            
            
        }
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }
            
            // Calculate statistics for the type.
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            
            updateForStatistics(statistics)
        }
    }
    
}
