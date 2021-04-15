/*
 * Copyright (c) 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable
@objc public protocol UserNotification {
    var requestIdentifier: String { get}
}

extension UNNotification: UserNotification {
    public var requestIdentifier: String {
        request.identifier
    }
}

/// @mockable
@objc public protocol NotificationResponse {
    var notificationRequestIdentifier: String { get}
}

extension UNNotificationResponse: NotificationResponse {
    public var notificationRequestIdentifier: String {
        notification.request.identifier
    }
}
