/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import SnapKit
import SnapshotTesting
import XCTest

final class CardButtonTests: TestCase {

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        recordSnapshots = false
    }

    // MARK: - Tests

    func test_snapshot_cardButton_typeShort_rendersCorrectly() {
        let shortButton = CardButton(title: "Bekijk broncode", subtitle: "Ga naar GitHub", image: UIImage.githubLogo, type: .short, theme: theme)
        shortButton.backgroundColor = theme.colors.tertiary
        snapshotWithWrappingView(cardButton: shortButton)
    }

    private func snapshotWithWrappingView(cardButton: CardButton) {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 420))
        view.addSubview(cardButton)
        cardButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerX.centerY.equalToSuperview()
        }

        assertSnapshot(matching: view, as: .image())
    }
}
