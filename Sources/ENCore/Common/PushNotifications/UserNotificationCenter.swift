/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import NotificationCenter

/// @mockable
protocol UserNotificationCenter {
    /// Gets the authroization status and returns the result on the main thread.
    func getAuthorizationStatus(completionHandler: @escaping (UNAuthorizationStatus) -> ())
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> ())
    func requestNotificationPermission(_ completion: @escaping (() -> ()))

    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> ())?)

    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
    func removeAllPendingNotificationRequests()
    func removeNotificationsFromNotificationsCenter()

    // Pause notifications
    func schedulePauseExpirationNotification(pauseEndDate: Date)
    func displayPauseExpirationReminder(completion: @escaping () -> ())
}

extension UNUserNotificationCenter: UserNotificationCenter {

    func getAuthorizationStatus(completionHandler: @escaping (UNAuthorizationStatus) -> ()) {
        getNotificationSettings { settings in
            DispatchQueue.main.async {
                completionHandler(settings.authorizationStatus)
            }
        }
    }
}

extension UserNotificationCenter {

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

        let dateComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: pauseEndDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(identifier: PushNotificationIdentifier.pauseEnded.rawValue,
                                            content: content,
                                            trigger: trigger)

        self.add(request, withCompletionHandler: nil)
    }

    func displayPauseExpirationReminder(completion: @escaping () -> ()) {
        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.default
        content.title = .notificationAppUnpausedTitle
        content.body = .notificationManualUnpauseDescription
        content.badge = 0

        let request = UNNotificationRequest(identifier: PushNotificationIdentifier.pauseEnded.rawValue,
                                            content: content,
                                            trigger: nil)

        self.add(request) { _ in
            completion()
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
}
