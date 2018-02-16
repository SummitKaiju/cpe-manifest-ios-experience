//
//  ExtrasViewController.swift
//

import UIKit
import CPEData

class ExtrasViewController: ExtrasExperienceViewController {

    fileprivate struct Constants {
        static let CollectionViewItemSpacing: CGFloat = (DeviceType.IS_IPAD ? 12 : 5)
        static let CollectionViewLineSpacing: CGFloat = (DeviceType.IS_IPAD ? 12 : 25)
        static let CollectionViewPadding: CGFloat = (DeviceType.IS_IPAD ? 15 : 10)
        static let CollectionViewItemAspectRatio: CGFloat = 318 / 224
        static let TableViewHeaderHeight: CGFloat = 35
        static let SegmentedControlPadding: CGFloat = (DeviceType.IS_IPAD ? 10 : 5)
        static let SegmentedControlFontSize: CGFloat = (DeviceType.IS_IPAD ? 10 : 9)
        static let SegmentedControlHeight: CGFloat = 30
    }

    fileprivate struct SegueIdentifier {
        static let ShowTalent = "ShowTalentSegueIdentifier"
        static let ShowGallery = "ExtrasGallerySegue"
        static let ShowList = "ExtrasListSegue"
        static let ShowMap = "ExtrasMapSegue"
        static let ShowShopping = "ExtrasShoppingSegue"
        static let ShowTalentSelector = "TalentSelectorSegueIdentifier"
    }

    @IBOutlet weak private var talentTableView: UITableView?
    @IBOutlet weak private var talentDetailView: UIView?
    @IBOutlet private var extrasCollectionView: UICollectionView!

    fileprivate var personSegmentedControl: UISegmentedControl?
    fileprivate var talentTableHeaderView: UIView?
    private var talentDetailViewController: TalentDetailViewController?
    fileprivate var currentPersonJobFunction = PersonJobFunction.actor
    fileprivate var selectedIndexPath: IndexPath?

    fileprivate var showPeopleInGrid: Bool {
        return (!DeviceType.IS_IPAD && CPEDataUtils.numPersonJobFunctions > 0)
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        experience = CPEXMLSuite.current!.manifest.outOfMovieExperience

        if let talentTableView = talentTableView, CPEDataUtils.people != nil {
            talentTableView.register(UINib(nibName: TalentTableViewCell.NibNameWide, bundle: Bundle.frameworkResources), forCellReuseIdentifier: TalentTableViewCell.ReuseIdentifier)
            talentTableView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)
        } else {
            talentTableView?.removeFromSuperview()
            talentTableView = nil
        }

        extrasCollectionView.register(UINib(nibName: TitledImageCell.NibName, bundle: Bundle.frameworkResources), forCellWithReuseIdentifier: TitledImageCell.ReuseIdentifier)

        showHomeButton()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        extrasCollectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: Actions
    override func close() {
        if talentDetailView != nil && !talentDetailView!.isHidden {
            hideTalentDetailView()
        } else {
            super.close()
        }
    }

    // MARK: Talent Details
    fileprivate func showTalentDetailView() {
        if selectedIndexPath != nil, let talent = (talentTableView?.cellForRow(at: selectedIndexPath!) as? TalentTableViewCell)?.talent, let talentDetailView = talentDetailView, let talentDetailViewController = UIStoryboard.viewController(for: TalentDetailViewController.self) as? TalentDetailViewController {
            talentDetailViewController.talent = talent

            talentDetailViewController.view.frame = talentDetailView.bounds
            talentDetailView.addSubview(talentDetailViewController.view)
            self.addChildViewController(talentDetailViewController)
            talentDetailViewController.didMove(toParentViewController: self)

            showBackButton()

            if talentDetailView.isHidden {
                talentDetailView.alpha = 0
                talentDetailView.isHidden = false

                UIView.animate(withDuration: 0.25, animations: {
                    talentDetailView.alpha = 1
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

                self.talentDetailViewController?.willMove(toParentViewController: nil)
                self.talentDetailViewController?.view.removeFromSuperview()
                self.talentDetailViewController?.removeFromParentViewController()
                self.talentDetailViewController = nil
                completed?()
            })
        } else {
            completed?()
        }
    }
    
    @objc fileprivate func onSelectPersonJobFunction() {
        if let index = personSegmentedControl?.selectedSegmentIndex, let jobFunctions = CPEDataUtils.personJobFunctions, jobFunctions.count > index {
            currentPersonJobFunction = Array(jobFunctions)[index]
            hideTalentDetailView()
            talentTableView?.reloadData()
        }
    }

    // MARK: Storyboard
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.ShowTalentSelector, let viewController = segue.destination as? ExtrasTalentSelectorViewController, let personJobFunction = sender as? PersonJobFunction {
            viewController.personJobFunction = personJobFunction
            viewController.experience = CPEXMLSuite.current!.manifest.mainExperience
        } else if let viewController = segue.destination as? ExtrasExperienceViewController, let experience = sender as? Experience {
            viewController.experience = experience
        }
    }

}

