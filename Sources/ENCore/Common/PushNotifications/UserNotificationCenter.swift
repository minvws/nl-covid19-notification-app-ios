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

    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> ())?)

    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
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

    func schedulePauseExpirationNotification(pauseEndDate: Date) {

        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.default
        content.body = .notificationManualUnpauseDescription
        content.badge = 0

        let dateComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: pauseEndDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(identifier: PushNotificationIdentifier.pauseEnded.rawValue,
                                            content: content,
                                            trigger: trigger)

        self.add(request, withCompletionHandler: nil)
    }
}
