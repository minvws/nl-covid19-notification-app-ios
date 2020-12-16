/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

#if canImport(Combine)
    import Combine
    import RxRelay
    import RxSwift

    // MARK: - Behavior Relay as Publisher

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    extension BehaviorRelay {
        /// An `AnyPublisher` of the underlying Relay's Element type
        /// so the relay pushes events to the Publisher.
        var publisher: AnyPublisher<Element, Never> {
            RxPublisher(upstream: self).assertNoFailure().eraseToAnyPublisher()
        }

        /// An `AnyPublisher` of the underlying Relay's Element type
        /// so the relay pushes events to the Publisher.
        ///
        /// - returns: AnyPublisher of the underlying Relay's Element type.
        /// - note: This is an alias for the `publisher` property.
        func asPublisher() -> AnyPublisher<Element, Never> {
            publisher
        }
    }

    // MARK: - Publish Relay as Publisher

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    extension PublishRelay {
        /// An `AnyPublisher` of the underlying Relay's Element type
        /// so the relay pushes events to the Publisher.
        var publisher: AnyPublisher<Element, Never> {
            RxPublisher(upstream: self).assertNoFailure().eraseToAnyPublisher()
        }

        /// An `AnyPublisher` of the underlying Relay's Element type
        /// so the relay pushes events to the Publisher.
        ///
        /// - returns: AnyPublisher of the underlying Relay's Element type.
        /// - note: This is an alias for the `publisher` property.
        func asPublisher() -> AnyPublisher<Element, Never> {
            publisher
        }
    }
#endif
