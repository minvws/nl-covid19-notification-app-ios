/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

/// @mockable
protocol ___VARIABLE_componentName___ViewControllable: ViewControllable {}

final class ___VARIABLE_componentName___ViewController: ViewController, ___VARIABLE_componentName___ViewControllable {

    init(listener: ___VARIABLE_componentName___Listener, theme: Theme) {
        self.listener = listener

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: Implement or delete
    }

    // MARK: - Private

    private weak var listener: ___VARIABLE_componentName___Listener?
    private lazy var internalView: ___VARIABLE_componentName___View = ___VARIABLE_componentName___View(theme: self.theme)
}

private final class ___VARIABLE_componentName___View: View {

    // MARK: - Init

    override init(theme: Theme) {
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        // TODO: Construct View here or delete this function
    }

    override func setupConstraints() {
        super.setupConstraints()

        // TODO: Setup constraints here or delete this function
    }
}
