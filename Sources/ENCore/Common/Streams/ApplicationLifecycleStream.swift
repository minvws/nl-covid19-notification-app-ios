/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift
import RxRelay
import UIKit

/// @mockable
protocol ApplicationLifecycleStreaming {
    var didBecomeActive: PublishRelay<Void> { get }
}

final class ApplicationLifecycleStream: ApplicationLifecycleStreaming {

    init() {
        // We listen for device orientation changes (which are more sensitive)
        // but we use the interface orientation of the key window to actually determine the rotation of the UI
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.didBecomeActive.accept(())
        }
    }

    // MARK: - ApplicationLifecycleStreaming

    var didBecomeActive = PublishRelay<Void>()
}
