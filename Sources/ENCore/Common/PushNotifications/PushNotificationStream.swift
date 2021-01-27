/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation
import NotificationCenter

enum PushNotificationIdentifier: String {
    case exposure = "nl.rijksoverheid.en.exposure"
    case inactive = "nl.rijksoverheid.en.inactive"
    case uploadFailed = "nl.rijksoverheid.en.uploadFailed"
    case enStatusDisabled = "nl.rijksoverheid.en.statusDisabled"
    case appUpdateRequired = "nl.rijksoverheid.en.appUpdateRequired"
    case pauseEnded = "nl.rijksoverheid.en.pauseended"

    static func allIdentifiers() -> [PushNotificationIdentifier] {
        return [
            .exposure,
            .inactive,
            .uploadFailed,
            .enStatusDisabled,
            .appUpdateRequired,
            .pauseEnded
        ]
    }
}

/// @mockable
protocol PushNotificationStreaming {
    var pushNotificationStream: AnyPublisher<UNNotificationResponse, Never> { get }
    var foregroundNotificationStream: AnyPublisher<UNNotification, Never> { get }
}

/// @mockable
protocol MutablePushNotificationStreaming: PushNotificationStreaming {
    func update(response: UNNotificationResponse)
    func update(notification: UNNotification)
}

final class PushNotificationStream: MutablePushNotificationStreaming {

    // MARK: - PushNotificationStreaming

    var pushNotificationStream: AnyPublisher<UNNotificationResponse, Never> {
        return pushNotificationSubject
            .removeDuplicates(by: ==)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    var foregroundNotificationStream: AnyPublisher<UNNotification, Never> {
        return foregroundNotificationSubject
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - MutablePushNotificationStreaming

    func update(response: UNNotificationResponse) {
        pushNotificationSubject.send(response)
    }

    func update(notification: UNNotification) {
        foregroundNotificationSubject.send(notification)
    }

    private let pushNotificationSubject = CurrentValueSubject<UNNotificationResponse?, Never>(nil)
    private let foregroundNotificationSubject = PassthroughSubject<UNNotification?, Never>()
}
