/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Lottie
import UIKit

protocol OnboardingStepViewControllable: ViewControllable {}

final class OnboardingStepViewController: ViewController, OnboardingStepViewControllable {

    private lazy var button: Button = {
        let button = Button(theme: self.theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    init(onboardingManager: OnboardingManaging,
         onboardingStepBuilder: OnboardingStepBuildable,
         listener: OnboardingStepListener,
         theme: Theme,
         index: Int) {

        self.onboardingManager = onboardingManager
        self.onboardingStepBuilder = onboardingStepBuilder
        self.listener = listener
        self.index = index

        guard let step = self.onboardingManager.getStep(index) else { fatalError("OnboardingStep index out of range") }

        self.onboardingStep = step

        super.init(theme: theme)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.internalView.onboardingStep = self.onboardingStep

        setThemeNavigationBar()

        self.button.title = self.onboardingStep.buttonTitle
        view.addSubview(button)

        setupConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if internalView.animationView.animation != nil, animationsEnabled() {
            self.internalView.animationView.play()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.internalView.animationView.stop()
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    // MARK: - Private

    private weak var listener: OnboardingStepListener?
    private lazy var internalView: OnboardingStepView = OnboardingStepView(theme: self.theme)
    private lazy var viewsInDisplayOrder = [button]
    private var index: Int
    private var onboardingStep: OnboardingStep
    private let onboardingManager: OnboardingManaging
    private let onboardingStepBuilder: OnboardingStepBuildable

    // MARK: - Setups

    private func setupViews() {
        setThemeNavigationBar()

        viewsInDisplayOrder.forEach { view.addSubview($0) }
    }

    private func setupConstraints() {

        var constraints = [[NSLayoutConstraint]()]

        constraints.append([
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: ViewController.deviceHasHomeButton() ? -16 : 0),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])

        for constraint in constraints { NSLayoutConstraint.activate(constraint) }
    }

    // MARK: - Functions

    @objc func buttonPressed() {
        let nextIndex = self.index + 1
        if onboardingManager.onboardingSteps.count > nextIndex {
            listener?.nextStepAtIndex(nextIndex)
        } else {
            // build consent
            listener?.onboardingStepsDidComplete()
        }
    }
}

final class OnboardingStepView: View {

    lazy var animationView: AnimationView = {
        let animationView = AnimationView()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFill
        return animationView
    }()

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
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    private lazy var viewsInDisplayOrder = [imageView, animationView, titleLabel, contentLabel]

    var onboardingStep: OnboardingStep? {
        didSet {
            updateView()
        }
    }

    deinit {
        displayLink?.invalidate()
        displayLink = nil
    }

    override func build() {
        super.build()

        viewsInDisplayOrder.forEach { addSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        var constraints = [[NSLayoutConstraint]()]

        constraints.append([
            imageView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 0),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.7, constant: 1)
        ])

        constraints.append([
            animationView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 0),
            animationView.leadingAnchor.constraint(equalTo: leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: trailingAnchor),
            animationView.heightAnchor.constraint(equalTo: animationView.widthAnchor, multiplier: 0.7, constant: 1)
        ])

        constraints.append([
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])

        constraints.append([
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            contentLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            contentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])

        for constraint in constraints { NSLayoutConstraint.activate(constraint) }

        self.contentLabel.sizeToFit()
    }

    func updateView() {

        guard let step = self.onboardingStep else {
            return
        }

        self.titleLabel.attributedText = step.attributedTitle
        self.contentLabel.attributedText = step.attributedContent
        self.displayLink?.invalidate()
        self.displayLink = nil
        self.frameNumber = nil

        switch step.illustration {
        case let .image(named: name):
            imageView.image = Image.named(name)
            animationView.isHidden = true
            imageView.isHidden = false
        case let .animation(named: name, repeatFromFrame: repeatFromFrame):
            animationView.animation = LottieAnimation.named(name)
            animationView.isHidden = false
            imageView.isHidden = true

            if let repeatFromFrame = repeatFromFrame {
                loopAnimation(fromFrame: repeatFromFrame)
            } else {
                animationView.loopMode = .loop
            }
        }
    }

    // MARK: - Private

    var displayLink: CADisplayLink?
    var frameNumber: Int?

    private func loopAnimation(fromFrame frameNumber: Int) {
        self.frameNumber = frameNumber

        displayLink?.invalidate()

        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: RunLoop.current, forMode: .common)
    }

    @objc private func tick() {
        if animationView.currentProgress == 1.0,
            animationView.isAnimationPlaying == false,
            let frameNumber = frameNumber {
            animationView.play(fromFrame: CGFloat(frameNumber),
                               toFrame: animationView.animation?.endFrame ?? 0,
                               loopMode: nil,
                               completion: nil)
        }
    }
}
