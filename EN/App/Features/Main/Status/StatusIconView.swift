/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import UIKit
import CoreGraphics

class StatusIconView: View {
    private var iconImageView = UIImageView()
    private var emitterLayer = CAEmitterLayer()
    private var emitterCell = CAEmitterCell()

    override func build() {
        super.build()

        backgroundColor = .clear

        buildEmitterLayer()
        layer.addSublayer(emitterLayer)

        iconImageView.layer.cornerRadius = 24

        iconImageView.contentMode = .center
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
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            iconImageView.topAnchor.constraint(equalTo: topAnchor),
            iconImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if emitterLayer.frame != bounds {
            emitterLayer.frame = bounds
            emitterLayer.position = CGPoint(x: bounds.width/2, y: bounds.height/2)
            emitterLayer.emitterPosition = emitterLayer.position

            updateEmitterCell()
        }
    }

    func update(with icon: StatusViewIcon) {
        iconImageView.backgroundColor = icon.color
        iconImageView.image = icon.icon

        updateEmitterCell()
    }

    private func updateEmitterCell() {
        emitterCell.contents = particle(
            size: CGSize(width: bounds.width*2, height: bounds.height*2),
            color: iconImageView.backgroundColor ?? .clear
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
