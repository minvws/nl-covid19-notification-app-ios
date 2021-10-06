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
        exposureStateDisposable = nil
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

        if self.setting == .enableBluetooth && exposureStateStream.currentExposureState.activeState == .inactive(.bluetoothOff) {
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
    private lazy var internalView: EnableSettingView = EnableSettingView(theme: theme, listener: listener)

    private let setting: EnableSetting
    private let exposureStateStream: ExposureStateStreaming
    private let environmentController: EnvironmentControlling
    private var exposureStateDisposable: Disposable?

    @objc private func didTapCloseButton() {
        listener?.enableSettingRequestsDismiss(shouldDismissViewController: true)
    }

    @objc private func checkBluetoothStatus() {
        guard exposureStateDisposable == nil else {
            return
        }

        exposureStateDisposable = exposureStateStream
            .exposureState
            .observe(on: MainScheduler.instance)
            .filter { (state) -> Bool in
                state.activeState != .inactive(.bluetoothOff)
            }
            .first()
            .subscribe(onSuccess: { _ in
                self.listener?.enableSettingRequestsDismiss(shouldDismissViewController: true)
            })
    }
}

private final class EnableSettingView: View {
    private lazy var scrollView = UIScrollView()
    private lazy var titleLabel = Label()
    private lazy var introductionLabel = Label()
    private lazy var stepTitleLabel = Label()
    private lazy var footerLabel = Label()

    fileprivate lazy var button = Button(theme: theme)
    fileprivate lazy var navigationBar = UINavigationBar()

    private weak var listener: EnableSettingListener?
    private var buttonToBottomConstraint: Constraint?
    private var contentToBottomConstraint: Constraint?

    private var stepViews: [EnableSettingStepView] = []
    private lazy var stepContainerView: UIStackView = {
        let stack = UIStackView(frame: .zero)
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(frame: .zero)
        stack.axis = .vertical
        stack.spacing = 32
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(introductionLabel)
        stack.addArrangedSubview(stepTitleLabel)
        stack.addArrangedSubview(stepContainerView)
        stack.addArrangedSubview(footerLabel)
        return stack
    }()

    init(theme: Theme, listener: EnableSettingListener?) {
        self.listener = listener
        super.init(theme: theme)
    }

    override func build() {
        super.build()

        scrollView.contentInsetAdjustmentBehavior = .automatic
        scrollView.alwaysBounceVertical = true

        titleLabel.font = theme.fonts.title1
        titleLabel.accessibilityTraits = [.header]
        titleLabel.numberOfLines = 0

        introductionLabel.font = theme.fonts.body
        introductionLabel.numberOfLines = 0

        stepTitleLabel.font = theme.fonts.title2
        stepTitleLabel.numberOfLines = 0
        stepTitleLabel.accessibilityTraits = [.header]

        footerLabel.font = theme.fonts.body
        footerLabel.numberOfLines = 0

        let navigationItem = UINavigationItem()
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(target: self, action: #selector(didTapClose))
        navigationBar.setItems([navigationItem], animated: false)
        navigationBar.makeTransparant()

        button.isHidden = true

        scrollView.addSubview(stackView)
        addSubview(navigationBar)
        addSubview(scrollView)
        addSubview(button)
    }

    @objc func didTapClose() {
        listener?.enableSettingRequestsDismiss(shouldDismissViewController: true)
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        navigationBar.snp.makeConstraints { make in

            if #available(iOS 13, *) {
                make.top.leading.trailing.equalToSuperview()
            } else {
                make.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            }
        }

        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(32)
            make.width.equalTo(scrollView).inset(16)
        }

        button.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(scrollView.snp.bottom).offset(16)
            make.height.greaterThanOrEqualTo(48)
        }

        scrollView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(safeAreaLayoutGuide)
            make.top.equalTo(navigationBar.snp.bottom).offset(8)
        }
    }

    // MARK: - Private

    fileprivate func update(model: EnableSettingModel, actionCompletion: @escaping () -> ()) {
        titleLabel.text = model.title
        introductionLabel.attributedText = model.introduction
        stepTitleLabel.attributedText = model.stepTitle
        footerLabel.attributedText = model.footer

        introductionLabel.isHidden = introductionLabel.attributedText == nil
        stepTitleLabel.isHidden = stepTitleLabel.attributedText == nil
        footerLabel.isHidden = footerLabel.attributedText == nil

        buttonToBottomConstraint?.isActive = model.action != nil
        contentToBottomConstraint?.isActive = model.action == nil

        if let action = model.action {
            button.isHidden = false
            button.setTitle(model.actionTitle, for: .normal)
            button.action = {
                action.action(actionCompletion)
            }

            button.snp.makeConstraints { make in
                constrainToSafeLayoutGuidesWithBottomMargin(maker: make)
            }
        } else {
            scrollView.snp.makeConstraints { make in
                constrainToSafeLayoutGuidesWithBottomMargin(maker: make)
            }
        }

        stepViews.forEach { $0.removeFromSuperview() }

        var stepIndex = 0

        stepViews = model.steps.map { model in
            stepIndex += 1

            return EnableSettingStepView(theme: theme, step: model, stepIndex: stepIndex)
        }

        stepViews.enumerated().forEach { index, stepView in
            stepContainerView.addListSubview(stepView, index: index, total: stepViews.count)
        }
    }
}
