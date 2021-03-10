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
    /// Gets the authroization status and returns the result on the main thread.
    func getAuthorizationStatus(completionHandler: @escaping (UNAuthorizationStatus) -> ())
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> ())
    func requestNotificationPermission(_ completion: @escaping (() -> ()))

    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> ())?)

    func removeNotificationsFromNotificationsCenter()
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
    func removeAllPendingNotificationRequests()
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])

    // Scheduling or displaying actual notifications
    func schedulePauseExpirationNotification(pauseEndDate: Date)
    func displayPauseExpirationReminder(completion: @escaping () -> ())
    func displayNotActiveNotification(completion: @escaping () -> ())
    func displayAppUpdateRequiredNotification(withUpdateMessage body: String, completion: @escaping () -> ())
    func displayExposureReminderNotification(exposureDaysAgo days: Int, completion: @escaping () -> ())
    func display24HoursNoActivityNotification(completion: @escaping () -> ())
}

extension UNUserNotificationCenter: UserNotificationCenter, Logging {

    func getAuthorizationStatus(completionHandler: @escaping (UNAuthorizationStatus) -> ()) {
        getNotificationSettings { settings in
            DispatchQueue.main.async {
                completionHandler(settings.authorizationStatus)
            }
        }
    }
    
    func requestNotificationPermission(_ completion: @escaping (() -> ())) {
        func request() {
            requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                DispatchQueue.main.async {
                    completion()
                }
            }
        }

        getAuthorizationStatus { authorizationStatus in
            if authorizationStatus == .authorized {
                completion()
            } else {
                request()
            }
        }
    }

    func removeNotificationsFromNotificationsCenter() {

        let identifiers = [
            PushNotificationIdentifier.exposure.rawValue,
            PushNotificationIdentifier.inactive.rawValue,
            PushNotificationIdentifier.enStatusDisabled.rawValue,
            PushNotificationIdentifier.appUpdateRequired.rawValue,
            PushNotificationIdentifier.pauseEnded.rawValue
        ]

        removeDeliveredNotifications(withIdentifiers: identifiers)
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

    func displayPauseExpirationReminder(completion: @escaping () -> ()) {
        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.default
        content.title = .notificationAppUnpausedTitle
        content.body = .notificationManualUnpauseDescription
        content.badge = 0

        addNotification(withContent: content, identifier: .pauseEnded, completion: completion)
    }
    
    func displayNotActiveNotification(completion: @escaping () -> ()) {
        let content = UNMutableNotificationContent()
        content.body = .notificationEnStatusNotActive
        content.sound = .default
        content.badge = 0

        addNotification(withContent: content, identifier: .enStatusDisabled, completion: completion)
    }
    
    func displayAppUpdateRequiredNotification(withUpdateMessage body: String, completion: @escaping () -> ()) {
        let content = UNMutableNotificationContent()
        content.body = body
        content.sound = .default
        content.badge = 0

        addNotification(withContent: content, identifier: .appUpdateRequired, completion: completion)
    }
    
    func displayExposureReminderNotification(exposureDaysAgo days: Int, completion: @escaping () -> ()) {
        let content = UNMutableNotificationContent()
        content.body = .exposureNotificationReminder(.exposureNotificationUserExplanation(.statusNotifiedDaysAgo(days: days)))
        content.sound = .default
        content.badge = 0

        addNotification(withContent: content, identifier: .exposure, completion: completion)
    }
    
    func display24HoursNoActivityNotification(completion: @escaping () -> ()) {
        let content = UNMutableNotificationContent()
        content.title = .statusAppStateInactiveTitle
        content.body = String(format: .statusAppStateInactiveNotification)
        content.sound = UNNotificationSound.default
        content.badge = 0

        addNotification(withContent: content, identifier: .inactive, completion: completion)
    }
    
    private func addNotification(withContent content: UNNotificationContent, identifier: PushNotificationIdentifier, trigger: UNNotificationTrigger? = nil, completion: (() -> ())?) {
        
        getAuthorizationStatus { status in
            guard status == .authorized else {
                completion?()
                return self.logError("Not authorized to post notifications")
            }

            let request = UNNotificationRequest(identifier: identifier.rawValue,
                                                content: content,
                                                trigger: trigger)

            self.add(request) { error in
                guard let error = error else {
                    self.logDebug("Did send local notification `\(content)`")
                    completion?()
                    return
                }
                
                self.logError("Error posting notification: \(identifier.rawValue) \(error.localizedDescription)")
                completion?()
            }
        }
    }

    
}
