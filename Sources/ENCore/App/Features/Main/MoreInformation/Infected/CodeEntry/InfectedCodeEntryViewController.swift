/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol InfectedCodeEntryViewControllable: ViewControllable {}

final class InfectedCodeEntryViewController: ViewController, InfectedCodeEntryViewControllable {

    init(listener: InfectedCodeEntryListener, theme: Theme) {
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

    private weak var listener: InfectedCodeEntryListener?
    private lazy var internalView: InfectedCodeEntryView = InfectedCodeEntryView(theme: self.theme)
}

private final class InfectedCodeEntryView: View {

    override func build() {
        super.build()

        // TODO: Construct View here or delete this function
    }

    override func setupConstraints() {
        super.setupConstraints()

        // TODO: Setup constraints here or delete this function
    }
}
