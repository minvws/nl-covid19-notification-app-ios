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
    func getAuthorizationStatus(completionHandler: @escaping (_ status: NotificationAuthorizationStatus) -> ())
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> ())
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> ())?)
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
    func removeAllPendingNotificationRequests()
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

/// @mockable(history:removeDeliveredNotifications = true;removePendingNotificationRequests=true)
protocol UserNotificationControlling {
    
    // Authorization and Permissions
    func getAuthorizationStatus(completionHandler: @escaping (_ status: NotificationAuthorizationStatus) -> ())
    func getIsAuthorized(completionHandler: @escaping (_ isAuthorized: Bool) -> ())
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

/// Internal representation mirroring UNAuthorizationStatus
enum NotificationAuthorizationStatus: Int {
    // The user has not yet made a choice regarding whether the application may post user notifications.
    case notDetermined = 0
    
    // The application is not authorized to post user notifications.
    case denied = 1
    
    // The application is authorized to post user notifications.
    case authorized = 2
    
    // The application is authorized to post non-interruptive user notifications.
    @available(iOS 12.0, *)
    case provisional = 3
    
    // The application is temporarily authorized to post notifications. Only available to app clips.
    @available(iOS 14.0, *)
    case ephemeral = 4
}

extension UNUserNotificationCenter: UserNotificationCenter {
    func getAuthorizationStatus(completionHandler: @escaping (_ status: NotificationAuthorizationStatus) -> ()) {
        getNotificationSettings { settings in
            DispatchQueue.main.async {
                let status = NotificationAuthorizationStatus(rawValue: settings.authorizationStatus.rawValue) ?? .notDetermined
                completionHandler(status)
            }
        }
    }
}

class UserNotificationController: UserNotificationControlling, Logging {
    
    private let userNotificationCenter: UserNotificationCenter
    
    init(userNotificationCenter: UserNotificationCenter = UNUserNotificationCenter.current()) {
        self.userNotificationCenter = userNotificationCenter
    }
    
    // MARK: - UserNotificationControlling
    
    func getIsAuthorized(completionHandler: @escaping (_ isAuthorized: Bool) -> ()) {
        userNotificationCenter.getAuthorizationStatus { (status) in
            completionHandler(status == .authorized)
        }
    }
    
    func getAuthorizationStatus(completionHandler: @escaping (_ status: NotificationAuthorizationStatus) -> ()) {
        userNotificationCenter.getAuthorizationStatus(completionHandler: completionHandler)
    }
            
    func requestNotificationPermission(_ completion: @escaping (() -> ())) {
        
        userNotificationCenter.getAuthorizationStatus { authorizationStatus in
            if authorizationStatus == .authorized {
                completion()
                return
            }
            
            self.userNotificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                DispatchQueue.main.async {
                    completion()
                }
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
        
        // Notification is scheduled 30 seconds after the actual pause end date to make it more likely that
        // the app updates correctly if the notification comes in while the app is in the foreground
        let dateComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: pauseEndDate.addingTimeInterval(.seconds(30)))
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        addNotification(title: .notificationAppUnpausedTitle,
                        body: .notificationManualUnpauseDescription,
                        identifier: .pauseEnded,
                        trigger: trigger)
    }

    func displayPauseExpirationReminder(completion: @escaping (_ success: Bool) -> ()) {
        
        addNotification(title: .notificationAppUnpausedTitle,
                        body: .notificationManualUnpauseDescription,
                        identifier: .pauseEnded,
                        completion: completion)
    }
    
    func displayNotActiveNotification(completion: @escaping (_ success: Bool) -> ()) {
        
        addNotification(body: .notificationEnStatusNotActive,
                        identifier: .enStatusDisabled,
                        completion: completion)
    }
    
    func displayAppUpdateRequiredNotification(withUpdateMessage body: String, completion: @escaping (_ success: Bool) -> ()) {
        
        addNotification(body: body,
                        identifier: .appUpdateRequired,
                        completion: completion)
    }
    
    func displayExposureNotification(daysSinceLastExposure: Int, completion: @escaping (_ success: Bool) -> ()) {
        
        addNotification(body: .exposureNotificationUserExplanation(.statusNotifiedDaysAgo(days: daysSinceLastExposure)),
                        identifier: .exposure,
                        completion: completion)
    }
    
    func displayExposureReminderNotification(daysSinceLastExposure: Int, completion: @escaping (_ success: Bool) -> ()) {
        
        addNotification(body: .exposureNotificationReminder(.exposureNotificationUserExplanation(.statusNotifiedDaysAgo(days: daysSinceLastExposure))),
                        identifier: .exposure,
                        completion: completion)
    }
    
    func display24HoursNoActivityNotification(completion: @escaping (_ success: Bool) -> ()) {
        
        addNotification(title: .statusAppStateInactiveTitle,
                        body: .statusAppStateInactiveNotification,
                        identifier: .inactive,
                        completion: completion)
    }
    
    func displayUploadFailedNotification() {

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
        
        addNotification(body: .notificationUploadFailedNotification, identifier: .uploadFailed, trigger: trigger)
    }
    
    // MARK: - Private
    
    private func addNotification(title: String = "", body: String, identifier: PushNotificationIdentifier, trigger: UNNotificationTrigger? = nil, completion: ((_ success: Bool) -> ())? = nil) {
        
        userNotificationCenter.getAuthorizationStatus { (authorizationStatus) in
            
            guard authorizationStatus == .authorized else {
                completion?(false)
                return self.logError("Not authorized to post notifications")
            }

            let content = UNMutableNotificationContent()
            content.sound = UNNotificationSound.default
            content.title = title
            content.body = body
            content.badge = 0
            
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
