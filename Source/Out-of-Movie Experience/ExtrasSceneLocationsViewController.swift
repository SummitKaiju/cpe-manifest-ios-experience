//
//  ExtrasSceneLocationsViewController.swift
//

import UIKit
import MapKit
import CPEData

class ExtrasSceneLocationsViewController: ExtrasExperienceViewController, UICollectionViewDataSource {

    fileprivate struct Constants {
        static let CollectionViewItemSpacing: CGFloat = (DeviceType.IS_IPAD ? 12 : 5)
        static let CollectionViewLineSpacing: CGFloat = (DeviceType.IS_IPAD ? 12 : 15)
        static let CollectionViewPadding: CGFloat = (DeviceType.IS_IPAD ? 15 : 10)
        static let CollectionViewImageAspectRatio: CGFloat = 16 / 9
        static let CollectionViewLabelHeight: CGFloat = (DeviceType.IS_IPAD ? 35 : 30)
    }

    @IBOutlet weak private var mapView: MultiMapView!
    @IBOutlet weak private var breadcrumbsPrimaryButton: UIButton!
    @IBOutlet weak private var breadcrumbsSecondaryArrowImageView: UIImageView!
    @IBOutlet weak private var breadcrumbsSecondaryLabel: UILabel!
    @IBOutlet weak private var collectionView: UICollectionView!
    private var mapTypeDidChangeObserver: NSObjectProtocol?

    @IBOutlet weak private var locationDetailView: UIView!
    @IBOutlet weak private var videoContainerView: UIView!
    private var videoPlayerViewController: VideoPlayerViewController?
    private var videoPlayerDidToggleFullScreenObserver: NSObjectProtocol?
    private var videoPlayerDidEndVideoObserver: NSObjectProtocol?

    @IBOutlet weak private var galleryScrollView: ImageGalleryScrollView!
    @IBOutlet weak private var galleryPageControl: UIPageControl!
    @IBOutlet weak private var closeButton: UIButton?
    private var galleryDidToggleFullScreenObserver: NSObjectProtocol?
    private var galleryDidScrollToPageObserver: NSObjectProtocol?

    @IBOutlet private var containerTopConstraint: NSLayoutConstraint?
    @IBOutlet private var containerBottomConstraint: NSLayoutConstraint?
    @IBOutlet private var containerAspectRatioConstraint: NSLayoutConstraint?
    @IBOutlet private var containerBottomInnerConstraint: NSLayoutConstraint?

    private var locationExperiences = [Experience]()
    fileprivate var markers = [String: MultiMapMarker]() // ExperienceID: MultiMapMarker
    fileprivate var selectedExperience: Experience? {
        didSet {
            if let selectedExperience = selectedExperience {
                if let marker = markers[selectedExperience.id] {
                    if let location = selectedExperience.location {
                        mapView.maxZoomLevel = (location.zoomLocked ? location.zoomLevel : -1)
                        mapView.setLocation(marker.location, zoomLevel: location.zoomLevel, animated: true)
                    }

                    mapView.selectedMarker = marker
                }
            } else {
                mapView.selectedMarker = nil

                var lowestZoomLevel = Int.max
                for locationExperience in locationExperiences {
                    if let location = locationExperience.location, location.zoomLocked, location.zoomLevel < lowestZoomLevel {
                        lowestZoomLevel = location.zoomLevel
                    }
                }

                mapView.maxZoomLevel = lowestZoomLevel
                mapView.zoomToFitAllMarkers()
            }

            if selectedExperience == nil || selectedExperience!.locationMediaCount > 0 {
                reloadBreadcrumbs()
                collectionView.reloadData()
                collectionView.contentOffset = CGPoint.zero
            }
        }
    }

    private var currentGalleryAnalyticsIdentifier: String?
    private var currentVideoAnalyticsIdentifier: String?

