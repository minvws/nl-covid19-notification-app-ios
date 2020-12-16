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

    // MARK: - Behavior Relay as Combine Subject

    /// A bi-directional wrapper for a RxSwift Behavior Relay
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public final class RxCurrentValueRelay<Output>: Combine.Subject {
        private let rxRelay: BehaviorRelay<Output>
        private let subject: CurrentValueSubject<Output, Never>
        private let subscription: AnyCancellable?

        public var value: Output {
            get { subject.value }
            set { rxRelay.accept(newValue) }
        }

        init(rxRelay: BehaviorRelay<Output>) {
            self.rxRelay = rxRelay
            self.subject = CurrentValueSubject(rxRelay.value)
            subscription = rxRelay.publisher.subscribe(subject)
        }

        public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            subject.receive(subscriber: subscriber)
        }

        public func send(_ value: Output) {
            rxRelay.accept(value)
        }

        public func send(completion: Subscribers.Completion<Failure>) {
            // Relays can't complete or fail
        }

        public func send(subscription: Subscription) {
            subject.send(subscription: subscription)
        }

        deinit { subscription?.cancel() }

        public typealias Failure = Never
    }

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public extension BehaviorRelay {
        func toCombine() -> RxCurrentValueRelay<Element> {
            RxCurrentValueRelay(rxRelay: self)
        }
    }
#endif
