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

/// @mockable
protocol NoInternetViewControllable: ViewControllable {}

final class NoInternetViewController: ViewController, NoInternetViewControllable, Logging {

    init(listener: NoInternetListener,
         theme: Theme,
         interfaceOrientationStream: InterfaceOrientationStreaming) {
        self.listener = listener
        self.interfaceOrientationStream = interfaceOrientationStream

        super.init(theme: theme)

        modalPresentationStyle = .overFullScreen
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupContent()

        interfaceOrientationStream.isLandscape.subscribe { isLandscape in
            self.internalView.showImage = !isLandscape
        }.disposed(by: disposeBag)
    }

    // MARK: - Private

    private weak var listener: NoInternetListener?
    private lazy var internalView: NoInternetView = {
        NoInternetView(theme: self.theme, showImage: !(interfaceOrientationStream.currentOrientationIsLandscape ?? false))
    }()
    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private var disposeBag = DisposeBag()

    private func setupContent() {
        internalView.imageView.image = .illustrationNotification
        internalView.titleLabel.text = .noInternetErrorTitle
        internalView.contentLabel.text = .noInternetErrorMessage
        internalView.button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }

    @objc private func buttonPressed() {
        listener?.noInternetRequestsRetry()
    }
}

private final class NoInternetView: View {

    lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        return view
    }()

    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 16

        view.addArrangedSubview(imageViewContainer)
        view.addArrangedSubview(titleLabel)
        view.addArrangedSubview(contentLabel)

        view.setCustomSpacing(50, after: imageViewContainer)
        return view
    }()

    lazy var button: Button = {
        let button = Button(theme: self.theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.title = .retry
        return button
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        return imageView
    }()

    lazy var imageViewContainer: UIView = {
        let container = UIView()
        container.addSubview(imageView)
        return container
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = theme.fonts.title2
        return label
    }()

    lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = theme.fonts.body
        return label
    }()

    var showImage: Bool {
        didSet {
            imageViewContainer.isHidden = !showImage
        }
    }

    // MARK: - Init

    init(theme: Theme, showImage: Bool) {
        self.showImage = showImage

        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        hasBottomMargin = true

        addSubview(scrollView)
        scrollView.addSubview(stackView)
        addSubview(button)
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(button.snp.top)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(75)
            make.leading.trailing.equalTo(self.safeAreaLayoutGuide).inset(20)
            make.bottom.equalToSuperview().offset(-50).priority(.high)
        }

        button.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.safeAreaLayoutGuide).inset(20)
            make.height.greaterThanOrEqualTo(50)

            constrainToSafeLayoutGuidesWithBottomMargin(maker: make)
        }

        imageView.snp.makeConstraints { make in
            make.centerX.equalTo(imageViewContainer)
            make.width.equalToSuperview().inset(30)
            make.height.equalTo(imageView.snp.width).multipliedBy(0.83)
            make.top.bottom.equalToSuperview()
        }
    }
}
