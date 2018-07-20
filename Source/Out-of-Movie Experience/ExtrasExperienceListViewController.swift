//
//  ExtrasViewController.swift
//

import UIKit
import CPEData

import AetherPlayer

class ExtrasExperienceListViewController: ExtrasExperienceViewController {

    fileprivate struct Constants {
        static let CollectionViewItemSpacing: CGFloat = (DeviceType.IS_IPAD ? 12 : 5)
        static let CollectionViewLineSpacing: CGFloat = (DeviceType.IS_IPAD ? 12 : 25)
        static let CollectionViewPadding: CGFloat = (DeviceType.IS_IPAD ? 15 : 10)
        static let CollectionViewItemAspectRatio: CGFloat = 318 / 224
    }

    private struct SegueIdentifier {
        static let ShowTalent = "ShowTalentSegueIdentifier"
        static let ShowGallery = "ExtrasGallerySegue"
        static let ShowMap = "ExtrasMapSegue"
        static let ShowShopping = "ExtrasShoppingSegue"
        static let ShowList = "ExtrasListSegue"
    }

    @IBOutlet var extrasCollectionView: UICollectionView!

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        extrasCollectionView.register(UINib(nibName: TitledImageCell.NibName, bundle: Bundle.frameworkResources), forCellWithReuseIdentifier: TitledImageCell.ReuseIdentifier)

        showBackButton()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        extrasCollectionView.collectionViewLayout.invalidateLayout()
    }

    fileprivate func launchExperience(_ experience: Experience) {
        if experience.isType(.product) {
            self.performSegue(withIdentifier: SegueIdentifier.ShowShopping, sender: experience)
            Analytics.log(event: .extrasAction, action: .selectShopping)
        } else if experience.isType(.location) {
            self.performSegue(withIdentifier: SegueIdentifier.ShowMap, sender: experience)
            Analytics.log(event: .extrasAction, action: .selectSceneLocations)
        } else if experience.isType(.app) {
            if let app = experience.app, let url = app.url {
                if app.appGroup?.interactiveTrackReferences.first?.interactives.first?.encodings.first?.runtimeEnvironment == InteractiveRuntimeEnvironment.ath {
                    let content = AetherContentManager.shared.get(imfURL: url)
                    let playerViewController = ATHPlayerViewController(content: content)
                    playerViewController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve;
                    playerViewController.modalPresentationStyle = UIModalPresentationStyle.fullScreen;
                    self.present(playerViewController, animated: true, completion: nil)
                    Analytics.log(event: .extrasAction, action: .selectApp, itemId: app.analyticsID)
                } else {
                    let webViewController = WebViewController(url: url, title: app.title)
                    let navigationController = CPENavigationController(rootViewController: webViewController)
                    navigationController.supportsPortrait = app.supportsPortrait
                    navigationController.supportsLandscape = app.supportsLandscape
                    self.present(navigationController, animated: true, completion: nil)
                    Analytics.log(event: .extrasAction, action: .selectApp, itemId: app.analyticsID)
                }
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

    // MARK: Storyboard
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? ExtrasExperienceViewController, let experience = sender as? Experience {
            viewController.experience = experience
        }
    }

}

extension ExtrasExperienceListViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return experience.numChildExperiences
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: TitledImageCell.ReuseIdentifier, for: indexPath)
        guard let cell = collectionViewCell as? TitledImageCell else {
            return collectionViewCell
        }

        cell.experience = experience.childExperience(atIndex: indexPath.row)
        return cell
    }

}

extension ExtrasExperienceListViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let experience = experience.childExperience(atIndex: indexPath.row) {
            launchExperience(experience)
        }
    }

}

extension ExtrasExperienceListViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let containerWidth = collectionView.frame.width - (Constants.CollectionViewPadding * 2)
        var itemWidth: CGFloat = 0
        if DeviceType.IS_IPAD {
            itemWidth = (containerWidth / 3) - (Constants.CollectionViewItemSpacing * 2)
        } else {
            itemWidth = (containerWidth / 2) - Constants.CollectionViewItemSpacing
        }

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
