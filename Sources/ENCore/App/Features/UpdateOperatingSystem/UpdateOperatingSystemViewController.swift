/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift
import UIKit

final class UpdateOperatingSystemViewController: ViewController, EnableSettingListener {

    // MARK: - Init

    init(theme: Theme,
         interfaceOrientationStream: InterfaceOrientationStreaming,
         enableSettingBuilder: EnableSettingBuildable) {
        self.interfaceOrientationStream = interfaceOrientationStream
        self.enableSettingBuilder = enableSettingBuilder

        super.init(theme: theme)

        modalPresentationStyle = .fullScreen
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {

        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        internalView.imageView.image = .updateApp
        internalView.titleLabel.attributedText = .makeFromHtml(
            text: .updateSoftwareOSTitle,
            font: theme.fonts.title2,
            textColor: .black,
            textAlignment: Localization.isRTL ? .right : .left)
        internalView.contentLabel.attributedText = .makeFromHtml(
            text: .updateSoftwareOSDescription,
            font: theme.fonts.body,
            textColor: theme.colors.gray,
            textAlignment: Localization.isRTL ? .right : .left)
        internalView.button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)

        interfaceOrientationStream.isLandscape.subscribe { isLandscape in
            self.internalView.showImage = !isLandscape
        }.disposed(by: disposeBag)
    }

    // MARK: - Functions

    @objc func buttonPressed() {
        let viewController = enableSettingBuilder.build(withListener: self,
                                                        setting: .updateOperatingSystem)

        self.enableSettingViewController = viewController

        present(viewController.uiviewController, animated: true, completion: nil)
    }

    // MARK: - EnableSettingListener

    func enableSettingRequestsDismiss(shouldDismissViewController: Bool) {
        enableSettingViewController?.uiviewController.dismiss(animated: true, completion: nil)
    }

    func enableSettingDidTriggerAction() {}

    // MARK: - Private

    private lazy var internalView: UpdateOperatingSystemView = {
        UpdateOperatingSystemView(theme: self.theme, showImage: !(interfaceOrientationStream.currentOrientationIsLandscape ?? false))
    }()
    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private var disposeBag = DisposeBag()
    private let enableSettingBuilder: EnableSettingBuildable
    private var enableSettingViewController: ViewControllable?
}

private final class UpdateOperatingSystemView: View {

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
        button.title = .updateAppButton
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
        return label
    }()

    lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
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
            make.height.equalTo(50)

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
