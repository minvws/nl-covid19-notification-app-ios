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

final class EnableSettingViewController: ViewController, UIAdaptivePresentationControllerDelegate {

    init(listener: EnableSettingListener,
         theme: Theme,
         setting: EnableSetting,
         exposureStateStream: ExposureStateStreaming,
         environmentController: EnvironmentControlling) {
        self.listener = listener
        self.setting = setting
        self.exposureStateStream = exposureStateStream
        self.environmentController = environmentController

        super.init(theme: theme)
        presentationController?.delegate = self
    }

    deinit {
        exposureStateCancellable = nil
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        internalView.update(model: setting.model(theme: theme, environmentController: environmentController), actionCompletion: { [weak self] in
            self?.listener?.enableSettingDidTriggerAction()
        })

        internalView.navigationBar.topItem?.rightBarButtonItem?.target = self
        internalView.navigationBar.topItem?.rightBarButtonItem?.action = #selector(didTapCloseButton)

        if self.setting == .enableBluetooth && exposureStateStream.currentExposureState?.activeState == .inactive(.bluetoothOff) {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(checkBluetoothStatus),
                                                   name: UIApplication.didBecomeActiveNotification,
                                                   object: nil)
        }
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.enableSettingRequestsDismiss(shouldDismissViewController: false)
    }

    // MARK: - Private

    private weak var listener: EnableSettingListener?
    private lazy var internalView: EnableSettingView = EnableSettingView(theme: theme)
    private let setting: EnableSetting
    private let exposureStateStream: ExposureStateStreaming
    private let environmentController: EnvironmentControlling
    private var exposureStateCancellable: AnyCancellable?

    @objc private func didTapCloseButton() {
        listener?.enableSettingRequestsDismiss(shouldDismissViewController: true)
    }

    @objc private func checkBluetoothStatus() {
        guard exposureStateCancellable == nil else {
            return
        }

        exposureStateCancellable = exposureStateStream
            .exposureState
            .filter { (state) -> Bool in
                state.activeState != .inactive(.bluetoothOff)
            }
            .first()
            .sink { state in
                self.listener?.enableSettingRequestsDismiss(shouldDismissViewController: true)
            }
    }
}

private final class EnableSettingView: View {
    private lazy var scrollView = UIScrollView()
    private lazy var titleLabel = Label()
    fileprivate lazy var button = Button(theme: theme)
    fileprivate lazy var navigationBar = UINavigationBar()

    private var stepViews: [EnableSettingStepView] = []

    override func build() {
        super.build()

        scrollView.contentInsetAdjustmentBehavior = .automatic
        scrollView.alwaysBounceVertical = true

        titleLabel.font = theme.fonts.title1
        titleLabel.numberOfLines = 0
        scrollView.addSubview(titleLabel)

        let navigationItem = UINavigationItem()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                            target: nil,
                                                            action: nil)
        navigationBar.setItems([navigationItem], animated: false)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationBar.standardAppearance = appearance

        button.isHidden = true

        addSubview(navigationBar)
        addSubview(scrollView)
        addSubview(button)
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        navigationBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(32)
        }

        button.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(scrollView.snp.bottom).offset(16)
            make.height.equalTo(48)

            constrainToSafeLayoutGuidesWithBottomMargin(maker: make)
        }

        scrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom).offset(8)
        }
    }

    // MARK: - Private

    fileprivate func update(model: EnableSettingModel, actionCompletion: @escaping () -> ()) {
        titleLabel.text = model.title
        if let action = model.action {
            button.isHidden = false
            button.setTitle(model.actionTitle, for: .normal)
            button.action = {
                action.action(actionCompletion)
            }
        }

        stepViews.forEach { $0.removeFromSuperview() }

        var stepIndex = 0

        stepViews = model.steps.map { model in
            stepIndex += 1

            return EnableSettingStepView(theme: theme, step: model, stepIndex: stepIndex)
        }

        stepViews.forEach(scrollView.addSubview(_:))

        updateStepViewConstraints()
    }

    private func updateStepViewConstraints() {
        var isFirst = true

        var yAnchor: View?

        stepViews.forEach { view in

            view.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.width.equalTo(scrollView)

                if isFirst {
                    make.top.equalTo(titleLabel.snp.bottom).offset(32)
                } else if let yAnchor = yAnchor {
                    make.top.equalTo(yAnchor.snp.bottom).offset(8)
                }

                // Anchor the last stepview to the bottom of the scrollview
                if view == stepViews.last {
                    make.bottom.equalTo(scrollView.snp.bottom).inset(32)
                }
            }

            yAnchor = view
            isFirst = false
        }
    }
}
