/*
 * Copyright (c) 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
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
