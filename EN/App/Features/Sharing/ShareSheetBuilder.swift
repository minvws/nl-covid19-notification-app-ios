/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import UIKit

/// @mockable
protocol ShareSheetListener: AnyObject {
    func shareSheetDidComplete()
}

/// @mockable
protocol ShareSheetBuildable {
    /// Builds ShareSheet
    ///
    /// - Parameter listener: Listener of created ShareSheetViewController
    /// - Parameter items: Items to share
    func build(withListener listener: ShareSheetListener,
               items: [Any]) -> ViewControllable
}

final class ShareSheetBuilder: Builder<EmptyDependency>, ShareSheetBuildable {
    func build(withListener listener: ShareSheetListener, items: [Any]) -> ViewControllable {
        // TODO: Forward Items
        return ShareSheetViewController(listener: listener)
    }
}
