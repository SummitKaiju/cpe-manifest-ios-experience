//
//  MenuedViewController.swift
//

import UIKit

class MenuedViewController: ExtrasExperienceViewController {

    @IBOutlet weak internal var menuTableView: UITableView?
    internal var menuSections = [MenuSection]()
    fileprivate var selectedSectionValue: String?
    fileprivate var selectedItemValue: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        menuTableView?.separatorStyle = UITableViewCell.SeparatorStyle.none
        menuTableView?.register(UINib(nibName: MenuSectionCell.NibName, bundle: Bundle.frameworkResources), forCellReuseIdentifier: MenuSectionCell.ReuseIdentifier)
        menuTableView?.register(UINib(nibName: MenuItemCell.NibName, bundle: Bundle.frameworkResources), forCellReuseIdentifier: MenuItemCell.ReuseIdentifier)
    }

}

extension MenuedViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return menuSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuSections[section].numRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let menuSection = menuSections[indexPath.section]

        if indexPath.row == 0 {
            let tableViewCell = tableView.dequeueReusableCell(withIdentifier: MenuSectionCell.ReuseIdentifier, for: indexPath)
            guard let cell = tableViewCell as? MenuSectionCell else {
                return tableViewCell
            }

            cell.menuSection = menuSection
            cell.active = selectedSectionValue == cell.menuSection?.value

            return cell
        }

        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: MenuItemCell.ReuseIdentifier, for: indexPath)
        guard let cell = tableViewCell as? MenuItemCell else {
            return tableViewCell
        }

        if let menuItem = menuSection.item(atIndex: indexPath.row - 1) {
            cell.menuItem = menuItem
            cell.active = (selectedItemValue == menuItem.value)
        }

        return cell
    }

}

extension MenuedViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return (DeviceType.IS_IPAD ? 60 : 40)
        }

        return (DeviceType.IS_IPAD ? 40 : 30)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let updateActiveCells = { [weak self] in
            if let strongSelf = self {
                for cell in tableView.visibleCells {
                    if let menuSectionCell = cell as? MenuSectionCell {
                        menuSectionCell.active = strongSelf.selectedSectionValue == menuSectionCell.menuSection?.value
                    } else if let menuItemCell = cell as? MenuItemCell {
                        menuItemCell.active = strongSelf.selectedItemValue == menuItemCell.menuItem?.value
                    }
                }
            }
        }

        let menuSection = menuSections[indexPath.section]
        if indexPath.row == 0 {
            menuSection.toggle()

            if let cell = tableView.cellForRow(at: indexPath) as? MenuSectionCell {
                cell.toggleDropDownIcon()
            }

            if !menuSection.isExpandable {
                selectedSectionValue = menuSection.value
                selectedItemValue = nil
            }

            CATransaction.begin()
            CATransaction.setCompletionBlock(updateActiveCells)
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: UITableView.RowAnimation.none)
            CATransaction.commit()
        } else {
            selectedItemValue = menuSection.item(atIndex: indexPath.row - 1)?.value
            selectedSectionValue = menuSection.value
            updateActiveCells()
        }
    }

}
