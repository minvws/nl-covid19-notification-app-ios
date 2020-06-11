/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import UIKit

/// @mockable
protocol ExposureManagerBuildable {
    /// Builds ExposureManager
    ///
    func build() throws -> ExposureManaging
}

final class ExposureManagerBuilder: Builder<EmptyDependency>, ExposureManagerBuildable {
    
    func build() throws -> ExposureManaging {
        if #available(iOS 13.5, *) {
            // check for simulator
            #if arch(i386) || arch(x86_64)
            return StubExposureManager()
            #else
            return InternalExposureManager()
            #endif
        } else {
            throw ENNotSupported.description("Update iOS")
        }
    }
    
    
}
