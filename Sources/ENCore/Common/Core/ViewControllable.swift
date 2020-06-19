/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// Base ViewController interface to allow to mock ViewControllers
///
/// Adopted by for example `ViewController` and `NavigationController`
/// and designated to use together with `Routing` and `Router`
/// @mockable
protocol ViewControllable: AnyObject {
    var uiviewController: UIViewController { get }
}
