/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

/// The App's entry point.
///
/// @mockable
protocol AppEntryPoint {
    /// The `UIViewController` instance that should be used as `keyWindow` property
    var uiviewController: UIViewController { get }
    
    /// Starts the application. Start should be called once
    /// the `SceneDelegate`'s `sceneDidBecomeActive` method is called.
    func start()
}

/// Provides all dependencies to build the RootRouter
private final class RootDependencyProvider: DependencyProvider<EmptyDependency>, MainDependency {
    /// Builds onboarding flow
    var onboardingBuilder: OnboardingBuildable {
        return OnboardingBuilder()
    }
    
    /// Builds main flow
    var mainBuilder: MainBuildable {
        return MainBuilder(dependency: self)
    }
}

/// Interface describing the builder that builds
/// the App's entry point
///
/// @mockable
protocol RootBuildable {
    /// Builds application's entry point
    ///
    /// - Returns: Application's entry point
    func build() -> AppEntryPoint
}

/// Builds the Root feature which should be used via the `AppEntryPoint`
/// interface. 
///
/// - Tag: RootBuilder
final class RootBuilder: Builder<EmptyDependency>, RootBuildable {
    
    // MARK: - RootBuildable
    
    func build() -> AppEntryPoint {
        let dependencyProvider = RootDependencyProvider()
        let viewController = RootViewController()
        
        return RootRouter(viewController: viewController,
                          onboardingBuilder: dependencyProvider.onboardingBuilder,
                          mainBuilder: dependencyProvider.mainBuilder)
    }
}
