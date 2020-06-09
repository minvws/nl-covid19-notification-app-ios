/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

open class View: UIView {

    public override init(frame: CGRect) {
        super.init(frame: frame)

        configure()
    }

    public required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    func configure() {

        build()
        setupConstraints()
    }

    open func build() {
        backgroundColor = .systemBackground
    }

    open func setupConstraints() {

    }
}
