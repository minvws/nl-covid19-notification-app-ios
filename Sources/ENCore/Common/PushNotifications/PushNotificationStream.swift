/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation
import NotificationCenter

protocol PushNotificaionStreaming {
    var pushNotificationStream: AnyPublisher<UNNotificationResponse, Never> { get }
}

protocol MutablePushNotificationStreaming: PushNotificaionStreaming {
    func update(response: UNNotificationResponse)
}

final class PushNotificaionStream: MutablePushNotificationStreaming {

    // MARK: - PushNotificaionStreaming

    var pushNotificationStream: AnyPublisher<UNNotificationResponse, Never> {
        return subject.eraseToAnyPublisher()
    }

    // MARK: - MutablePushNotificationStreaming

    func update(response: UNNotificationResponse) {
        subject.send(response)
    }

    private let subject = PassthroughSubject<UNNotificationResponse, Never>()
}
