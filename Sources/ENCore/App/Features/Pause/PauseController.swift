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
    func getPauseCountdownString(theme: Theme) -> NSAttributedString
}

final class PauseController: PauseControlling {

    private let exposureDataController: ExposureDataControlling
    private let exposureController: ExposureControlling

    init(exposureDataController: ExposureDataControlling,
         exposureController: ExposureControlling) {
        self.exposureDataController = exposureDataController
        self.exposureController = exposureController
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
                if let endDate = calendar.date(byAdding: .hour, value: hours, to: currentDate()) {
                    self?.pauseExposureManager(until: endDate)
                }
            }

            optionMenu.addAction(action)
        }

        optionMenu.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: nil))

        viewController.uiviewController.present(optionMenu, animated: true, completion: nil)
    }

    func unpauseExposureManager() {
        exposureController.unpause()
    }

    private func pauseExposureManager(until date: Date) {
        exposureController.pause(untilDate: date)
    }

    func getPauseCountdownString(theme: Theme) -> NSAttributedString {

        guard let countDownDate = exposureDataController.pauseEndDate else {
            return NSAttributedString()
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full

        let timeLeft = countDownDate.timeIntervalSince(currentDate())

        guard timeLeft > 0,
            let time = formatter.string(from: timeLeft) else {

            return NSAttributedString.makeFromHtml(
                text: .statusPausedManualUnpause,
                font: theme.fonts.body,
                textColor: theme.colors.gray,
                textAlignment: Localization.isRTL ? .right : .left
            )
        }

        let completeString = NSMutableAttributedString(attributedString: NSAttributedString.makeFromHtml(
            text: String(format: .statusPausedCountdown, arguments: [time]),
            font: theme.fonts.body,
            textColor: theme.colors.gray,
            textAlignment: Localization.isRTL ? .right : .left
        ))

        if let timeRange = completeString.string.range(of: time) {
            let nsRange = NSRange(timeRange, in: completeString.string)
            completeString.addAttributes([.font: theme.fonts.bodyBold], range: nsRange)
        }

        return completeString
    }
}
