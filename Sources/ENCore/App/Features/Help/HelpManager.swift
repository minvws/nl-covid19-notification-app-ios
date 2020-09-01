/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import UIKit

/// @mockable
protocol HelpManaging {
    var entries: [HelpOverviewEntry] { get }
}

final class HelpManager: HelpManaging {
    let entries: [HelpOverviewEntry]

    init() {
        let reason = HelpQuestion(question: .helpFaqReasonTitle, answer: .helpFaqReasonDescription)
        let location = HelpQuestion(question: .helpFaqLocationTitle, answer: .helpFaqLocationDescription)
        let anonymous = HelpQuestion(question: .helpFaqAnonymousTitle, answer: .helpFaqAnonymousDescription1 + "\n\n" + .helpFaqAnonymousDescription2)
        let notification = HelpQuestion(question: .helpFaqNotificationTitle, answer: .helpFaqNotificationDescription)
        let bluetooth = HelpQuestion(question: .helpFaqBluetoothTitle, answer: .helpFaqBluetoothDescription)
        let power = HelpQuestion(question: .helpFaqPowerUsageTitle, answer: .helpFaqPowerUsageDescription)

        let notificationExplanation = HelpOverviewEntry.notificationExplanation(title: String.moreInformationCellReceivedNotificationTitle,
                                                                                linkedContent: [
                                                                                    HelpOverviewEntry.question(notification),
                                                                                    HelpOverviewEntry.question(reason),
                                                                                    HelpOverviewEntry.question(bluetooth)
                                                                                ])

        entries = [
            .question(reason.appending(linkedContent: [
                HelpOverviewEntry.question(location),
                notificationExplanation
            ])),

            .question(location.appending(linkedContent: [
                HelpOverviewEntry.question(bluetooth)
            ])),

            .question(anonymous.appending(linkedContent: [
                notificationExplanation,
                HelpOverviewEntry.question(location)
            ])),

            .question(notification.appending(linkedContent: [
                notificationExplanation,
                HelpOverviewEntry.question(bluetooth)
            ])),

            notificationExplanation,

            .question(bluetooth.appending(linkedContent: [
                HelpOverviewEntry.question(notification),
                HelpOverviewEntry.question(anonymous)
            ])),

            .question(power.appending(linkedContent: [
                HelpOverviewEntry.question(reason)
            ]))
        ]
    }
}
