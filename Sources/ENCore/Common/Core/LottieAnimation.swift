/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Lottie

public final class LottieAnimation {

    /// Get the Lottie Animation for the current bundle.
    public static func named(_ name: String) -> Animation? {
        return Animation.named(name, bundle: Bundle(for: LottieAnimation.self))
    }
}
