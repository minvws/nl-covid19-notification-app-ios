/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation

/// @mockable
protocol NetworkStatusStreaming {
    var currentStatus: Bool { get }
    var networkStatusStream: AnyPublisher<Bool, Never> { get }
}

/// @mockable
protocol MutableNetworkStatusStreaming: NetworkStatusStreaming {
    func update(isReachable: Bool)
}

final class NetworkStatusStream: MutableNetworkStatusStreaming {

    // MARK: - PushNotificationStreaming

    var currentStatus: Bool {
        return subject.value
    }

    var networkStatusStream: AnyPublisher<Bool, Never> {
        return subject.removeDuplicates(by: ==).eraseToAnyPublisher()
    }

    // MARK: - MutablePushNotificationStreaming

    func update(isReachable: Bool) {
        subject.send(isReachable)
    }

    private let subject = CurrentValueSubject<Bool, Never>(false)
}
