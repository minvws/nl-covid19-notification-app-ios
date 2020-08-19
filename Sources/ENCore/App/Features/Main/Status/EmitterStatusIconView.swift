/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import CoreGraphics
import Foundation
import UIKit

final class EmitterStatusIconView: View {
    private var iconImageView = UIImageView()
    private var emitterLayer = CAEmitterLayer()
    private var emitterCell = CAEmitterCell()

    override func build() {
        super.build()

        backgroundColor = .clear

        buildEmitterLayer()
        layer.addSublayer(emitterLayer)

        iconImageView.contentMode = .scaleAspectFit
        addSubview(iconImageView)
    }

    private func buildEmitterLayer() {
        emitterCell.birthRate = 0.2
        emitterCell.lifetime = 5 / emitterCell.birthRate
        emitterCell.scale = 0
        emitterCell.scaleSpeed = 0.025
        emitterCell.alphaSpeed = -0.04

        emitterLayer.emitterCells = [emitterCell]
    }

    override func setupConstraints() {
        super.setupConstraints()

        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),

            iconImageView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.66),
            iconImageView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, multiplier: 0.66)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if emitterLayer.frame != bounds {
            emitterLayer.frame = bounds
            emitterLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
            emitterLayer.emitterPosition = emitterLayer.position

            updateEmitterCell()
        }

        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }

    func update(with icon: StatusViewIcon) {
        backgroundColor = theme.colors[keyPath: icon.color]
        iconImageView.image = icon.icon

        updateEmitterCell()
    }

    private func updateEmitterCell() {

        emitterLayer.emitterCells?.removeAll()
        buildEmitterLayer()

        self.emitterCell.contents = particle(
            size: CGSize(width: bounds.width * 2, height: bounds.height * 2),
            color: backgroundColor ?? .clear
        ).cgImage
    }

    private func particle(size: CGSize, color: UIColor) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        return UIGraphicsImageRenderer(size: rect.size).image { context in
            context.cgContext.setFillColor(color.withAlphaComponent(0.2).cgColor)
            context.cgContext.addPath(CGPath(ellipseIn: rect, transform: nil))
            context.cgContext.fillPath()
        }
    }
}
