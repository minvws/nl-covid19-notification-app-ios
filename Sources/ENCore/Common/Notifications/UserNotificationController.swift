/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import NotificationCenter
import ENFoundation

/// @mockable(history:removeDeliveredNotifications = true;add=true;removePendingNotificationRequests=true)
protocol UserNotificationCenter {
    func getAuthorizationStatus(completionHandler: @escaping (_ isAuthorized: Bool) -> ())
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> ())
    func getNotificationSettings(completionHandler: @escaping (UNNotificationSettings) -> Void)
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> ())?)
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
    func removeAllPendingNotificationRequests()
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

/// @mockable(history:removeDeliveredNotifications = true;removePendingNotificationRequests=true)
protocol UserNotificationControlling {
    
    // Authorization and Permissions
    func getAuthorizationStatus(completionHandler: @escaping (_ isAuthorized: Bool) -> ())
    func requestNotificationPermission(_ completion: @escaping (() -> ()))
    
    // Removing notifications
    func removeNotificationsFromNotificationsCenter()
    func removeAllPendingNotificationRequests()
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
    
    // Scheduling or displaying actual notifications
    func schedulePauseExpirationNotification(pauseEndDate: Date)
    func displayPauseExpirationReminder(completion: @escaping (_ success: Bool) -> ())
    func displayNotActiveNotification(completion: @escaping (_ success: Bool) -> ())
    func displayAppUpdateRequiredNotification(withUpdateMessage body: String, completion: @escaping (_ success: Bool) -> ())
    func displayExposureNotification(daysSinceLastExposure: Int, completion: @escaping (_ success: Bool) -> ())
    func displayExposureReminderNotification(daysSinceLastExposure: Int, completion: @escaping (_ success: Bool) -> ())
    func display24HoursNoActivityNotification(completion: @escaping (_ success: Bool) -> ())
    func displayUploadFailedNotification()
}

extension UNUserNotificationCenter: UserNotificationCenter {
    func getAuthorizationStatus(completionHandler: @escaping (_ isAuthorized: Bool) -> ()) {
        getNotificationSettings { settings in
            DispatchQueue.main.async {
                completionHandler(settings.authorizationStatus == .authorized)
            }
        }
    }
}

class UserNotificationController: UserNotificationControlling, Logging {
    
    private let userNotificationCenter: UserNotificationCenter
    
    init(userNotificationCenter: UserNotificationCenter = UNUserNotificationCenter.current()) {
        self.userNotificationCenter = userNotificationCenter
    }
        
    func getAuthorizationStatus(completionHandler: @escaping (_ isAuthorized: Bool) -> ()) {
        userNotificationCenter.getAuthorizationStatus(completionHandler: completionHandler)
    }
        
    func requestNotificationPermission(_ completion: @escaping (() -> ())) {
        func request() {
            userNotificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                DispatchQueue.main.async {
                    completion()
                }
            }
        }

