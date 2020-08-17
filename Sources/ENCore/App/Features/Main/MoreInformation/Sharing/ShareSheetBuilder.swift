/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol ShareSheetListener: AnyObject {
    func shareSheetDidComplete(shouldHideViewController: Bool)
    func displayShareSheet(usingViewController viewcontroller: ViewController, completion: @escaping ((Bool) -> ()))
}

protocol ShareSheetDependency {
    var theme: Theme { get }
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

private final class ShareSheetDependencyProvider: DependencyProvider<ShareSheetDependency> {}

final class ShareSheetBuilder: Builder<ShareSheetDependency>, ShareSheetBuildable {
    func build(withListener listener: ShareSheetListener, items: [Any]) -> ViewControllable {
        let dependencyProvider = ShareSheetDependencyProvider(dependency: dependency)
        return ShareSheetViewController(listener: listener,
                                        theme: dependencyProvider.dependency.theme)
    }
}
