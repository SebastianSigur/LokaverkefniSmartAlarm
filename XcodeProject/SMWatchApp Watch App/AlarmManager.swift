//
//  AlarmManager.swift
//  SAOS Watch App
//
//  Created by Sebastian Sigurdarson on 15.2.2023.
//

import Foundation
import UserNotifications
import AVFoundation
import WatchConnectivity

class AlarmManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    let content = UNMutableNotificationContent()

    func configureAlarm(hour: Int, minute: Int, uuid:String = "", uuid2:String = ""){
        
        
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        
        #if os(watchOS)
        content.title = NSString.localizedUserNotificationString(forKey: "Alarm", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: "Time to wake up :)", arguments: nil)
        content.interruptionLevel = .critical
        
        
        
        let trigger = UNCalendarNotificationTrigger(
                 dateMatching: dateComponents, repeats: true)
        let uuidString = uuid.isEmpty ? UUID().uuidString : uuid
        
        let request = UNNotificationRequest(identifier: uuidString,
                    content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .criticalAlert]) { (granted, error) in
            print("MYDEBUG:ERRORAUTH \(error) and \(granted)")
        }
        
        center.add(request) { (error : Error?) in
             if let theError = error {
                 // Handle any errors
             }
        }
        content.title = NSString.localizedUserNotificationString(forKey: "Good Morning", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: "Let's get ready for a new day", arguments: nil)
        content.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: 1.0)
        content.interruptionLevel = .critical
        dateComponents.minute = minute
        
        let uuidString2 = uuid2.isEmpty ? UUID().uuidString : uuid2
        let trigger2 = UNCalendarNotificationTrigger(
                 dateMatching: dateComponents, repeats: true)
        let request2 = UNNotificationRequest(identifier: uuidString2,
                    content: content, trigger: trigger2)
        
        center.add(request2) { (error : Error?) in
             if let theError = error {
                 // Handle any errors
             }
        }
        #else
        
        content.title = NSString.localizedUserNotificationString(forKey: "Alarm", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: "Time to wake up", arguments: nil)

        let soundName = UNNotificationSoundName(rawValue: "ringtone.mp3")
        content.sound = UNNotificationSound(named: soundName)
        content.interruptionLevel = .critical
        dateComponents.minute = minute
        dateComponents.second = 0

        // Create and register the custom notification category
        let myCategoryIdentifier = "myPersistentCategory"
        let myCategory = UNNotificationCategory(
            identifier: myCategoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "",
            options: [.customDismissAction]
        )
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([myCategory])

        // Assign the custom notification category to the content
        content.categoryIdentifier = myCategoryIdentifier

        let uuidString = uuid.isEmpty ? UUID().uuidString : uuid
        center.requestAuthorization(options: [.alert, .sound, .criticalAlert]) { (granted, error) in
            print("MYDEBUG:ERRORAUTH \(String(describing: error)) and \(granted)")
        }
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: uuidString,
                        content: content, trigger: trigger)

        center.add(request) { (error : Error?) in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {

            }
        }

        #endif
        
        

    }
    func reset(){
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
    }
    func removeNotification(uuidString: String){
        let center = UNUserNotificationCenter.current()
        

        center.removePendingNotificationRequests(withIdentifiers: [uuidString])

        
    }

}
