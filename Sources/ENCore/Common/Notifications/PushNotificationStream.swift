/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift
import UserNotifications

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
    var pushNotificationStream: Observable<PushNotificationIdentifier> { get }
    var foregroundNotificationStream: Observable<UNNotification> { get }
}

/// @mockable
protocol MutablePushNotificationStreaming: PushNotificationStreaming {
    func update(identifier: PushNotificationIdentifier)
    func update(notification: UNNotification)
}

final class PushNotificationStream: MutablePushNotificationStreaming, Logging {

    // MARK: - PushNotificationStreaming

    var pushNotificationStream: Observable<PushNotificationIdentifier> {
        return pushNotificationSubject
            .subscribe(on: MainScheduler.instance)
            .distinctUntilChanged()
            .compactMap { $0 }
    }

    var foregroundNotificationStream: Observable<UNNotification> {
        return foregroundNotificationSubject
            .subscribe(on: MainScheduler.instance)
            .compactMap { $0 }
    }

    // MARK: - MutablePushNotificationStreaming

    func update(identifier: PushNotificationIdentifier) {
        pushNotificationSubject.onNext(identifier)
    }

    func update(notification: UNNotification) {
        foregroundNotificationSubject.onNext(notification)
    }

    private let pushNotificationSubject = BehaviorSubject<PushNotificationIdentifier?>(value: nil)
    private let foregroundNotificationSubject = BehaviorSubject<UNNotification?>(value: nil)
}
