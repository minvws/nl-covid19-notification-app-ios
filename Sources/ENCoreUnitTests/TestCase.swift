/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
import SnapshotTesting
import XCTest

class TestCase: XCTestCase {

    var recordSnapshots: Bool {
        get { SnapshotTesting.record }
        set { SnapshotTesting.record = newValue }
    }

    let theme = ENTheme()

    // MARK: - Overrides

    override func setUp() {
        super.setUp()

        SnapshotTesting.diffTool = "ksdiff"
    }

    override func tearDown() {
        disposeBag.forEach { $0.cancel() }

        super.tearDown()
    }

    // MARK: - Private

    fileprivate var disposeBag = Set<AnyCancellable>()
}

extension AnyCancellable {
    func disposeOnTearDown(of testCase: TestCase) {
        store(in: &testCase.disposeBag)
    }
}
