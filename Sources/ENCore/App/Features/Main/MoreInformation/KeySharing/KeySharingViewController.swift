/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import ENFoundation

/// @mockable
protocol KeySharingRouting: Routing {
    func routeToShareKeyViaGGD(animated: Bool, withBackButton: Bool)
    func routeToShareKeyViaWebsite()
    func keySharingWantsDismissal(shouldDismissViewController: Bool)
    func viewDidLoad()
}

final class KeySharingViewController: ViewController, KeySharingViewControllable, KeySharingViewListener, UIAdaptivePresentationControllerDelegate {
    
    // MARK: - KeySharingViewControllable
    
    weak var router: KeySharingRouting?
    
    override func loadView() {
        self.view = choiceView
        self.view.frame = UIScreen.main.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = closeBarButtonItem
        router?.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setThemeNavigationBar(withTitle: .moreInformationInfectedTitle, topItem: navigationItem)
    }
        
    func push(viewController: ViewControllable, animated: Bool) {
        navigationController?.pushViewController(viewController.uiviewController, animated: animated)
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
            router?.routeToShareKeyViaGGD(animated: true, withBackButton: true)
        case .shareKeyWebsite:
            router?.routeToShareKeyViaWebsite()
        default:
            return
        }
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        router?.keySharingWantsDismissal(shouldDismissViewController: false)
    }
    
    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        router?.keySharingWantsDismissal(shouldDismissViewController: true)
    }
    
    // MARK: - Private
    
    private lazy var choiceView = KeySharingView(theme: self.theme, listener: self)
    private lazy var closeBarButtonItem = UIBarButtonItem.closeButton(target: self, action: #selector(didTapCloseButton))    
}

fileprivate protocol KeySharingViewListener: AnyObject {
    func didSelect(identifier: MoreInformationIdentifier)
}

private final class KeySharingView: View, MoreInformationCellListner {
    
    private lazy var scrollableStackView = ScrollableStackView(theme: theme)
    private weak var listener: KeySharingViewListener?
    
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
                                                                                                             title: .moreInformationKeySharingCoronaTestOption1Title,
                                                                                                             subtitle: .moreInformationKeySharingCoronaTestOption1Content)))
        
        stack.addArrangedSubview(MoreInformationCell(listener: self, theme: theme, data: MoreInformationCellViewModel(identifier: .shareKeyGGD,
                                                                                             icon: .phone,
                                                                                             title: .moreInformationKeySharingCoronaTestOption2Title,
                                                                                             subtitle: .moreInformationKeySharingCoronaTestOption2Content)))
        
        return stack
    }()
    
    private lazy var titleLabel: Label = {
        let label = Label(frame: .zero)
        label.isUserInteractionEnabled = true
        label.font = theme.fonts.title3
        label.text = .moreInformationKeySharingCoronaTestHeaderTitle
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()
    
    private lazy var descriptionLabel: Label = {
        let label = Label()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .moreInformationKeySharingCoronaTestHeaderContent
        return label
    }()
    
    // MARK: - Init
    
    init(theme: Theme,
         listener: KeySharingViewListener) {
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
        scrollableStackView.spacing = 0
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
            maker.bottom.equalTo(contentContainer).inset(64)
            maker.leading.trailing.equalTo(contentContainer.safeAreaLayoutGuide).inset(16)
        }
    }
}
