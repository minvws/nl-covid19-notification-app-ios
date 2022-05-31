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
    let values: [DashboardData.DatedValue]

    let maxValue: UInt
    let orderOfMagnitude: UInt
    let graphUpperBound: UInt
    let normalizedValues: [CGFloat]
    let scaledNormalizedValues: [CGFloat]

    init(values: [DashboardData.DatedValue]) {
        self.values = values.sorted { $0.date < $1.date }
        let values = self.values.map { UInt($0.value) }

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

        do { // Normalize
            normalizedValues = values.map { [maxValue] in CGFloat($0) / CGFloat(maxValue) }
        }
    }
}

final class GraphView: View {

    enum Style {
        case normal
        case compact
    }

    private let data: GraphData

    private let upperBoundLabel = Label()
    private lazy var drawingView = GraphDrawingView(theme: theme, data: data, style: style)
    private let lowerBoundLabel = Label()
    private let dateContainerView = UIStackView()
    private let startDateLabel = Label()
    private let endDateLabel = Label()
    private let selectedDateLabel = Label()
    private let markerView = UIImageView(image: .graphMarker)
    private let selectionView = UIImageView(image: .graphSelection)

    // StackView with hidden but accessible views overlaying points in the graph
    // For keyboard and switchkeys navigation
    private let accessibilityHelperStackView = UIStackView()

    private let popupContainerView = UIView()
    private let popupBubbleView = UIView()
    private let popupArrowView = UIImageView(image: .popupArrow)
    private let popupLabel = Label()
    private let style: Style
    private let title: String

    private let errorLabel = Label()

    private lazy var panningViews = [selectedDateLabel, markerView, selectionView, popupContainerView]

    var accessibilityChartDescriptorStorage: Any?

    // MARK: - Init

    init(theme: Theme, title: String, data: GraphData, style: Style) {
        self.style = style
        self.data = data
        self.title = title
        super.init(theme: theme)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        switch style {
        case .normal:
            buildNormal()
            setupAccessibilityHelperViews()

            if #available(iOS 15.0, *) {
                setupAudioGraph()
            }
        case .compact:
            buildCompact()
        }

