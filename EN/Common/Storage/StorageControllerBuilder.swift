/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol StorageControllerBuildable {
    /// Builds StorageController
    ///
    /// - Parameter listener: Listener of created StorageController
    func build() -> StorageControlling
}

final class StorageControllerBuilder: Builder<StorageControllerDependency>, StorageControllerBuildable {
    func build() -> StorageControlling {
        return StorageControllerViewController(listener: listener)
    }
}
