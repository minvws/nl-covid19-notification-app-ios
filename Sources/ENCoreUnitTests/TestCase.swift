/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import XCTest

class TestCase: XCTestCase {
    fileprivate var disposeBag = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        disposeBag.forEach { $0.cancel() }

        super.tearDown()
    }
}

extension AnyCancellable {
    func disposeOnTearDown(of testCase: TestCase) {
        store(in: &testCase.disposeBag)
    }
}
