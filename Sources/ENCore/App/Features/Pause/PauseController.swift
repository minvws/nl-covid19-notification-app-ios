/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

protocol PauseControlling {
    func showPauseTimeOptions(onViewController viewController: ViewControllable)
    func unpauseExposureManager()
    func getPauseCountdownString(theme: Theme, emphasizeTime: Bool) -> NSAttributedString
    func hidePauseInformationScreen()
    var pauseTimeElapsed: Bool { get }
}

final class PauseController: PauseControlling {

    private let exposureDataController: ExposureDataControlling
    private let exposureController: ExposureControlling
    private let userNotificationCenter: UserNotificationCenter

    init(exposureDataController: ExposureDataControlling,
         exposureController: ExposureControlling,
         userNotificationCenter: UserNotificationCenter) {
        self.exposureDataController = exposureDataController
        self.exposureController = exposureController
        self.userNotificationCenter = userNotificationCenter
    }

    var pauseTimeElapsed: Bool {
        if let pauseEndDate = exposureDataController.pauseEndDate {
            return pauseEndDate.timeIntervalSince(currentDate()) <= 0
        } else {
            return true
        }
    }

    func showPauseTimeOptions(onViewController viewController: ViewControllable) {

        let hourOptions = [1, 2, 4, 8, 12]

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour]
        formatter.unitsStyle = .full

        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        hourOptions.forEach { hours in
            guard let title = formatter.string(from: Double(hours) * 3600) else {
                return
            }

            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                let calendar = Calendar.current
                // TODO: minutes are for testing only
                if let endDate = calendar.date(byAdding: .minute, value: hours, to: currentDate()) {
                    self?.pauseExposureManager(until: endDate)
                }
//                if let endDate = calendar.date(byAdding: .hour, value: hours, to: currentDate()) {
//                    self?.pauseExposureManager(until: endDate)
//                }
            }

            optionMenu.addAction(action)
        }

        optionMenu.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: nil))

        viewController.uiviewController.present(optionMenu, animated: true, completion: nil)
    }

    func hidePauseInformationScreen() {
        exposureDataController.hidePauseInformation = true
    }

    func unpauseExposureManager() {
        exposureController.unpause()

        // TODO:
        // - Re-schedule background tasks
        // - Run background processes (download keys, etc.)
        // - Clear local notification?
    }

    private func pauseExposureManager(until date: Date) {
        exposureController.pause(untilDate: date)

        userNotificationCenter.schedulePauseExpirationNotification(pauseEndDate: date)

        // TODO:
        // - Clear all background tasks
        // - schedule local notification
        //
    }

    func getPauseCountdownString(theme: Theme, emphasizeTime: Bool) -> NSAttributedString {
        guard let countDownDate = exposureDataController.pauseEndDate else {
            return NSAttributedString()
        }

        return PauseController.getPauseCountdownString(theme: theme, endDate: countDownDate, emphasizeTime: emphasizeTime)
    }

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
        let oneMinute: TimeInterval = 60
        guard let time = formatter.string(from: max(timeLeft, oneMinute)) else {
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