        backgroundColor = .clear
    }

    // MARK: - Private

    private static var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("d MMM YYYY")
        return dateFormatter
    }()

    private static var shortDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("d MMM")
        return dateFormatter
    }()

    private static var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()

    private func buildNormal() {
        addSubview(errorLabel)

        addSubview(drawingView)
        addSubview(upperBoundLabel)
        addSubview(lowerBoundLabel)
        addSubview(dateContainerView)
        addSubview(selectionView)
        addSubview(markerView)
        addSubview(selectedDateLabel)
        addSubview(popupContainerView)
        addSubview(accessibilityHelperStackView)

        upperBoundLabel.font = theme.fonts.caption1
        upperBoundLabel.text = String(data.graphUpperBound)
        upperBoundLabel.textColor = theme.colors.captionGray

        lowerBoundLabel.font = theme.fonts.caption1
        lowerBoundLabel.text = "0"
        lowerBoundLabel.textColor = theme.colors.captionGray

        startDateLabel.font = theme.fonts.caption1
        startDateLabel.text = data.values.first.map(\.date).map(Self.dateFormatter.string)
        startDateLabel.textColor = theme.colors.captionGray

        endDateLabel.font = theme.fonts.caption1
        endDateLabel.text = data.values.last.map(\.date).map(Self.dateFormatter.string)
        endDateLabel.textColor = theme.colors.captionGray

        selectedDateLabel.font = theme.fonts.caption1Bold
        selectedDateLabel.textColor = theme.colors.textPrimary
        selectedDateLabel.textAlignment = .center
        selectedDateLabel.backgroundColor = theme.colors.viewControllerBackground

        popupLabel.font = theme.fonts.caption1
        popupLabel.textColor = theme.colors.captionGray

        popupBubbleView.backgroundColor = theme.colors.graphBackground
        popupBubbleView.layer.cornerRadius = 8

        popupContainerView.translatesAutoresizingMaskIntoConstraints = false
        popupContainerView.layer.shadowOffset = CGSize(width: 0, height: 8)
        popupContainerView.layer.shadowRadius = 12
        popupContainerView.layer.shadowColor = UIColor.black.cgColor
        popupContainerView.layer.shadowOpacity = 0.1

        popupArrowView.tintColor = theme.colors.graphBackground

        popupContainerView.addSubview(popupBubbleView)
        popupContainerView.addSubview(popupArrowView)
        popupBubbleView.addSubview(popupLabel)

        panningViews.forEach { $0.isHidden = true }

        dateContainerView.addArrangedSubview(startDateLabel)
        dateContainerView.addArrangedSubview(endDateLabel)
        dateContainerView.axis = .horizontal
        dateContainerView.distribution = .equalSpacing

        errorLabel.text = .dashboardServerError
        errorLabel.font = theme.fonts.caption1
        errorLabel.textAlignment = .center

        let panGestureRecognizer = ImmediatePanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGestureRecognizer)

        showErrorIfNeeded()
    }

    private func buildCompact() {
        addSubview(drawingView)
        addSubview(markerView)

        panningViews.forEach { $0.isHidden = true }
        markerView.isHidden = false
    }

    private func showErrorIfNeeded() {
        let isError = data.values.isEmpty

        subviews.forEach { $0.isHidden = isError }
        panningViews.forEach { $0.isHidden = true }
        errorLabel.isHidden = !isError
    }

    override func setupConstraints() {
        super.setupConstraints()

        switch style {
        case .normal:
            setupConstraintsNormal()
        case .compact:
            setupConstraintsCompact()
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        highlightValue(at: accessibilityHelperStackView
            .arrangedSubviews
            .firstIndex(where: \.isFocused))
    }

    private func setupAccessibilityHelperViews() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(evaluateAccessibleState),
                                               name: UIAccessibility.switchControlStatusDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(evaluateAccessibleState),
                                               name: UIAccessibility.voiceOverStatusDidChangeNotification,
                                               object: nil)

        accessibilityHelperStackView.axis = .horizontal
        accessibilityHelperStackView.distribution = .equalSpacing

        data.values.forEach { _ in
            let view = UIView(frame: .zero)

            view.isAccessibilityElement = true
            view.isUserInteractionEnabled = true
            view.accessibilityTraits = .link

            accessibilityHelperStackView.addArrangedSubview(view)

            view.snp.makeConstraints { maker in
                maker.width.equalTo(1)
            }
        }

        evaluateAccessibleState()
    }

    @objc private func evaluateAccessibleState() {
        let shouldUseHelperViews = UIAccessibility.isSwitchControlRunning || !UIAccessibility.isVoiceOverRunning

        // If the helper views for switch control and fulll keyboard access are active,
        // don't mark the entire view as one accessible element
        isAccessibilityElement = !shouldUseHelperViews
        accessibilityHelperStackView.isHidden = !shouldUseHelperViews
    }

    private func setupConstraintsNormal() {
        errorLabel.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        drawingView.snp.makeConstraints { maker in
            maker.top.equalTo(upperBoundLabel.snp.bottom).offset(1)
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
        }

        accessibilityHelperStackView.snp.makeConstraints { maker in
            maker.edges.equalTo(drawingView)
        }

        upperBoundLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview().offset(4)
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

        let arrowSize = popupArrowView.image?.size ?? .zero

        popupLabel.snp.makeConstraints { maker in
            maker.left.equalToSuperview().offset(8)
            maker.right.equalToSuperview().offset(-8)
            maker.top.equalToSuperview().offset(13)
            maker.bottom.equalToSuperview().offset(-13)
        }

        popupBubbleView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
        }

        popupArrowView.snp.makeConstraints { maker in
            maker.top.equalTo(popupBubbleView.snp.bottom).offset(-8)
            maker.left.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.height.equalTo(arrowSize.height)
            maker.width.equalTo(arrowSize.width)
        }

        popupContainerView.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.bottom.equalTo(drawingView.snp.top).offset(-2)
        }

        hasBottomMargin = true
    }

    private func setupConstraintsCompact() {
        drawingView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    @objc
    private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard !data.values.isEmpty else { return }

        let isActive = ![.ended, .cancelled, .failed].contains(recognizer.state)
        let offset = recognizer.location(in: self).x
        let selectedIndex = max(min(Int(round(offset / segmentWidth)), data.values.count - 1), 0)

        if isActive {
            highlightValue(at: selectedIndex)
        } else {
            highlightValue(at: nil)
        }
    }

    private var segmentWidth: CGFloat {
        bounds.width / CGFloat(data.values.count - 1)
    }

    private func highlightValue(at index: Int? = nil) {
        guard let index = index, data.values.indices.contains(index) else {
            panningViews.forEach { $0.isHidden = true }
            return
        }

        panningViews.forEach { $0.isHidden = false }

        let horizontalOffset = CGFloat(index) * segmentWidth
        let verticalOffset = (1 - data.scaledNormalizedValues[index]) * drawingView.bounds.height

        markerView.center.x = horizontalOffset
        markerView.center.y = verticalOffset + drawingView.frame.minY

        selectionView.frame.origin.y = drawingView.frame.minY + 1
        selectionView.frame.size.height = drawingView.frame.height - 1
        selectionView.center.x = horizontalOffset

        selectedDateLabel.sizeToFit()

        let selectedDateMargin: CGFloat = 4

        selectedDateLabel.frame.origin.y = dateContainerView.frame.minY
        selectedDateLabel.frame.size.height = dateContainerView.frame.height
        selectedDateLabel.frame.size.width += selectedDateMargin * 2

        let minCenter = -selectedDateMargin + selectedDateLabel.frame.width / 2
        let maxCenter = bounds.width - selectedDateLabel.frame.width / 2 + selectedDateMargin

        selectedDateLabel.center.x = min(max(horizontalOffset, minCenter), maxCenter)

        let arrowHalfWidth = (popupArrowView.image?.size.width ?? 1) / 2
        let popupHalfWidth = popupContainerView.frame.width / 2

        let popupMinCenter = popupHalfWidth - arrowHalfWidth
        let popupMaxCenter = bounds.width - popupHalfWidth + arrowHalfWidth

        let popupCenter = min(max(horizontalOffset, popupMinCenter), popupMaxCenter)
        let popupCenterDifference = horizontalOffset - popupCenter
        popupContainerView.transform = CGAffineTransform(translationX: popupCenter - popupHalfWidth, y: 0)
        popupArrowView.transform = CGAffineTransform(translationX: popupHalfWidth + popupCenterDifference - arrowHalfWidth, y: 0)

        let datedValue = data.values[index]
        selectedDateLabel.text = Self.shortDateFormatter.string(from: datedValue.date)

        // TODO: Add localized prefix string
        popupLabel.text = Self.numberFormatter.string(from: datedValue.value as NSNumber)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        switch style {
        case .normal:
            break
        case .compact:
            let lastValue = data.normalizedValues.last ?? 0

            markerView.center.x = drawingView.frame.width
            markerView.center.y = drawingView.graphOffset + (drawingView.frame.height - drawingView.graphOffset) * (1 - lastValue)
        }
    }
}

