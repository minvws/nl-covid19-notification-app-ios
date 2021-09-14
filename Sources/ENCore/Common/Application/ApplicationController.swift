/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// @mockable(history:dismissAllPresentedViewController=true)
protocol ApplicationControlling {
    func isInBackground() -> Bool
    func isActive() -> Bool
    func canOpenURL(_ url: URL) -> Bool
    func open(_ url: URL)
    func dismissAllPresentedViewController(animated: Bool, completion: (() -> ())?)
}

class ApplicationController: ApplicationControlling {
    func isInBackground() -> Bool {
        UIApplication.shared.applicationState == .background
    }

    func isActive() -> Bool {
        UIApplication.shared.applicationState == .active
    }

    func open(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func canOpenURL(_ url: URL) -> Bool {
        UIApplication.shared.canOpenURL(url)
    }

    func dismissAllPresentedViewController(animated: Bool, completion: (() -> ())?) {
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: animated, completion: completion)
    }
}
