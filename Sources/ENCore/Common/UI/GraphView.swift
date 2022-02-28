/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift
import SnapKit
import UIKit

struct GraphData {
    let values: [UInt]

    let maxValue: UInt
    let orderOfMagnitude: UInt
    let graphUpperBound: UInt
    let scaledNormalizedValues: [CGFloat]

    init(values: [UInt]) {
        self.values = values
        maxValue = values.max() ?? 0

        do { // orderOfMagnitude
            func numberOfDigits(in number: UInt) -> Int {
                if number < 10 {
                    return 1
                } else {
                    return 1 + numberOfDigits(in: number / 10)
                }
            }

            orderOfMagnitude = UInt(pow(10.0, CGFloat(numberOfDigits(in: maxValue) - 1)))
        }

        do { // Upper bound
            let orderOfMagnitude = CGFloat(orderOfMagnitude)
            let upperBound = ceil(CGFloat(maxValue) / orderOfMagnitude) * orderOfMagnitude

            graphUpperBound = UInt(upperBound)
        }

        do { // Normalize and scale to bound
            scaledNormalizedValues = values.map { [graphUpperBound] in CGFloat($0) / CGFloat(graphUpperBound) }
        }
    }
}

final class GraphView: View {

    var data = GraphData(values: (0 ..< 20).map { _ in UInt.random(in: 30000 ... 45000) })

    private let upperBoundLabel = Label()
    private lazy var drawingView = GraphDrawingView(theme: theme, data: data)
    private let lowerBoundLabel = Label()
    private let dateContainerView = UIStackView()
    private let startDateLabel = Label()
    private let endDateLabel = Label()
    private let markerView = UIImageView(image: .graphMarker)
    private let selectionView = UIImageView(image: .graphSelection)

    // MARK: - Init

    override init(theme: Theme) {
        super.init(theme: theme)

        isUserInteractionEnabled = true
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        upperBoundLabel.font = theme.fonts.caption1
        upperBoundLabel.text = String(data.graphUpperBound)
        upperBoundLabel.textColor = theme.colors.captionGray

        lowerBoundLabel.font = theme.fonts.caption1
        lowerBoundLabel.text = "0"
        lowerBoundLabel.textColor = theme.colors.captionGray

        startDateLabel.font = theme.fonts.caption1
        startDateLabel.text = "4 jan. 2022"
        startDateLabel.textColor = theme.colors.captionGray

        endDateLabel.font = theme.fonts.caption1
        endDateLabel.text = "18 jan. 2022"
        endDateLabel.textColor = theme.colors.captionGray

        addSubview(upperBoundLabel)
        addSubview(drawingView)
        addSubview(lowerBoundLabel)
        addSubview(dateContainerView)
        addSubview(selectionView)
        addSubview(markerView)

        markerView.isHidden = true
        selectionView.isHidden = true

        dateContainerView.addArrangedSubview(startDateLabel)
        dateContainerView.addArrangedSubview(endDateLabel)
        dateContainerView.axis = .horizontal
        dateContainerView.distribution = .equalSpacing

        let panGestureRecognizer = ImmediatePanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGestureRecognizer)
    }

    @objc
    private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .ended, .cancelled, .failed:
            markerView.isHidden = true
            selectionView.isHidden = true
        default:
            markerView.isHidden = false
            selectionView.isHidden = false
        }

        let offset = recognizer.location(in: self).x

        let segmentWidth = bounds.width / CGFloat(data.values.count - 1)
        let selectedIndex = max(min(Int(round(offset / segmentWidth)), data.values.count - 1), 0)

        let horizontalOffset = CGFloat(selectedIndex) * segmentWidth
        let verticalOffset = (1 - data.scaledNormalizedValues[selectedIndex]) * drawingView.bounds.height

        markerView.center.x = horizontalOffset
        markerView.center.y = verticalOffset + drawingView.frame.minY

        selectionView.frame.origin.y = drawingView.frame.minY + 1
        selectionView.frame.size.height = drawingView.frame.height - 1
        selectionView.center.x = horizontalOffset
    }

    override func setupConstraints() {
        super.setupConstraints()

        upperBoundLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview().offset(4)
        }

        drawingView.snp.makeConstraints { maker in
            maker.top.equalTo(upperBoundLabel.snp.bottom).offset(1)
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
        }

        lowerBoundLabel.snp.makeConstraints { maker in
            maker.bottom.equalTo(drawingView.snp.bottom).offset(-1)
            maker.leading.equalToSuperview().offset(4)
        }

        dateContainerView.snp.makeConstraints { maker in
            maker.top.equalTo(drawingView.snp.bottom).offset(4)
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.height.greaterThanOrEqualTo(20)
        }

        hasBottomMargin = true
    }
}

private class ImmediatePanGestureRecognizer: UIPanGestureRecognizer {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard state != .began else { return }
        super.touchesBegan(touches, with: event)
        state = .began
    }
}

private class GraphDrawingView: View {

    let data: GraphData

    // MARK: - Init

    init(theme: Theme, data: GraphData) {
        self.data = data

        super.init(theme: theme)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    // MARK: - Overrides

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        // Draw the filled area
        let filledShapePath = UIBezierPath()
        // start bottom right
        filledShapePath.move(to: .init(x: bounds.width, y: bounds.height))
        filledShapePath.addLine(to: .init(x: 0, y: bounds.height))

        let segmentWidth = bounds.width / CGFloat(data.values.count - 1)

        let scaledDataPoints = data.scaledNormalizedValues

        scaledDataPoints
            .enumerated()
            .forEach { index, value in
                filledShapePath
                    .addLine(to: .init(x: CGFloat(index) * segmentWidth,
                                       y: (1.0 - value) * bounds.height))
            }

        filledShapePath.close()

        theme.colors.graphFill.setFill()
        filledShapePath.fill()

        // Draw the horizontal lines
        let lineCount = data.graphUpperBound / data.orderOfMagnitude

        let segmentHeight = bounds.height / CGFloat(lineCount)

        (1 ... lineCount)
            .forEach { line in
                var offset = bounds.height - CGFloat(line) * segmentHeight
                offset += 0.5 // offset the line half a point, so the line at the top won't be clipped

                let linePath = UIBezierPath()
                linePath.move(to: .init(x: 0, y: offset))
                linePath.addLine(to: .init(x: bounds.width, y: offset))

                theme.colors.graphLine.setStroke()
                linePath.lineCapStyle = .square
                linePath.lineWidth = 1
                linePath.stroke()
            }

        // Draw the graph line
        let strokePath = UIBezierPath()
        scaledDataPoints.first.map { value in
            strokePath.move(to: .init(x: 0,
                                      y: (1.0 - value) * bounds.height))
        }

        scaledDataPoints
            .enumerated()
            .dropFirst()
            .forEach { index, value in
                strokePath
                    .addLine(to: .init(x: CGFloat(index) * segmentWidth,
                                       y: (1.0 - value) * bounds.height))
            }

        theme.colors.graphStroke.setStroke()
        strokePath.lineWidth = 2
        strokePath.lineCapStyle = .square
        strokePath.stroke()
    }
}
