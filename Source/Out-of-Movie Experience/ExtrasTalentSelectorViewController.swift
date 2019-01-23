//
//  ExtrasTalentSelectorViewController.swift
//

import UIKit
import AVFoundation
import CPEData

class ExtrasTalentSelectorViewController: ExtrasExperienceViewController {

    @IBOutlet private weak var talentTableView: UITableView!
    @IBOutlet private weak var talentDetailView: UIView!
    
    var personJobFunction = PersonJobFunction.actor

    private var talentDetailViewController: TalentDetailViewController?
    fileprivate var selectedIndexPath: IndexPath?

    // MARK: View Lifecycle
    override func viewDidLoad() {
        customTitle = CPEDataUtils.titleForPeople(with: personJobFunction)

        super.viewDidLoad()

        talentTableView.register(UINib(nibName: TalentTableViewCell.NibNameNarrow + (DeviceType.IS_IPAD ? "" : "_iPhone"), bundle: Bundle.frameworkResources), forCellReuseIdentifier: TalentTableViewCell.ReuseIdentifier)

        showBackButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if selectedIndexPath == nil {
            let path = IndexPath(row: 0, section: 0)
            self.talentTableView.selectRow(at: path, animated: false, scrollPosition: .top)
            self.tableView(self.talentTableView, didSelectRowAt: path)
        }
    }

    // MARK: Talent Details
    fileprivate func showTalentDetailView() {
        if selectedIndexPath != nil, let talent = (talentTableView?.cellForRow(at: selectedIndexPath!) as? TalentTableViewCell)?.talent, let talentDetailViewController = UIStoryboard.viewController(for: TalentDetailViewController.self) as? TalentDetailViewController {
            talentDetailViewController.talent = talent

            talentDetailViewController.view.frame = talentDetailView.bounds
            talentDetailView.addSubview(talentDetailViewController.view)
            self.addChild(talentDetailViewController)
            talentDetailViewController.didMove(toParent: self)

            showBackButton()

            if talentDetailView.isHidden {
                talentDetailView.alpha = 0
                talentDetailView.isHidden = false
                UIView.animate(withDuration: 0.25, animations: {
                    self.talentDetailView.alpha = 1
                })
            } else {
                talentDetailViewController.view.alpha = 0
                UIView.animate(withDuration: 0.25, animations: {
                    talentDetailViewController.view.alpha = 1
                })
            }

            self.talentDetailViewController = talentDetailViewController
            Analytics.log(event: .extrasAction, action: .selectTalent, itemId: talent.id)
        }
    }

    fileprivate func hideTalentDetailView(completed: (() -> Void)? = nil) {
        if talentDetailViewController != nil {
            if selectedIndexPath != nil {
                talentTableView?.deselectRow(at: selectedIndexPath!, animated: true)
                selectedIndexPath = nil
            }

            if completed == nil {
                showHomeButton()
            }

            UIView.animate(withDuration: 0.25, animations: {
                if completed != nil {
                    self.talentDetailViewController?.view.alpha = 0
                } else {
                    self.talentDetailView?.alpha = 0
                }
            }, completion: { (_) -> Void in
                if completed == nil {
                    self.talentDetailView?.isHidden = true
                }

                self.talentDetailViewController?.willMove(toParent: nil)
                self.talentDetailViewController?.view.removeFromSuperview()
                self.talentDetailViewController?.removeFromParent()
                self.talentDetailViewController = nil
                completed?()
            })
        } else {
            completed?()
        }
    }

}

extension ExtrasTalentSelectorViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (CPEDataUtils.people?[personJobFunction]?.count ?? 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: TalentTableViewCell.ReuseIdentifier, for: indexPath)
        guard let cell = tableViewCell as? TalentTableViewCell else {
            return tableViewCell
        }

        if let people = CPEDataUtils.people?[personJobFunction], people.count > indexPath.row {
            cell.talent = people[indexPath.row]
        }

        return cell
    }

}

extension ExtrasTalentSelectorViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return (indexPath != selectedIndexPath ? indexPath : nil)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        hideTalentDetailView { [weak self] in
            self?.selectedIndexPath = indexPath
            self?.showTalentDetailView()
        }
    }

}

extension ExtrasTalentSelectorViewController: TalentDetailViewPresenter {

    @objc func talentDetailViewShouldClose() {
        hideTalentDetailView()
    }

}
