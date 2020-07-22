/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

final class CloudView: View {
    private let cloudImages: [UIImage?] = [.statusCloud1, .statusCloud1, .statusCloud2]
    private let verticalSpacing: CGFloat = 12
    private let topMargin: CGFloat = 20

    private lazy var horizontalVelocities: [CGFloat] = defaultHorizontalVelocities
    private let defaultHorizontalVelocities: [CGFloat] = [3, 7, 5] // pt / sec
    private var horizontalPositions: [CGFloat] = [0.8, 0, 0.15] // width%

    private let cloudViews: [UIView]
    private var displayLink: CADisplayLink?

    override init(theme: Theme) {
        cloudViews = cloudImages.map { UIImageView(image: $0) }

        super.init(theme: theme)

        assert(numberOfClouds == horizontalPositions.count)
        assert(numberOfClouds == horizontalVelocities.count)

        layoutClouds()
    }

    override func build() {
        super.build()

        backgroundColor = .clear

        cloudViews.forEach(addSubview(_:))
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if superview == nil {
            stopDisplayLink()
        } else {
            startDisplayLink()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layoutClouds()
    }

    private var numberOfClouds: Int {
        return cloudImages.count
    }

    private func layoutClouds() {
        var y: CGFloat = topMargin

        for i in 0 ..< numberOfClouds {
            var frame = cloudViews[i].frame

            let horizontalFactor = CGFloat(horizontalPositions[i])
            let widthFactor = (1.0 - horizontalFactor) * frame.width
            frame.origin.x = CGFloat(horizontalPositions[i]) * bounds.width - widthFactor
            frame.origin.y = y

            y += frame.height + verticalSpacing

            cloudViews[i].frame = frame
        }
    }

    private func updatePositions(delta: CGFloat) {
        for i in 0 ..< numberOfClouds {
            horizontalPositions[i] += CGFloat(horizontalVelocities[i] / bounds.width) * delta

            if horizontalPositions[i] > 1.0 {
                horizontalPositions[i] = 0.0
            } else if horizontalPositions[i] < 0.0 {
                horizontalPositions[i] = 1.0
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: cloudViews.last?.frame.maxY ?? 0)
    }

    private func startDisplayLink() {
        #if DEBUG
            if let animationsEnabled = AnimationTestingOverrides.animationsEnabled, animationsEnabled == false {
                return
            }
        #endif

        guard displayLink == nil else { return }

        displayLink = CADisplayLink(target: self, selector: #selector(tick(_:)))
        displayLink?.add(to: RunLoop.main, forMode: .common)
    }

    private func stopDisplayLink() {
        guard displayLink != nil else { return }

        displayLink?.remove(from: RunLoop.main, forMode: .common)
        displayLink = nil
    }

    @objc
    private func tick(_ displayLink: CADisplayLink) {
        updatePositions(delta: CGFloat(displayLink.duration))
        setNeedsLayout()
    }
}
