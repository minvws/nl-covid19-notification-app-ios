/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// A Builder can build new objects using a dependency as input
///
/// Builders can be added to an architecture to simplify dependency
/// injecten and (therefore) object creation. Imagine the example:
///
/// ```
/// class MyFeatureViewController {
///     init(mainStateStream: MainStateStreaming,
///          shareController: ShareControlling) {}
/// }
/// ```
///
/// This viewController could be created from another viewController:
/// `MyParentViewController`. In order to create a `MyFeatureViewController` instance
/// `MyParentViewController` would have to know about the dependencies required
/// to create a `MyFeatureViewController` instance: `mainStateStream` and `shareController`.
/// Ideally `MyParentViewController` does not want to worry about these, but just
/// create the instance and use it.
///
/// This is where builders come into place: instead of `MyParentViewController` knowing
/// how to create `MyFeatureViewController`, it just gets a `MyFeatureBuilder` instance`.
/// This instance has just once function:
///
/// ```
/// func build() -> MyFeatureViewController`
/// ```
///
/// Now the only thing `MyParentViewController` has to do is call this `build`
/// method and use the returned `MyFeatureViewController` right away.
///
/// - Note: Any dynamic dependencies can be passed as argument of the `build` method:
///
/// ```
/// func build(withListener listener: MyFeatureListener)
/// ```
///
/// # Reference
/// `RootBuilder` as [example](x-source-tag://RootBuilder)
///
class Builder<DependencyType> {
    /// DependencyType instance to use to create return a built instance
    let dependency: DependencyType
    
    /// Initialises a new builder instance
    ///
    /// - Parameter dependency: Dependency of type DependencyType
    init(dependency: DependencyType) {
        self.dependency = dependency
    }
}

// MARK: - Empty Dependency Support

/// Empty Dependency implementation
/// Is used implicitly when defining a Builder with EmptyDependency
/// as DependencyType
private final class EmptyDependencyImpl: EmptyDependency {}

extension Builder where DependencyType == EmptyDependency {
    convenience init() {
        self.init(dependency: EmptyDependencyImpl())
    }
}
