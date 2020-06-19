/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// Provides dependencies to a `Builder`'s build method.
///
/// Initial a `DependencyProvider` with an object conforming to
/// the specified `DependencyType`. Provide any additional dependencies
/// by creating getters in a `DependencyProvider`'s subclass:
///
/// ```
/// protocol MyFeatureDependency {
///     var networkClient: NetworkingClient { get }
/// }
///
/// final class MyFeatureDependencyProvider: DependencyProvider<MyFeatureDependency> {
///     var networkService: MyNetworkService {
///         return MyNetworkService(networkClient: dependency.networkClient)
///     }
/// }
///
/// final class MyFeatureBuilder: Builder<MyFeatureDependency> {
///     func build() -> MyFeature {
///         let dependencyProvider = MyFeatureDependencyProvider(dependency: dependency)
///
///         // optionally access parent dependencies via `dependencyProvider.dependency`
///         return MyFeature(networkService: dependencyProvider.networkService)
///     }
/// }
/// ```
///
/// Instances that should be initialised only once can be marked with `lazy` to prevent
/// multiple initialization (note that this is not thread safe).
///
/// When DependencyProvider provide child builders they have to adopt the dependency protocol
/// of the child feature:
///
/// ```
/// final class MyFeatureDependencyProvider: DependencyProvider<MyFeatureDependency>, MyChildFeatureDependency {
///     var childBuilder: MyChildFeatureBuildable {
///         return MyChildFeatureBuilder(dependency: self)
///     }
/// }
/// ```
///
/// # Reference
/// `OnboardingDependencyProvider` as [example](x-source-tag://OnboardingDependencyProvider)
class DependencyProvider<DependencyType> {
    let dependency: DependencyType

    init(dependency: DependencyType) {
        self.dependency = dependency
    }
}

// MARK: - Empty Dependency Support

private final class EmptyDependencyImpl: EmptyDependency {}

extension DependencyProvider where DependencyType == EmptyDependency {
    convenience init() {
        self.init(dependency: EmptyDependencyImpl())
    }
}