    deinit {
        let center = NotificationCenter.default

        if let observer = mapTypeDidChangeObserver {
            center.removeObserver(observer)
            mapTypeDidChangeObserver = nil
        }

        if let observer = videoPlayerDidToggleFullScreenObserver {
            center.removeObserver(observer)
            videoPlayerDidToggleFullScreenObserver = nil
        }

        if let observer = videoPlayerDidEndVideoObserver {
            center.removeObserver(observer)
            videoPlayerDidEndVideoObserver = nil
        }

        if let observer = galleryDidToggleFullScreenObserver {
            center.removeObserver(observer)
            galleryDidToggleFullScreenObserver = nil
        }

        if let observer = galleryDidScrollToPageObserver {
            center.removeObserver(observer)
            galleryDidScrollToPageObserver = nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        galleryScrollView.cleanInvisibleImages()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let childExperiences = experience.childExperiences {
            locationExperiences = childExperiences
        }

        breadcrumbsPrimaryButton.setTitle(experience.title.uppercased(), for: .normal)
        collectionView.register(UINib(nibName: MapItemCell.NibName, bundle: Bundle.frameworkResources), forCellWithReuseIdentifier: MapItemCell.ReuseIdentifier)
        closeButton?.titleLabel?.font = UIFont.themeCondensedFont(17)
        closeButton?.setTitle(String.localize("label.close"), for: .normal)
        closeButton?.setImage(UIImage(named: "Close", in: Bundle.frameworkResources, compatibleWith: nil), for: .normal)
        closeButton?.contentEdgeInsets = UIEdgeInsets(top: 0, left: -35, bottom: 0, right: 0)
        closeButton?.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 25)
        closeButton?.imageEdgeInsets = UIEdgeInsets(top: 0, left: 110, bottom: 0, right: 0)

        breadcrumbsSecondaryArrowImageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)

        mapTypeDidChangeObserver = NotificationCenter.default.addObserver(forName: .locationsMapTypeDidChange, object: nil, queue: OperationQueue.main, using: { (notification) in
            if let mapType = notification.userInfo?[NotificationConstants.mapType] as? MultiMapType {
                Analytics.log(event: .extrasSceneLocationsAction, action: .setMapType, itemName: (mapType == .satellite ? AnalyticsLabel.satellite : AnalyticsLabel.road))
            }
        })

