//
//  MoreInformationTableController.swift
//  EN
//
//  Created by Robin van Dijke on 09/06/2020.
//

import UIKit

protocol MoreInformationTableControlling: UITableViewDelegate, UITableViewDataSource {
    func set(cells: [MoreInformationCell])
}

protocol MoreInformationCell {
    var icon: UIImage { get }
    var title: String { get }
    var description: String { get }
}

struct MoreInformationCellViewModel: MoreInformationCell {
    let icon: UIImage
    let title: String
    let description: String
}

final class MoreInformationTableController: NSObject, MoreInformationTableControlling {
    
    // MARK: - MoreInformationTableControlling
    
    func set(cells: [MoreInformationCell]) {
        self.cells = cells
    }
    
    // MARK: - UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: Return proper designed cell
        
        let cell: UITableViewCell
        
        let reuseIdentifier = "Cell"
        
        if let aCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) {
            cell = aCell
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        }
        
        let cellViewModel = cells[indexPath.row]
        cell.textLabel?.text = cellViewModel.title
        cell.detailTextLabel?.text = cellViewModel.description
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Meer informatie".uppercased()
    }
    
    // MARK: - Private
    
    private var cells: [MoreInformationCell] = []
}
