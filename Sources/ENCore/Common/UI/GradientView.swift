/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class GradientView: UIView {

    private let gradient: CAGradientLayer = CAGradientLayer()
    private let startColor: UIColor
    private let endColor: UIColor

    init(startColor: UIColor, endColor: UIColor) {
        self.startColor = startColor
        self.endColor = endColor
        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        gradient.frame = self.bounds
    }

    override public func draw(_ rect: CGRect) {
        gradient.frame = self.bounds
        gradient.colors = [startColor.cgColor, endColor.cgColor]
        if gradient.superlayer == nil {
            layer.insertSublayer(gradient, at: 0)
        }
    }
}
