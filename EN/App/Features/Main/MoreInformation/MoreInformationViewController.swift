/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

final class MoreInformationViewController: ViewController, MoreInformationViewControllable, MoreInformationTableListener {
    private enum MoreInformationCellIdentifier {
        case aboutApp
        case receivedNotification
        case infected
    }
    
    
    init(listener: MoreInformationListener,
         tableController: MoreInformationTableControlling) {
        self.tableController = tableController
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func loadView() {
        self.view = moreInformationView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupButtonsView()
    }
    
    // MARK: - MoreInformationTableListener
    
    func didSelect(cell: MoreInformationCell, at index: Int) {
        guard (0 ..< cells.keys.count).contains(index) else { return }
        
        switch Array(cells.keys)[index] {
        case .aboutApp:
            listener?.moreInformationRequestsAbout()
        case .infected:
            listener?.moreInformationRequestsInfected()
        case .receivedNotification:
            listener?.moreInformationRequestsReceivedNotification()
        }
    }
    
    // MARK: - Private
    
    private func setupTableView() {
        moreInformationView.tableView.delegate = tableController.delegate
        moreInformationView.tableView.dataSource = tableController.dataSource
        
        tableController.listener = self
        tableController.set(cells: Array(cells.values))
        
        moreInformationView.tableView.reloadData()
        moreInformationView.updateHeightConstraint()
    }
    
    private func setupButtonsView() {
        moreInformationView.addButton(withTitle: "Coronatest aanvragen",
                                      target: self,
                                      action: #selector(didTapRequestTestButton))
        
        moreInformationView.addButton(withTitle: "App delen",
                                      target: self,
                                      action: #selector(didTapRequestShareAppButton))
        
        moreInformationView.addButton(withTitle: "Instellingen",
                                      target: self,
                                      action: #selector(didTapRequestSettingsButton))
    }
    
    @objc
    func didTapRequestTestButton() {
        listener?.moreInformationRequestsRequestTest()
    }
    
    @objc
    func didTapRequestShareAppButton() {
        listener?.moreInformationRequestsShareApp()
    }
    
    @objc
    func didTapRequestSettingsButton() {
        listener?.moreInformationRequestsSettings()
    }
    
    private var cells: [MoreInformationCellIdentifier: MoreInformationCell] {
        // dummy data
        let aboutAppModel = MoreInformationCellViewModel(icon: UIImage(),
                                                         title: "Over de app",
                                                         description: "Hoe de app werkt en wat privacy betekent")
        
        let receivedNotificationModel = MoreInformationCellViewModel(icon: UIImage(),
                                                                     title: "Ik krijg een melding",
                                                                     description: "Wat moet je doen nadat een ander het virus blijkt te hebben")
        let infectedModel = MoreInformationCellViewModel(icon: UIImage(),
                                                         title: "Ik ben besmet",
                                                         description: "Zo laat je anderen weten dat je positief getest bent")
        
        return [
            .aboutApp: aboutAppModel,
            .receivedNotification: receivedNotificationModel,
            .infected: infectedModel
        ]
    }
    
    private lazy var moreInformationView: MoreInformationView = MoreInformationView()
    
    private weak var listener: MoreInformationListener?
    private let tableController: MoreInformationTableControlling
}

fileprivate final class MoreInformationView: View {
    fileprivate let tableView = UITableView()
    fileprivate let buttonsView = UIStackView()
    private var heightConstraint: NSLayoutConstraint?
    
    override func build() {
        super.build()
        
        addSubview(tableView)
        addSubview(buttonsView)
        
        buttonsView.axis = .vertical
        buttonsView.distribution = .fillEqually
        
        tableView.isScrollEnabled = false
        tableView.estimatedRowHeight = 100
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        buttonsView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        let constraints = [
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            buttonsView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 44),
            buttonsView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 44),
            buttonsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -44),
            buttonsView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        
        heightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate(constraints)
    }
    
    fileprivate func updateHeightConstraint() {
        heightConstraint = tableView.heightAnchor.constraint(equalToConstant: tableView.contentSize.height)
        heightConstraint?.isActive = true
    }
    
    fileprivate func addButton(withTitle title: String, target: Any, action: Selector) {
        let buttonView = Button(title: title)
        
        buttonView.addTarget(target, action: action, for: .touchUpInside)
        buttonView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        buttonsView.addArrangedSubview(buttonView)
        buttonsView.setCustomSpacing(20, after: buttonView)
    }
}
