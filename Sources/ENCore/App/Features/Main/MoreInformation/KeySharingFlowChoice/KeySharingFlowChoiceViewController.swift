/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import ENFoundation

/// @mockable
protocol KeySharingFlowChoiceRouting: Routing {
    func routeToShareKeyViaGGD()
    func routeToShareKeyViaWebsite()
    func keySharingFlowChoiceWantsDismissal(shouldDismissViewController: Bool)
}

final class KeySharingFlowChoiceViewController: ViewController, KeySharingFlowChoiceViewControllable, KeySharingFlowChoiceViewListener, UIAdaptivePresentationControllerDelegate {
    
    // MARK: - KeySharingFlowChoiceViewControllable
    
    weak var router: KeySharingFlowChoiceRouting?
    
    override init(theme: Theme) {
        super.init(theme: theme)
    }
    
    override func loadView() {
        self.view = choiceView
        self.view.frame = UIScreen.main.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setThemeNavigationBar(withTitle: .moreInformationInfectedTitle)
        navigationItem.rightBarButtonItem = closeBarButtonItem
        
    }
    
    func presentInNavigationController(viewController: ViewControllable) {
        let navigationController = NavigationController(rootViewController: viewController.uiviewController, theme: theme)

        if let presentationDelegate = viewController.uiviewController as? UIAdaptivePresentationControllerDelegate {
            navigationController.presentationController?.delegate = presentationDelegate
        }

        present(navigationController, animated: true, completion: nil)
    }
    
    func dismiss(viewController: ViewControllable) {
        if let navigationController = viewController.uiviewController.navigationController {
            navigationController.dismiss(animated: true, completion: nil)
        } else {
            viewController.uiviewController.dismiss(animated: true, completion: nil)
        }
    }
    
    func didSelect(identifier: MoreInformationIdentifier) {
        switch identifier {
        case .shareKeyGGD:
            router?.routeToShareKeyViaGGD()
        case .shareKeyWebsite:
            let alert = UIAlertController(title: "Not implemented yet", message: nil, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            router?.routeToShareKeyViaWebsite()
        default:
            return
        }
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        router?.keySharingFlowChoiceWantsDismissal(shouldDismissViewController: false)
    }
    
    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        router?.keySharingFlowChoiceWantsDismissal(shouldDismissViewController: true)
    }
    
    // MARK: - Private
    
    private lazy var choiceView = KeySharingFlowChoiceView(theme: self.theme, listener: self)
    private lazy var closeBarButtonItem = UIBarButtonItem.closeButton(target: self, action: #selector(didTapCloseButton))    
}

fileprivate protocol KeySharingFlowChoiceViewListener: AnyObject {
    func didSelect(identifier: MoreInformationIdentifier)
}

private final class KeySharingFlowChoiceView: View, MoreInformationCellListner {
    
    private lazy var scrollableStackView = ScrollableStackView(theme: theme)
    private weak var listener: KeySharingFlowChoiceViewListener?
    
    private lazy var contentContainer: UIView = {
        let view = UIView(frame: .zero)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        return view
    }()
    
    private lazy var buttonContainer: UIStackView = {
        let stack = UIStackView(frame: .zero)
        stack.axis = .vertical
        stack.addArrangedSubview(MoreInformationCell(listener: self, theme: theme, data: MoreInformationCellViewModel(identifier: .shareKeyWebsite,
                                                                                                             icon: .computer,
                                                                                                             title: "via website title",
                                                                                                             subtitle: "via website subtitle")))
        
        stack.addArrangedSubview(MoreInformationCell(listener: self, theme: theme, data: MoreInformationCellViewModel(identifier: .shareKeyGGD,
                                                                                             icon: .phone,
                                                                                             title: "via phone title",
                                                                                             subtitle: "via phone subtitle")))
        
        return stack
    }()
    
    private lazy var titleLabel: Label = {
        let label = Label(frame: .zero)
        label.isUserInteractionEnabled = true
        label.font = theme.fonts.title3
        label.text = "some title"
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()
    
    private lazy var descriptionLabel: Label = {
        let label = Label()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "some text"
        return label
    }()
    
    // MARK: - Init
    
    init(theme: Theme,
         listener: KeySharingFlowChoiceViewListener) {
        self.listener = listener
        super.init(theme: theme)
    }
    
    func didSelect(identifier: MoreInformationIdentifier) {
        listener?.didSelect(identifier: identifier)
    }
    
    // MARK: - Overrides
    
    override func build() {
        super.build()
        
        addSubview(scrollableStackView)
        scrollableStackView.spacing = 64
        scrollableStackView.stackViewBottomMargin = 32
        scrollableStackView.addSections([
            contentContainer,
            buttonContainer
        ])
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        scrollableStackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.top.bottom.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(contentContainer)
            maker.leading.trailing.equalTo(contentContainer.safeAreaLayoutGuide).inset(16)
        }
        
        descriptionLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(21)
            maker.bottom.equalTo(contentContainer.safeAreaLayoutGuide)
            maker.leading.trailing.equalTo(contentContainer.safeAreaLayoutGuide).inset(16)
        }
    }
}