        videoPlayerDidToggleFullScreenObserver = NotificationCenter.default.addObserver(forName: .videoPlayerDidToggleFullScreen, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
            if let isFullScreen = notification.userInfo?[NotificationConstants.isFullScreen] as? Bool, isFullScreen {
                Analytics.log(event: .extrasSceneLocationsAction, action: .setVideoFullScreen, itemId: self?.currentVideoAnalyticsIdentifier)
            }
        })

        videoPlayerDidEndVideoObserver = NotificationCenter.default.addObserver(forName: .videoPlayerDidEndVideo, object: nil, queue: OperationQueue.main, using: { [weak self] (_) in
            self?.closeDetailView(animated: true)
        })

        galleryDidToggleFullScreenObserver = NotificationCenter.default.addObserver(forName: .imageGalleryDidToggleFullScreen, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
            if let isFullScreen = notification.userInfo?[NotificationConstants.isFullScreen] as? Bool {
                self?.closeButton?.isHidden = isFullScreen
                self?.galleryPageControl.isHidden = isFullScreen

                if isFullScreen {
                    Analytics.log(event: .extrasSceneLocationsAction, action: .setImageGalleryFullScreen, itemId: self?.currentGalleryAnalyticsIdentifier)
                }
            }
        })

        galleryDidScrollToPageObserver = NotificationCenter.default.addObserver(forName: .imageGalleryDidScrollToPage, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
            if let page = notification.userInfo?[NotificationConstants.page] as? Int {
                self?.galleryPageControl.currentPage = page
                Analytics.log(event: .extrasSceneLocationsAction, action: .selectImage, itemId: self?.currentGalleryAnalyticsIdentifier)
            }
        })

        galleryScrollView.allowsFullScreen = DeviceType.IS_IPAD

        // Set up map markers
        for locationExperience in locationExperiences {
            if let location = locationExperience.location {
                markers[locationExperience.id] = mapView.addMarker(location.centerPoint, title: location.name, subtitle: location.address, icon: location.iconImage, autoSelect: false)
            }
        }

        mapView.addControls()
        mapView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.view.layoutIfNeeded()
        selectedExperience = nil
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let toLandscape = (size.width > size.height)
        containerAspectRatioConstraint?.isActive = !toLandscape
        containerTopConstraint?.constant = (toLandscape ? 0 : ExtrasExperienceViewController.Constants.TitleImageHeight)
        containerBottomConstraint?.isActive = !toLandscape
        containerBottomInnerConstraint?.isActive = !toLandscape
        if #available(iOS 11.0, *) {
            self.setNeedsUpdateOfHomeIndicatorAutoHidden()
        }

        coordinator.animate(alongsideTransition: nil, completion: { (_) in
            self.galleryScrollView.layoutPages()
        })

        if toLandscape {
            if let galleryAnalyticsIdentifier = currentGalleryAnalyticsIdentifier {
                Analytics.log(event: .extrasSceneLocationsAction, action: .setImageGalleryFullScreen, itemId: galleryAnalyticsIdentifier)
            } else if let videoAnalyticsIdentifier = currentVideoAnalyticsIdentifier {
                Analytics.log(event: .extrasSceneLocationsAction, action: .setVideoFullScreen, itemId: videoAnalyticsIdentifier)
            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if DeviceType.IS_IPAD || (currentGalleryAnalyticsIdentifier == nil && currentVideoAnalyticsIdentifier == nil) {
            return super.supportedInterfaceOrientations
        }

        return .all
    }
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return (containerBottomConstraint != nil && !containerBottomConstraint!.isActive)
    }

    private func playVideo(fromExperience experience: Experience) {
        if let videoURL = experience.video?.url {
            let shouldAnimateOpen = locationDetailView.isHidden
            closeDetailView(animated: false)

            if let videoPlayerViewController = UIStoryboard.viewController(for: VideoPlayerViewController.self) as? VideoPlayerViewController {
                videoPlayerViewController.mode = VideoPlayerMode.supplemental

                videoPlayerViewController.view.frame = videoContainerView.bounds
                videoContainerView.addSubview(videoPlayerViewController.view)
                self.addChildViewController(videoPlayerViewController)
                videoPlayerViewController.didMove(toParentViewController: self)

                if !DeviceType.IS_IPAD && videoPlayerViewController.fullScreenButton != nil {
                    videoPlayerViewController.fullScreenButton?.removeFromSuperview()
                }

                self.videoPlayerViewController = videoPlayerViewController

                locationDetailView.alpha = 0
                locationDetailView.isHidden = false

                if shouldAnimateOpen {
                    UIView.animate(withDuration: 0.25, animations: {
                        self.locationDetailView.alpha = 1
                    }, completion: { (_) in
                        self.videoPlayerViewController?.playAsset(withURL: videoURL, title: experience.title, imageURL: experience.thumbnailImageURL)
                    })
                } else {
                    locationDetailView.alpha = 1
                    self.videoPlayerViewController?.playAsset(withURL: videoURL, title: experience.title, imageURL: experience.thumbnailImageURL)
                }
            }
        }
    }

    func showGallery(_ gallery: Gallery) {
        let shouldAnimateOpen = locationDetailView.isHidden
        closeDetailView(animated: false)

        galleryScrollView.load(with: gallery)
        galleryScrollView.isHidden = false

        if gallery.isTurntable {
            galleryPageControl.isHidden = true
        } else {
            galleryPageControl.isHidden = false
            galleryPageControl.numberOfPages = gallery.numPictures
            galleryPageControl.currentPage = 0
        }

        locationDetailView.alpha = 0
        locationDetailView.isHidden = false

        if shouldAnimateOpen {
            UIView.animate(withDuration: 0.25, animations: {
                self.locationDetailView.alpha = 1
            })
        } else {
            locationDetailView.alpha = 1
        }
    }

    @IBAction func closeDetailView() {
        closeDetailView(animated: true)
    }

    private func closeDetailView(animated: Bool) {
        let hideViews = {
            self.locationDetailView.isHidden = true

            self.galleryScrollView.load(with: nil)
            self.galleryScrollView.isHidden = true
            self.galleryPageControl.isHidden = true

            self.videoPlayerViewController?.willMove(toParentViewController: nil)
            self.videoPlayerViewController?.view.removeFromSuperview()
            self.videoPlayerViewController?.removeFromParentViewController()
            self.videoPlayerViewController = nil
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.locationDetailView.alpha = 0
            }, completion: { (_) in
                hideViews()
            })
        } else {
            hideViews()
        }
    }

    func reloadBreadcrumbs() {
        breadcrumbsPrimaryButton.isUserInteractionEnabled = false
        breadcrumbsSecondaryArrowImageView.isHidden = true
        breadcrumbsSecondaryLabel.isHidden = true

        if let selectedExperience = selectedExperience, selectedExperience.locationMediaCount > 0 {
            breadcrumbsSecondaryLabel.text = selectedExperience.title.uppercased()
            breadcrumbsSecondaryLabel.sizeToFit()
            breadcrumbsSecondaryLabel.frame.size.height = breadcrumbsPrimaryButton.frame.height
            breadcrumbsSecondaryArrowImageView.isHidden = false
            breadcrumbsSecondaryLabel.isHidden = false
            breadcrumbsPrimaryButton.isUserInteractionEnabled = true
        }
    }

    // MARK: Actions
    override func close() {
        if !locationDetailView.isHidden && !DeviceType.IS_IPAD {
            closeDetailView()
        } else {
            mapView.destroy()
            mapView = nil
            super.close()
        }
    }

    @IBAction func onTapBreadcrumb(_ sender: UIButton) {
        closeDetailView(animated: false)
        selectedExperience = nil
        currentVideoAnalyticsIdentifier = nil
        currentGalleryAnalyticsIdentifier = nil
    }

    @IBAction func onPageControlValueChanged() {
        galleryScrollView.gotoPage(galleryPageControl.currentPage, animated: true)
    }

    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let selectedExperience = selectedExperience, selectedExperience.locationMediaCount > 0 {
            return selectedExperience.locationMediaCount
        }

        return locationExperiences.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: MapItemCell.ReuseIdentifier, for: indexPath)
        guard let cell = collectionViewCell as? MapItemCell else {
            return collectionViewCell
        }

        cell.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        if let selectedExperience = selectedExperience, selectedExperience.locationMediaCount > 0 {
            if let experience = selectedExperience.locationMediaAtIndex(indexPath.row) {
                cell.playButtonVisible = experience.isType(.audioVisual)
                cell.imageURL = experience.thumbnailImageURL
                cell.title = experience.title
            }
        } else {
            let experience = locationExperiences[indexPath.row]
            cell.playButtonVisible = false
            cell.imageURL = experience.thumbnailImageURL
            cell.title = experience.title
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentVideoAnalyticsIdentifier = nil
        currentGalleryAnalyticsIdentifier = nil

        if let selectedExperience = selectedExperience, selectedExperience.locationMediaCount > 0 {
            if let experience = selectedExperience.locationMediaAtIndex(indexPath.row) {
                if let video = experience.video {
                    playVideo(fromExperience: experience)
                    currentVideoAnalyticsIdentifier = video.analyticsID
                    Analytics.log(event: .extrasSceneLocationsAction, action: .selectVideo, itemId: currentVideoAnalyticsIdentifier)
                } else if let gallery = experience.gallery {
                    showGallery(gallery)
                    currentGalleryAnalyticsIdentifier = gallery.analyticsID
                    Analytics.log(event: .extrasSceneLocationsAction, action: .selectImageGallery, itemId: currentGalleryAnalyticsIdentifier)
                }
            }
        } else {
            selectedExperience = locationExperiences[indexPath.row]
            Analytics.log(event: .extrasSceneLocationsAction, action: .selectLocationThumbnail, itemId: selectedExperience?.analyticsID)
        }
    }

}

extension ExtrasSceneLocationsViewController: MultiMapViewDelegate {

    func mapView(_ mapView: MultiMapView, didTapMarker marker: MultiMapMarker) {
        for (experienceID, locationMarker) in markers {
            if marker == locationMarker {
                selectedExperience = CPEXMLSuite.current!.manifest.experienceWithID(experienceID)
                Analytics.log(event: .extrasSceneLocationsAction, action: .selectLocationMarker, itemId: experienceID)
                return
            }
        }
    }

}

extension ExtrasSceneLocationsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if DeviceType.IS_IPAD {
            let itemHeight = collectionView.frame.height
            return CGSize(width: (itemHeight - Constants.CollectionViewLabelHeight) * Constants.CollectionViewImageAspectRatio, height: itemHeight)
        }

        let itemWidth = (collectionView.frame.width - (Constants.CollectionViewPadding * 2) - Constants.CollectionViewItemSpacing) / 2
        return CGSize(width: itemWidth, height: (itemWidth / Constants.CollectionViewImageAspectRatio) + Constants.CollectionViewLabelHeight)
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
