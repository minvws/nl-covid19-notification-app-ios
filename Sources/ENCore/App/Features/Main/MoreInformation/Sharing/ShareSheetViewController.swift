/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation
import UIKit

/// @mockable
protocol ShareSheetViewControllable: ViewControllable {}

final class ShareSheetViewController: ViewController, ShareSheetViewControllable, UIAdaptivePresentationControllerDelegate, Logging {

    init(listener: ShareSheetListener,
         theme: Theme,
         deviceOrientationStream: DeviceOrientationStreaming) {
        self.listener = listener

        self.deviceOrientationStream = deviceOrientationStream

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = closeBarButtonItem

        internalView.showVisual = !(deviceOrientationStream.currentOrientationIsLandscape ?? false)
        internalView.button.action = { [weak self] in
            if let viewController = self {
                self?.listener?.displayShareSheet(usingViewController: viewController, completion: { completed in
                    if completed {
                        self?.didTapClose()
                    }
                })
            } else {
                self?.logError("Couldn't retreive a viewcontroller")
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        deviceOrientationStreamCancellable = deviceOrientationStream
            .isLandscape
            .sink(receiveValue: { [weak self] isLandscape in
                self?.internalView.showVisual = !isLandscape
        })
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        deviceOrientationStreamCancellable = nil
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.shareSheetDidComplete(shouldHideViewController: false)
    }

    // MARK: - Private

    @objc
    func didTapClose() {
        listener?.shareSheetDidComplete(shouldHideViewController: true)
    }

    private let deviceOrientationStream: DeviceOrientationStreaming
    private var deviceOrientationStreamCancellable: AnyCancellable?
    private weak var listener: ShareSheetListener?
    private lazy var internalView: ShareSheetView = ShareSheetView(theme: self.theme)
    private lazy var closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                          target: self,
                                                          action: #selector(didTapClose))
}

final class ShareSheetView: View {

    private lazy var scrollView = UIScrollView()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    lazy var button: Button = {
        let button = Button(theme: self.theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .primary
        return button
    }()

    private lazy var viewsInDisplayOrder = [imageView, titleLabel, contentLabel]

    var showVisual: Bool = true {
        didSet {
            setupConstraints()
            imageView.isHidden = !showVisual
        }
    }

    override func build() {
        super.build()

        imageView.image = Image.named("ShareApp")
        titleLabel.attributedText = .makeFromHtml(text: .moreInformationShareTitle,
                                                  font: theme.fonts.title2,
                                                  textColor: .black,
                                                  textAlignment: Localization.isRTL ? .right : .left)
        contentLabel.attributedText = .makeFromHtml(text: .moreInformationShareContent,
                                                    font: theme.fonts.body,
                                                    textColor: theme.colors.gray,
                                                    textAlignment: Localization.isRTL ? .right : .left)
        button.title = .moreInformationShareButton

        addSubview(scrollView)
        addSubview(button)

        viewsInDisplayOrder.forEach { scrollView.addSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        scrollView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.bottom.equalTo(button.snp.top).inset(-16)
        }

        if showVisual,
            let width = imageView.image?.size.width,
            let height = imageView.image?.size.height,
            width > 0, height > 0 {

            let aspectRatio = height / width

            imageView.snp.makeConstraints { maker in
                maker.top.equalToSuperview()
                maker.leading.trailing.equalTo(self).inset(16)
                maker.height.equalTo(scrollView.snp.width).multipliedBy(aspectRatio)
            }
        }

        titleLabel.snp.remakeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.height.greaterThanOrEqualTo(50)
            if showVisual {
                maker.top.equalTo(imageView.snp.bottom).offset(25)
            } else {
                maker.top.equalToSuperview()
            }
        }

        contentLabel.snp.remakeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.height.greaterThanOrEqualTo(50)
            maker.bottom.lessThanOrEqualTo(scrollView.snp.bottom)
        }

        button.snp.remakeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.height.equalTo(50)

            constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
        }
    }
}
