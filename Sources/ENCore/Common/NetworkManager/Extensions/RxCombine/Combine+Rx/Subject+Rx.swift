/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

#if canImport(Combine)
    import Combine
    import RxSwift

    /// Represents a Combine Subject that can be converted
    /// to a RxSwift AnyObserver of the underlying Output type.
    ///
    /// - note: This only works when the underlying Failure is Swift.Error,
    ///         since RxSwift has no typed errors.
    public protocol AnyObserverConvertible: Combine.Subject where Failure == Swift.Error {
        associatedtype Output

        /// Returns a RxSwift `AnyObserver` wrapping the Subject
        ///
        /// - returns: AnyObserver<Output>
        func asAnyObserver() -> AnyObserver<Output>
    }

    public extension AnyObserverConvertible {
        /// Returns a RxSwift AnyObserver wrapping the Subject
        ///
        /// - returns: AnyObserver<Output>
        func asAnyObserver() -> AnyObserver<Output> {
            AnyObserver { [weak self] event in
                guard let self = self else { return }
                switch event {
                case let .next(value):
                    self.send(value)
                case let .error(error):
                    self.send(completion: .failure(error))
                case .completed:
                    self.send(completion: .finished)
                }
            }
        }
    }

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    extension PassthroughSubject: AnyObserverConvertible where Failure == Swift.Error {}
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    extension CurrentValueSubject: AnyObserverConvertible where Failure == Swift.Error {}

    public extension ObservableConvertibleType {
        /**
         Creates new subscription and sends elements to a Combine Subject.

         - parameter to: Combine subject to receives events.
         - returns: Disposable object that can be used to unsubscribe the observers.
         - seealso: `AnyOserverConvertible`
         */
        func bind<S: AnyObserverConvertible>(to subject: S) -> Disposable where S.Output == Element {
            asObservable().subscribe(subject.asAnyObserver())
        }
    }
#endif