@available(iOS 15.0, *)
extension GraphView: AXChart {
    var accessibilityChartDescriptor: AXChartDescriptor? {
        get { accessibilityChartDescriptorStorage as? AXChartDescriptor }

        set(accessibilityChartDescriptor) {
            accessibilityChartDescriptorStorage = accessibilityChartDescriptor
        }
    }

    fileprivate func setupAudioGraph() {
        // Generate the data points from the model data.
        let audiographValues = data.values.map {
            (x: Self.shortDateFormatter.string(from: $0.date), y: Double($0.value))
        }

        let dataPoints = audiographValues.map { AXDataPoint(x: $0.x, y: $0.y) }

        // Make the series descriptor.
        let series = AXDataSeriesDescriptor(name: title,
                                            isContinuous: true,
                                            dataPoints: dataPoints)

        // Make the axis descriptors.
        let category = AXCategoricalDataAxisDescriptor(title: .dashboardGraphHorizontalAxisLabel,
                                                       categoryOrder: audiographValues.map(\.x))

        let amount = AXNumericDataAxisDescriptor(title: .dashboardGraphVerticalAxisLabel,
                                                 range: 0 ... Double(data.graphUpperBound),
                                                 gridlinePositions: []) {
            Self.numberFormatter.string(from: $0 as NSNumber) ?? ""
        }

        // Make and set the chart descriptor.
        accessibilityChartDescriptor = AXChartDescriptor(title: title,
                                                         xAxis: category,
                                                         yAxis: amount,
                                                         additionalAxes: [],
                                                         series: [series])
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
    let style: GraphView.Style

    // MARK: - Init

    init(theme: Theme, data: GraphData, style: GraphView.Style) {
        self.data = data
        self.style = style

        super.init(theme: theme)
        setContentCompressionResistancePriority(.required, for: .vertical)
        backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    var graphOffset: CGFloat {
        switch style {
        case .normal:
            return 0
        case .compact:
            return 8
        }
    }

    // MARK: - Overrides

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard !data.values.isEmpty else { return }

        let graphWidth = bounds.width
        let graphHeight = bounds.height - graphOffset
        let scaledDataPoints: [CGFloat]
        let drawLines: Bool

        switch style {
        case .normal:
            scaledDataPoints = data.scaledNormalizedValues
            drawLines = true
        case .compact:
            scaledDataPoints = data.normalizedValues
            drawLines = false
        }

        if drawLines {
            // Draw the horizontal lines
            let lineCount = data.graphUpperBound / data.orderOfMagnitude

            let segmentHeight = graphHeight / CGFloat(lineCount)

            (1 ... lineCount)
                .forEach { line in
                    var offset = graphHeight - CGFloat(line) * segmentHeight
                    offset += 0.5 // offset the line half a point, so the line at the top won't be clipped

                    let linePath = UIBezierPath()
                    linePath.move(to: .init(x: 0, y: offset))
                    linePath.addLine(to: .init(x: graphWidth, y: offset))

                    theme.colors.graphLine.setStroke()
                    linePath.lineCapStyle = .square
                    linePath.lineWidth = 1
                    linePath.apply(CGAffineTransform(translationX: 0, y: graphOffset))
                    linePath.stroke()
                }
        }

        // Draw the filled area
        let filledShapePath = UIBezierPath()
        // start bottom right
        filledShapePath.move(to: .init(x: graphWidth, y: graphHeight))
        filledShapePath.addLine(to: .init(x: 0, y: graphHeight))

        let segmentWidth = graphWidth / CGFloat(data.values.count - 1)

        scaledDataPoints
            .enumerated()
            .forEach { index, value in
                filledShapePath
                    .addLine(to: .init(x: CGFloat(index) * segmentWidth,
                                       y: (1.0 - value) * graphHeight))
            }

        filledShapePath.close()

        theme.colors.graphFill.setFill()
        filledShapePath.apply(CGAffineTransform(translationX: 0, y: graphOffset))
        filledShapePath.fill()

        // Draw the graph line
        let strokePath = UIBezierPath()
        scaledDataPoints.first.map { value in
            strokePath.move(to: .init(x: 0,
                                      y: (1.0 - value) * graphHeight))
        }

        scaledDataPoints
            .enumerated()
            .dropFirst()
            .forEach { index, value in
                strokePath
                    .addLine(to: .init(x: CGFloat(index) * segmentWidth,
                                       y: (1.0 - value) * graphHeight))
            }

        theme.colors.graphStroke.setStroke()
        strokePath.lineWidth = 2
        strokePath.lineCapStyle = .square
        strokePath.apply(CGAffineTransform(translationX: 0, y: graphOffset))
        strokePath.stroke()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 100, height: style == .compact ? 48 : 88)
    }
}
