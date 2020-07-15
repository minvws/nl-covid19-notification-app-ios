/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

final class EnableSettingViewController: ViewController {

    init(listener: EnableSettingListener, theme: Theme) {
        self.listener = listener

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: Implement or delete
    }

    // MARK: - Private

    private weak var listener: EnableSettingListener?
    private lazy var internalView: EnableSettingView = EnableSettingView()
}

private final class EnableSettingView: View {
    override func build() {
        super.build()

        // TODO: Construct View here or delete this function
    }

    override func setupConstraints() {
        super.setupConstraints()

        // TODO: Setup constraints here or delete this function
    }
}
