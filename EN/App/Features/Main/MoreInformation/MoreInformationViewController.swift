/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

/// @mockable
protocol MoreInformationRouting: Routing {
}

final class MoreInformationViewController: ViewController, MoreInformationViewControllable {
    
    init(tableController: MoreInformationTableControlling) {
        self.tableController = tableController
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    // MARK: - MoreInformationViewControllable
    
    weak var router: MoreInformationRouting?
    
    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        present(viewController.uiviewController,
                animated: animated,
                completion: completion)
    }
    
    func dismiss(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        viewController.uiviewController.dismiss(animated: animated, completion: completion)
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
    
    // MARK: - Private
    
    private func setupTableView() {
        moreInformationView.tableView.delegate = tableController.delegate
        moreInformationView.tableView.dataSource = tableController.dataSource
        
        // dummy data
        tableController.set(cells: [
            MoreInformationCellViewModel(icon: UIImage(), title: "Over de app", description: "Hoe de app werkt en wat privacy betekent"),
            MoreInformationCellViewModel(icon: UIImage(), title: "Ik krijg een melding", description: "Wat moet je doen nadat een ander het virus blijkt te hebben"),
            MoreInformationCellViewModel(icon: UIImage(), title: "Ik ben besmet", description: "Zo laat je anderen weten dat je positief getest bent"),
        ])
        moreInformationView.tableView.reloadData()
        moreInformationView.updateHeightConstraint()
    }
    
    private func setupButtonsView() {
        moreInformationView.set(buttonTitles: [
            "Coronatest aanvragen",
            "App delen",
            "Instellingen"
        ])
    }
    
    private lazy var moreInformationView: MoreInformationView = MoreInformationView()
    
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
    
    fileprivate func set(buttonTitles: [String]) {
        buttonsView.arrangedSubviews.forEach { view in
            buttonsView.removeArrangedSubview(view)
        }
        
        buttonTitles.forEach { title in
            let buttonView = Button(title: title)
            buttonView.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            buttonsView.addArrangedSubview(buttonView)
            buttonsView.setCustomSpacing(20, after: buttonView)
        }
    }
}