extension ExtrasViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (CPEDataUtils.people?[currentPersonJobFunction]?.count ?? 0)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if CPEDataUtils.numPersonJobFunctions > 1 && talentTableHeaderView == nil {
            personSegmentedControl = UISegmentedControl(items: CPEDataUtils.personJobFunctions?.map({ CPEDataUtils.titleForPeople(with: $0).uppercased() }))
            personSegmentedControl?.frame = CGRect(x: Constants.SegmentedControlPadding, y: 0, width: tableView.frame.width - (Constants.SegmentedControlPadding * 2), height: Constants.SegmentedControlHeight)
            personSegmentedControl?.tintColor = UIColor(netHex: 0xd61414)
            personSegmentedControl?.setTitleTextAttributes([
                NSFontAttributeName: UIFont.systemFont(ofSize: Constants.SegmentedControlFontSize),
                NSForegroundColorAttributeName: UIColor.white
                ], for: .normal)
            personSegmentedControl?.setTitleTextAttributes([
                NSForegroundColorAttributeName: UIColor.white
                ], for: .selected)
            personSegmentedControl?.selectedSegmentIndex = 0
            personSegmentedControl?.addTarget(self, action: #selector(onSelectPersonJobFunction), for: .valueChanged)
            
            talentTableHeaderView = UIView()
            talentTableHeaderView?.addSubview(personSegmentedControl!)
        }
        
        return talentTableHeaderView
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (CPEDataUtils.numPersonJobFunctions > 1 ? Constants.TableViewHeaderHeight : 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: TalentTableViewCell.ReuseIdentifier, for: indexPath)
        guard let cell = tableViewCell as? TalentTableViewCell else {
            return tableViewCell
        }

        if let people = CPEDataUtils.people?[currentPersonJobFunction], people.count > indexPath.row {
            cell.talent = people[indexPath.row]
        }

        return cell
    }

}

extension ExtrasViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath == selectedIndexPath {
            hideTalentDetailView()
            return nil
        }

        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        hideTalentDetailView { [weak self] in
            self?.selectedIndexPath = indexPath
            self?.showTalentDetailView()
        }
    }

}

extension ExtrasViewController: TalentDetailViewPresenter {

    func talentDetailViewShouldClose() {
        hideTalentDetailView()
    }

}

extension ExtrasViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (showPeopleInGrid ? (experience.numChildExperiences + CPEDataUtils.numPersonJobFunctions) : experience.numChildExperiences)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: TitledImageCell.ReuseIdentifier, for: indexPath)
        guard let cell = collectionViewCell as? TitledImageCell else {
            return collectionViewCell
        }

        var childExperienceIndex = indexPath.row
        if showPeopleInGrid {
            if childExperienceIndex < CPEDataUtils.numPersonJobFunctions {
                let jobFunction = CPEDataUtils.personJobFunctions![childExperienceIndex]
                cell.experience = nil
                cell.title = CPEDataUtils.titleForPeople(with: jobFunction)
                cell.imageURL = CPEDataUtils.people?[jobFunction]?.first?.thumbnailImageURL
                cell.imageView.contentMode = .scaleAspectFit
                return cell
            }

            childExperienceIndex -= CPEDataUtils.numPersonJobFunctions
        }

        cell.experience = experience.childExperience(atIndex: childExperienceIndex)

        return cell
    }

}

extension ExtrasViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var childExperienceIndex = indexPath.row
        if showPeopleInGrid {
            if childExperienceIndex < CPEDataUtils.numPersonJobFunctions {
                self.performSegue(withIdentifier: SegueIdentifier.ShowTalentSelector, sender: CPEDataUtils.personJobFunctions?[childExperienceIndex])
                return
            }

            childExperienceIndex -= CPEDataUtils.numPersonJobFunctions
        }

        if let experience = experience.childExperience(atIndex: childExperienceIndex) {
            launchExperience(experience)
        }
    }

    private func launchExperience(_ experience: Experience) {
        if experience.isType(.product) {
            self.performSegue(withIdentifier: SegueIdentifier.ShowShopping, sender: experience)
            Analytics.log(event: .extrasAction, action: .selectShopping)
        } else if experience.isType(.location) {
            self.performSegue(withIdentifier: SegueIdentifier.ShowMap, sender: experience)
            Analytics.log(event: .extrasAction, action: .selectSceneLocations)
        } else if experience.isType(.app) {
            if let app = experience.app, let url = app.url {
                let webViewController = WebViewController(url: url, title: app.title)
                let navigationController = CPENavigationController(rootViewController: webViewController)
                navigationController.supportsPortrait = app.supportsPortrait
                navigationController.supportsLandscape = app.supportsLandscape
                self.present(navigationController, animated: true, completion: nil)
                Analytics.log(event: .extrasAction, action: .selectApp, itemId: app.analyticsID)
            }
        } else {
            if let firstChildExperience = experience.childExperience(atIndex: 0) {
                if firstChildExperience.isType(.audioVisual) {
                    self.performSegue(withIdentifier: SegueIdentifier.ShowGallery, sender: experience)
                    Analytics.log(event: .extrasAction, action: .selectVideoGallery, itemId: experience.analyticsID)
                } else if firstChildExperience.isType(.gallery) {
                    self.performSegue(withIdentifier: SegueIdentifier.ShowGallery, sender: experience)
                    Analytics.log(event: .extrasAction, action: .selectImageGalleries, itemId: experience.analyticsID)
                } else if experience.numChildExperiences > 1 {
                    self.performSegue(withIdentifier: SegueIdentifier.ShowList, sender: experience)
                    Analytics.log(event: .extrasAction, action: .selectExperienceList, itemId: experience.analyticsID)
                } else {
                    launchExperience(firstChildExperience)
                }
            }
        }
    }

}

extension ExtrasViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let containerWidth = collectionView.frame.width - (Constants.CollectionViewPadding * 2)
        let itemWidth: CGFloat = (containerWidth / 2) - Constants.CollectionViewItemSpacing
        return CGSize(width: itemWidth, height: itemWidth / Constants.CollectionViewItemAspectRatio)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.CollectionViewLineSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.CollectionViewItemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: Constants.CollectionViewPadding, left: Constants.CollectionViewPadding, bottom: Constants.CollectionViewPadding, right: Constants.CollectionViewPadding)
    }

}
