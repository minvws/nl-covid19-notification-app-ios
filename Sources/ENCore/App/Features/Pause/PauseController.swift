/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

/// @mockable
protocol PauseControlling {
    var pauseTimeElapsed: Bool { get }
    var isAppPaused: Bool { get }

    func getPauseTimeOptionsController() -> UIAlertController
    func unpauseApp()
    func getPauseCountdownString(theme: Theme, emphasizeTime: Bool) -> NSAttributedString
    func hidePauseInformationScreen()
}

#if USE_DEVELOPER_MENU || DEBUG

    struct PauseOverrides {
        static var useMinutesInsteadOfHours = false
    }

#endif

final class PauseController: PauseControlling, Logging {

    private let exposureDataController: ExposureDataControlling
    private let exposureController: ExposureControlling
    private let userNotificationCenter: UserNotificationCenter
    private let backgroundController: BackgroundControlling

    init(exposureDataController: ExposureDataControlling,
         exposureController: ExposureControlling,
         userNotificationCenter: UserNotificationCenter,
         backgroundController: BackgroundControlling) {
        self.exposureDataController = exposureDataController
        self.exposureController = exposureController
        self.userNotificationCenter = userNotificationCenter
        self.backgroundController = backgroundController
    }

    var isAppPaused: Bool {
        return exposureDataController.isAppPaused
    }

    var pauseTimeElapsed: Bool {
        if let pauseEndDate = exposureDataController.pauseEndDate {
            return pauseEndDate.timeIntervalSince(currentDate()) <= 0
        } else {
            return true
        }
    }

    // MARK: - Pausing and unpausing

    func getPauseTimeOptionsController() -> UIAlertController {

        let timeOptions = [1, 2, 4, 8, 12]

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full

        #if USE_DEVELOPER_MENU || DEBUG
            formatter.allowedUnits = PauseOverrides.useMinutesInsteadOfHours ? [.minute] : [.hour]
        #else
            formatter.allowedUnits = [.hour]
        #endif

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        timeOptions.forEach { timeOption in

            #if USE_DEVELOPER_MENU || DEBUG
                let pauseInterval: TimeInterval = PauseOverrides.useMinutesInsteadOfHours ? .minutes(Double(timeOption)) : .hours(Double(timeOption))
            #else
                let pauseInterval: TimeInterval = .hours(timeOption)
            #endif

            guard let title = formatter.string(from: pauseInterval) else {
                return
            }

            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                let calendar = Calendar.current

                #if USE_DEVELOPER_MENU || DEBUG
                    let calendarComponentToAdd: Calendar.Component = PauseOverrides.useMinutesInsteadOfHours ? .minute : .hour
                #else
                    let calendarComponentToAdd: Calendar.Component = .hour
                #endif

                if let endDate = calendar.date(byAdding: calendarComponentToAdd, value: timeOption, to: currentDate()) {
                    self?.pauseApp(until: endDate)
                }
            }

            alertController.addAction(action)
        }

        alertController.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: nil))

        return alertController
    }

    private func pauseApp(until date: Date) {

        logInfo("Pausing app until \(date)")

        exposureController.pause(untilDate: date)

        // Remove any currently pending notifications
        userNotificationCenter.removeAllPendingNotificationRequests()

        // Schedule the notification to inform the user of elapsed pause state
        userNotificationCenter.schedulePauseExpirationNotification(pauseEndDate: date)
    }

    func unpauseApp() {

        logInfo("Unpausing app")

        // Mark app as unpaused (also starts downloading and processing keys if necessary)
        exposureController.unpause()

        // Cancel unpause reminder notification
        userNotificationCenter.removeDeliveredNotifications(withIdentifiers: [PushNotificationIdentifier.pauseEnded.rawValue])
    }

    func hidePauseInformationScreen() {
        exposureDataController.hidePauseInformation = true
    }

    func getPauseCountdownString(theme: Theme, emphasizeTime: Bool) -> NSAttributedString {
        guard let countDownDate = exposureDataController.pauseEndDate else {
            return NSAttributedString()
        }

        return PauseController.getPauseCountdownString(theme: theme, endDate: countDownDate, emphasizeTime: emphasizeTime)
    }

    /// Helper function to get an attributed string description of the time left until the end of the chosen pause time.
    /// If the pause time has expired, it will return a text indicating to the user that the app needs to be manually unpaused
    /// - Parameters:
    ///   - theme: Theme userd for text color and font
    ///   - endDate: The time at which the pause state should end
    ///   - center: Indicates if the paragraph of text needs to be centered or not
    ///   - emphasizeTime: Indicates if the time mentioned in the next needs bold formatting
    /// - Returns: An AttributedString with a countdown text
    static func getPauseCountdownString(theme: Theme, endDate: Date, center: Bool = false, emphasizeTime: Bool) -> NSAttributedString {

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full

        let timeLeft = endDate.timeIntervalSince(currentDate())

        guard timeLeft > 0 else {
            let attributedString = NSMutableAttributedString(attributedString: NSAttributedString.makeFromHtml(
                text: .statusPausedManualUnpause,
                font: theme.fonts.body,
                textColor: theme.colors.gray,
                textAlignment: Localization.isRTL ? .right : .left
            ))
            return center ? attributedString.centered() : attributedString
        }

        // We max out the timeinterval that is left to make sure we never show "0 minutes left" but we always show "1 minute" left in that case
        guard let time = formatter.string(from: max(timeLeft, .minutes(1))) else {
            return NSAttributedString()
        }

        var completeString = NSMutableAttributedString(attributedString: NSAttributedString.makeFromHtml(
            text: String(format: .statusPausedCountdown, arguments: [time]),
            font: theme.fonts.body,
            textColor: theme.colors.gray,
            textAlignment: Localization.isRTL ? .right : .left
        ))

        if emphasizeTime, let timeRange = completeString.string.range(of: time) {
            let nsRange = NSRange(timeRange, in: completeString.string)
            completeString.addAttributes([.font: theme.fonts.bodyBold], range: nsRange)
        }

        if center {
            completeString = completeString.centered()
        }

        return completeString
    }
}
