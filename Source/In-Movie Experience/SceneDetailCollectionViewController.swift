//
//  SceneDetailCollectionViewController.swift
//

import UIKit
import MapKit
import CPEData

struct ExperienceCellData {
    var experience: Experience
    var timedEvent: TimedEvent

    init(experience: Experience, timedEvent: TimedEvent) {
        self.experience = experience
        self.timedEvent = timedEvent
    }
}

class SceneDetailCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    private struct SegueIdentifier {
        static let ShowGallery = "ShowGallerySegueIdentifier"
        static let ShowShopping = "ShowShoppingSegueIdentifier"
        static let ShowMap = "ShowMapSegueIdentifier"
        static let ShowClipShare = "ShowClipShareSegueIdentifier"
        static let ShowLargeText = "ShowLargeTextSegueIdentifier"
    }

    private struct Constants {
        static let ItemsPerRow: CGFloat = (DeviceType.IS_IPAD ? 2 : 1)
        static let ItemSpacing: CGFloat = 10
        static let LineSpacing: CGFloat = 10
        static let ItemImageAspectRatio: CGFloat = 16 / 9
        static let ItemTitleHeight: CGFloat = 35
        static let ItemCaptionHeight: CGFloat = (DeviceType.IS_IPAD ? 25 : 30)
    }

    private var didChangeTimeObserver: NSObjectProtocol!

    private var _currentTime: Double = -1
    private var _currentTimedEvents = [TimedEvent]()
    private var _isProcessingTimedEvents = false

    deinit {
        let center = NotificationCenter.default
        center.removeObserver(didChangeTimeObserver)
        didChangeTimeObserver = nil
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.backgroundColor = UIColor.clear
        self.collectionView?.alpha = 0
        self.collectionView?.register(UINib(nibName: TextSceneDetailCollectionViewCell.NibName, bundle: Bundle.frameworkResources), forCellWithReuseIdentifier: TextSceneDetailCollectionViewCell.ReuseIdentifier)
        self.collectionView?.register(UINib(nibName: ImageSceneDetailCollectionViewCell.NibName, bundle: Bundle.frameworkResources), forCellWithReuseIdentifier: ImageSceneDetailCollectionViewCell.ReuseIdentifier)
        self.collectionView?.register(UINib(nibName: ImageSceneDetailCollectionViewCell.NibNameClipShare, bundle:Bundle.frameworkResources), forCellWithReuseIdentifier: ImageSceneDetailCollectionViewCell.ClipShareReuseIdentifier)
        self.collectionView?.register(UINib(nibName: MapSceneDetailCollectionViewCell.NibName, bundle: Bundle.frameworkResources), forCellWithReuseIdentifier: MapSceneDetailCollectionViewCell.ReuseIdentifier)
        self.collectionView?.register(UINib(nibName: ShoppingSceneDetailCollectionViewCell.NibName, bundle: Bundle.frameworkResources), forCellWithReuseIdentifier: ShoppingSceneDetailCollectionViewCell.ReuseIdentifier)

        didChangeTimeObserver = NotificationCenter.default.addObserver(forName: .videoPlayerDidChangeTime, object: nil, queue: nil) { [weak self] (notification) -> Void in
            if let strongSelf = self, let time = notification.userInfo?[NotificationConstants.time] as? Double {
                if time != strongSelf._currentTime && !strongSelf._isProcessingTimedEvents {
                    strongSelf._isProcessingTimedEvents = true
                    strongSelf.processTimedEvents(time)
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.collectionView?.alpha = 1
        self.collectionViewLayout.invalidateLayout()
    }

    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.collectionViewLayout.invalidateLayout()
    }

    func processTimedEvents(_ time: Double) {
        DispatchQueue.global(qos: .userInitiated).async {
            self._currentTime = time

            var deleteIndexPaths: [IndexPath]?
            var insertIndexPaths: [IndexPath]?
            var reloadIndexPaths: [IndexPath]?

            var newTimedEvents = [TimedEvent]()
            if let timedEvents = CPEXMLSuite.current!.manifest.timedEvents(atTimecode: time) {
                for timedEvent in timedEvents {
                    if !timedEvent.isType(.person) {
                        let indexPath = IndexPath(item: newTimedEvents.count, section: 0)

                        if newTimedEvents.count < self._currentTimedEvents.count {
                            if self._currentTimedEvents[newTimedEvents.count] != timedEvent {
                                if reloadIndexPaths == nil {
                                    reloadIndexPaths = [IndexPath]()
                                }

                                reloadIndexPaths!.append(indexPath)
                            } else if timedEvent.isType(.product), let cell = self.collectionView?.cellForItem(at: indexPath) as? ShoppingSceneDetailCollectionViewCell {
                                cell.currentTime = self._currentTime
                            }
                        } else {
                            if insertIndexPaths == nil {
                                insertIndexPaths = [IndexPath]()
                            }

                            insertIndexPaths!.append(indexPath)
                        }

                        newTimedEvents.append(timedEvent)
                    }
                }
            }

            if self._currentTimedEvents.count > newTimedEvents.count {
                for i in newTimedEvents.count ..< self._currentTimedEvents.count {
                    if deleteIndexPaths == nil {
                        deleteIndexPaths = [IndexPath]()
                    }

                    deleteIndexPaths!.append(IndexPath(item: i, section: 0))
                }
            }

            DispatchQueue.main.async {
                self._currentTimedEvents = newTimedEvents

                self.collectionView?.performBatchUpdates({
                    if let deleteIndexPaths = deleteIndexPaths, deleteIndexPaths.count > 0 {
                        self.collectionView?.deleteItems(at: deleteIndexPaths)
                    }

                    if let insertIndexPaths = insertIndexPaths, insertIndexPaths.count > 0 {
                        self.collectionView?.insertItems(at: insertIndexPaths)
                    }

                    if let reloadIndexPaths = reloadIndexPaths, reloadIndexPaths.count > 0 {
                        self.collectionView?.reloadItems(at: reloadIndexPaths)
                    }
                }, completion: { (_) in
                    self._isProcessingTimedEvents = false
                })
            }
        }
    }

    // MARK: UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _currentTimedEvents.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let timedEvent = _currentTimedEvents[indexPath.row]

        var reuseIdentifier: String
        if timedEvent.isType(.location) {
            reuseIdentifier = MapSceneDetailCollectionViewCell.ReuseIdentifier
        } else if timedEvent.isType(.product) {
            reuseIdentifier = ShoppingSceneDetailCollectionViewCell.ReuseIdentifier
        } else if timedEvent.isType(.clipShare) {
            reuseIdentifier = ImageSceneDetailCollectionViewCell.ClipShareReuseIdentifier
        } else if timedEvent.thumbnailImageURL != nil {
            reuseIdentifier = ImageSceneDetailCollectionViewCell.ReuseIdentifier
        } else {
            reuseIdentifier = TextSceneDetailCollectionViewCell.ReuseIdentifier
        }

        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let cell = collectionViewCell as? SceneDetailCollectionViewCell else {
            return collectionViewCell
        }

        cell.timedEvent = timedEvent
        cell.currentTime = _currentTime
        return cell
    }

    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth: CGFloat = (collectionView.frame.width / Constants.ItemsPerRow) - (Constants.ItemSpacing / Constants.ItemsPerRow)
        let itemHeight = (itemWidth / Constants.ItemImageAspectRatio) + Constants.ItemTitleHeight + Constants.ItemCaptionHeight
        return CGSize(width: itemWidth, height: itemHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.LineSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.ItemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: Constants.LineSpacing, right: 0)
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? SceneDetailCollectionViewCell, let timedEvent = cell.timedEvent {
            if timedEvent.isType(.appGroup) {
                if let experienceApp = timedEvent.experience?.app, let webViewController = WebViewController(experienceApp: experienceApp) {
                    NotificationCenter.default.post(name: .videoPlayerShouldPause, object: nil)
                    self.present(webViewController, animated: true, completion: nil)
                    Analytics.log(event: .imeExtrasAction, action: .selectApp, itemId: experienceApp.analyticsID)
                }
            } else {
                var segueIdentifier: String?
                if timedEvent.isType(.clipShare) {
                    segueIdentifier = SegueIdentifier.ShowClipShare
                    Analytics.log(event: .imeExtrasAction, action: .selectClipShare, itemId: timedEvent.analyticsID)
                } else if timedEvent.isType(.video) {
                    segueIdentifier = SegueIdentifier.ShowGallery
                    Analytics.log(event: .imeExtrasAction, action: .selectVideo, itemId: timedEvent.analyticsID)
                } else if timedEvent.isType(.gallery) {
                    segueIdentifier = SegueIdentifier.ShowGallery
                    Analytics.log(event: .imeExtrasAction, action: .selectImageGallery, itemId: timedEvent.analyticsID)
                } else if timedEvent.isType(.location) {
                    segueIdentifier = SegueIdentifier.ShowMap
                    Analytics.log(event: .imeExtrasAction, action: .selectLocation, itemId: timedEvent.analyticsID)
                } else if timedEvent.isType(.product) {
                    segueIdentifier = SegueIdentifier.ShowShopping
                    Analytics.log(event: .imeExtrasAction, action: .selectShopping, itemId: timedEvent.analyticsID)
                } else if timedEvent.isType(.textItem) {
                    segueIdentifier = SegueIdentifier.ShowLargeText
                    Analytics.log(event: .imeExtrasAction, action: .selectTrivia, itemId: timedEvent.analyticsID)
                }

                if let identifier = segueIdentifier {
                    self.performSegue(withIdentifier: identifier, sender: cell)
                }
            }
        }

    }

    // MARK: Storyboard Methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? SceneDetailCollectionViewCell, let timedEvent = cell.timedEvent {
            if segue.identifier == SegueIdentifier.ShowShopping {
                if let products = (cell as? ShoppingSceneDetailCollectionViewCell)?.products, let shopDetailViewController = segue.destination as? ShoppingDetailViewController {
                    shopDetailViewController.mode = .ime
                    shopDetailViewController.products = products
                }
            } else if let sceneDetailViewController = segue.destination as? SceneDetailViewController {
                sceneDetailViewController.timedEvent = timedEvent
            }
        }
    }

}
