/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol HelpOverviewListener: AnyObject {
    func helpOverviewRequestsDismissal(shouldDismissViewController: Bool)
    func helpOverviewRequestsRouteTo(question: HelpQuestion)
    func helpOverviewDidTapEnableAppButton()
}

protocol HelpOverviewBuildable {
    func build(withListener listener: HelpOverviewListener,
               shouldShowEnableAppButton: Bool) -> ViewControllable
}

protocol HelpOverviewDependency {
    var theme: Theme { get }
    var helpManager: HelpManaging { get }
}

final class HelpOverviewDependencyDependencyProvider: DependencyProvider<HelpOverviewDependency> {}

final class HelpOverviewBuilder: Builder<HelpOverviewDependency>, HelpOverviewBuildable {
    func build(withListener listener: HelpOverviewListener,
               shouldShowEnableAppButton: Bool) -> ViewControllable {
        let dependencyProvider = HelpOverviewDependencyDependencyProvider(dependency: dependency)

        return HelpOverviewViewController(listener: listener,
                                          shouldShowEnableAppButton: shouldShowEnableAppButton,
                                          helpManager: dependencyProvider.dependency.helpManager,
                                          theme: dependencyProvider.dependency.theme)
    }
}