        userNotificationCenter.getAuthorizationStatus { isAuthorized in
            if isAuthorized {
                completion()
            } else {
                request()
            }
        }
    }
    
    func removeAllPendingNotificationRequests() {
        userNotificationCenter.removeAllPendingNotificationRequests()
    }
    
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        userNotificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func removeNotificationsFromNotificationsCenter() {

        let identifiers = [
            PushNotificationIdentifier.exposure.rawValue,
            PushNotificationIdentifier.inactive.rawValue,
            PushNotificationIdentifier.enStatusDisabled.rawValue,
            PushNotificationIdentifier.appUpdateRequired.rawValue,
            PushNotificationIdentifier.pauseEnded.rawValue
        ]

        userNotificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func schedulePauseExpirationNotification(pauseEndDate: Date) {

        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.default
        content.title = .notificationAppUnpausedTitle
        content.body = .notificationManualUnpauseDescription
        content.badge = 0

        // Notification is scheduled 30 seconds after the actual pause end date to make it more likely that
        // the app updates correctly if the notification comes in while the app is in the foreground
        let dateComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: pauseEndDate.addingTimeInterval(.seconds(30)))
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        addNotification(withContent: content, identifier: .pauseEnded, trigger: trigger, completion: nil)
    }

    func displayPauseExpirationReminder(completion: @escaping (_ success: Bool) -> ()) {
        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.default
        content.title = .notificationAppUnpausedTitle
        content.body = .notificationManualUnpauseDescription
        content.badge = 0

        addNotification(withContent: content, identifier: .pauseEnded, completion: completion)
    }
    
    func displayNotActiveNotification(completion: @escaping (_ success: Bool) -> ()) {
        let content = UNMutableNotificationContent()
        content.body = .notificationEnStatusNotActive
        content.sound = .default
        content.badge = 0

        addNotification(withContent: content, identifier: .enStatusDisabled, completion: completion)
    }
    
    func displayAppUpdateRequiredNotification(withUpdateMessage body: String, completion: @escaping (_ success: Bool) -> ()) {
        let content = UNMutableNotificationContent()
        content.body = body
        content.sound = .default
        content.badge = 0

        addNotification(withContent: content, identifier: .appUpdateRequired, completion: completion)
    }
    
    func displayExposureNotification(daysSinceLastExposure: Int, completion: @escaping (_ success: Bool) -> ()) {
        let content = UNMutableNotificationContent()
        content.body = .exposureNotificationUserExplanation(.statusNotifiedDaysAgo(days: daysSinceLastExposure))
        content.sound = .default
        content.badge = 0

        addNotification(withContent: content, identifier: .exposure, completion: completion)
    }
    
    func displayExposureReminderNotification(daysSinceLastExposure: Int, completion: @escaping (_ success: Bool) -> ()) {
        let content = UNMutableNotificationContent()
        content.body = .exposureNotificationReminder(.exposureNotificationUserExplanation(.statusNotifiedDaysAgo(days: daysSinceLastExposure)))
        content.sound = .default
        content.badge = 0

        addNotification(withContent: content, identifier: .exposure, completion: completion)
    }
    
    func display24HoursNoActivityNotification(completion: @escaping (_ success: Bool) -> ()) {
        let content = UNMutableNotificationContent()
        content.title = .statusAppStateInactiveTitle
        content.body = String(format: .statusAppStateInactiveNotification)
        content.sound = UNNotificationSound.default
        content.badge = 0

        addNotification(withContent: content, identifier: .inactive, completion: completion)
    }
    
    func displayUploadFailedNotification() {
        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.default
        content.body = .notificationUploadFailedNotification
        content.badge = 0

        let date = currentDate()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        var trigger: UNNotificationTrigger?
        // Make sure notification is only shown during GGD opening hours
        if hour > 20 || hour < 8 {
            var dateComponents = DateComponents()
            dateComponents.hour = 8
            dateComponents.minute = 0
            dateComponents.timeZone = TimeZone(identifier: "Europe/Amsterdam")
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        }
        
        addNotification(withContent: content, identifier: .uploadFailed, trigger: trigger)
    }
    
    private func addNotification(withContent content: UNNotificationContent, identifier: PushNotificationIdentifier, trigger: UNNotificationTrigger? = nil, completion: ((_ success: Bool) -> ())? = nil) {
        
        userNotificationCenter.getAuthorizationStatus { (isAuthorized) in
            
            guard isAuthorized else {
                completion?(false)
                return self.logError("Not authorized to post notifications")
            }

            let request = UNNotificationRequest(identifier: identifier.rawValue,
                                                content: content,
                                                trigger: trigger)

            self.userNotificationCenter.add(request) { error in
                guard let error = error else {
                    self.logDebug("Did send local notification `\(content)`")
                    completion?(true)
                    return
                }
                
                self.logError("Error posting notification: \(identifier.rawValue) \(error.localizedDescription)")
                completion?(false)
            }
        }
    }

    
}
