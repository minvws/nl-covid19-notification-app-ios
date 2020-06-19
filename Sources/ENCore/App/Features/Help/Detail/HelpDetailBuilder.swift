/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

protocol HelpDetailListener: AnyObject {
    func helpDetailRequestsDismissal(shouldDismissViewController: Bool)
}

protocol HelpDetailBuildable {
    func build(withListener listener: HelpDetailListener,
               question: HelpQuestion) -> ViewControllable
}

protocol HelpDetailDependency {
    var theme: Theme { get }
}

private final class HelpDetailDependencyProvider: DependencyProvider<HelpDetailDependency> {}

final class HelpDetailBuilder: Builder<HelpDetailDependency>, HelpDetailBuildable {
    func build(withListener listener: HelpDetailListener,
               question: HelpQuestion) -> ViewControllable {
        let dependencyProvider = HelpDetailDependencyProvider(dependency: dependency)

        return HelpDetailViewController(listener: listener,
                                        question: question,
                                        theme: dependencyProvider.dependency.theme)
    }
}
