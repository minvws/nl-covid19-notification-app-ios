/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import NotificationCenter

/// @mockable(history:removeDeliveredNotifications = true;removePendingNotificationRequests=true;displayAppUpdateRequiredNotification=true)
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
    func removeScheduledRemoteNotification()

    // Scheduling or displaying actual notifications
    func schedulePauseExpirationNotification(pauseEndDate: Date)
    func displayPauseExpirationReminder(completion: @escaping (_ success: Bool) -> ())
    func displayNotActiveNotification(completion: @escaping (_ success: Bool) -> ())
    func displayAppUpdateRequiredNotification(withUpdateMessage body: String, completion: @escaping (_ success: Bool) -> ())
    func displayExposureNotification(daysSinceLastExposure: Int, completion: @escaping (_ success: Bool) -> ())
    func displayExposureReminderNotification(daysSinceLastExposure: Int, completion: @escaping (_ success: Bool) -> ())
    func display24HoursNoActivityNotification(completion: @escaping (_ success: Bool) -> ())
    func displayUploadFailedNotification()
    func scheduleRemoteNotification(title: String, body: String, date: DateComponents, targetScreen: String)
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

class UserNotificationController: UserNotificationControlling, Logging {
    private let userNotificationCenter: UserNotificationCenter

    init(userNotificationCenter: UserNotificationCenter = UNUserNotificationCenter.current()) {
        self.userNotificationCenter = userNotificationCenter
    }

    // MARK: - UserNotificationControlling

    func getIsAuthorized(completionHandler: @escaping (_ isAuthorized: Bool) -> ()) {
        userNotificationCenter.getAuthorizationStatus { status in
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

    func removeScheduledRemoteNotification() {
        removePendingNotificationRequests(withIdentifiers: [PushNotificationIdentifier.remoteScheduled.rawValue])
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
        addNotification(title: .notificationEnStatusNotActiveTitle,
                        body: .notificationEnStatusNotActive,
                        identifier: .enStatusDisabled,
                        completion: completion)
    }

    func displayAppUpdateRequiredNotification(withUpdateMessage body: String, completion: @escaping (_ success: Bool) -> ()) {
        addNotification(title: .notificationUpdateAppTitle,
                        body: body,
                        identifier: .appUpdateRequired,
                        completion: completion)
    }

    func displayExposureNotification(daysSinceLastExposure: Int, completion: @escaping (_ success: Bool) -> ()) {
        addNotification(title: .exposureNotificationUserExplanationTitle,
                        body: .exposureNotificationUserExplanation(.statusNotifiedDaysAgo(days: daysSinceLastExposure)),
                        identifier: .exposure,
                        completion: completion)
    }

    func displayExposureReminderNotification(daysSinceLastExposure: Int, completion: @escaping (_ success: Bool) -> ()) {
        addNotification(title: .exposureNotificationUserExplanationTitle,
                        body: .exposureNotificationReminder(.exposureNotificationUserExplanation(.statusNotifiedDaysAgo(days: daysSinceLastExposure))),
                        identifier: .exposure,
                        completion: completion)
    }

    func display24HoursNoActivityNotification(completion: @escaping (_ success: Bool) -> ()) {
        addNotification(title: .statusAppStateInactiveNotificationTitle,
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

        addNotification(title: .notificationUploadFailedNotificationTitle,
                        body: .notificationUploadFailedNotification,
                        identifier: .uploadFailed,
                        trigger: trigger)
    }

    func scheduleRemoteNotification(title: String, body: String, date: DateComponents, targetScreen: String) {
        removeScheduledRemoteNotification()

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)

        addNotification(title: title,
                        body: body,
                        identifier: .remoteScheduled,
                        trigger: trigger,
                        userInfo: ["targetScreen": targetScreen])
    }

    // MARK: - Private

    private func addNotification(
        title: String = "",
        body: String,
        identifier: PushNotificationIdentifier,
        trigger: UNNotificationTrigger? = nil,
        userInfo: [AnyHashable: Any] = [:],
        completion: ((_ success: Bool) -> ())? = nil
    ) {
        userNotificationCenter.getAuthorizationStatus { [weak self] authorizationStatus in

            guard let strongSelf = self else { return }

            guard authorizationStatus == .authorized else {
                completion?(false)
                return strongSelf.logError("Not authorized to post notification with identifier \(identifier.rawValue)")
            }

            let content = UNMutableNotificationContent()
            content.sound = UNNotificationSound.default
            content.title = title
            content.body = body
            content.badge = 0
            content.userInfo = userInfo

            let request = UNNotificationRequest(identifier: identifier.rawValue,
                                                content: content,
                                                trigger: trigger)

            strongSelf.userNotificationCenter.add(request) { error in

                guard let error = error else {
                    strongSelf.logDebug("Did send local notification `\(content)`")
                    completion?(true)
                    return
                }

                strongSelf.logError("Error posting notification: \(identifier.rawValue). \(error.localizedDescription)")
                completion?(false)
            }
        }
    }
}
