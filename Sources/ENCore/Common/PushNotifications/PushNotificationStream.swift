/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import NotificationCenter
import RxSwift

enum PushNotificationIdentifier: String {
    case exposure = "nl.rijksoverheid.en.exposure"
    case inactive = "nl.rijksoverheid.en.inactive"
    case uploadFailed = "nl.rijksoverheid.en.uploadFailed"
    case enStatusDisabled = "nl.rijksoverheid.en.statusDisabled"
    case appUpdateRequired = "nl.rijksoverheid.en.appUpdateRequired"

    static func allIdentifiers() -> [PushNotificationIdentifier] {
        return [
            .exposure,
            .inactive,
            .uploadFailed,
            .enStatusDisabled,
            .appUpdateRequired
        ]
    }
}

/// @mockable
protocol PushNotificationStreaming {
    var pushNotificationStream: Observable<PushNotificationIdentifier> { get }
}

/// @mockable
protocol MutablePushNotificationStreaming: PushNotificationStreaming {
    func update(identifier: PushNotificationIdentifier)
}

final class PushNotificationStream: MutablePushNotificationStreaming, Logging {

    // MARK: - PushNotificationStreaming

    var pushNotificationStream: Observable<PushNotificationIdentifier> {
        return subject
            .subscribe(on: MainScheduler.instance)
            .distinctUntilChanged()
            .compactMap { $0 }
    }

    // MARK: - MutablePushNotificationStreaming

    func update(identifier: PushNotificationIdentifier) {
        subject.onNext(identifier)
    }

    private let subject = BehaviorSubject<PushNotificationIdentifier?>(value: nil)
}
