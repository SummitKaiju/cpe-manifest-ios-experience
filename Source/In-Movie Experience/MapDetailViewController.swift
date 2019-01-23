//
//  MapDetailViewController.swift
//

import UIKit
import MapKit
import CPEData

class MapDetailViewController: SceneDetailViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak private var mapView: MultiMapView!
    @IBOutlet private var mapContainerAspectRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak private var mediaCollectionView: UICollectionView?
    @IBOutlet weak private var descriptionLabel: UILabel?

    @IBOutlet weak var locationDetailView: UIView!
    @IBOutlet weak var videoContainerView: UIView!
    private var videoPlayerViewController: VideoPlayerViewController?

    @IBOutlet weak var galleryScrollView: ImageGalleryScrollView!

    private var mapTypeDidChangeObserver: NSObjectProtocol?

    private var marker: MultiMapMarker!
    private var location: AppDataItemLocation {
        return timedEvent!.location!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        galleryScrollView.cleanInvisibleImages()
    }

    deinit {
        let center = NotificationCenter.default

        if let observer = mapTypeDidChangeObserver {
            center.removeObserver(observer)
            mapTypeDidChangeObserver = nil
        }

        mapView.destroy()
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if location.mediaCount > 0 {
            mediaCollectionView?.register(UINib(nibName: SimpleMapCollectionViewCell.NibName, bundle: Bundle.frameworkResources), forCellWithReuseIdentifier: SimpleMapCollectionViewCell.ReuseIdentifier)
            mediaCollectionView?.register(UINib(nibName: SimpleImageCollectionViewCell.NibName, bundle: Bundle.frameworkResources), forCellWithReuseIdentifier: SimpleImageCollectionViewCell.BaseReuseIdentifier)
        } else {
            mediaCollectionView?.removeFromSuperview()
            mapContainerAspectRatioConstraint.isActive = false
        }

        if let text = location.description {
            descriptionLabel?.text = text
            descriptionLabel?.isHidden = false
        } else {
            descriptionLabel?.removeFromSuperview()
        }

        mapView.delegate = self

        mapTypeDidChangeObserver = NotificationCenter.default.addObserver(forName: .locationsMapTypeDidChange, object: nil, queue: OperationQueue.main, using: { (notification) in
            if let mapType = notification.userInfo?[NotificationConstants.mapType] as? MultiMapType {
                Analytics.log(event: .imeLocationAction, action: .setMapType, itemName: (mapType == .satellite ? AnalyticsLabel.satellite : AnalyticsLabel.road))
            }
        })

        galleryScrollView.allowsFullScreen = false
        galleryScrollView.removeToolbar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        mapView.setLocation(location.centerPoint, zoomLevel: location.zoomLevel, animated: false)
        marker = mapView.addMarker(location.centerPoint, title: location.name, subtitle: location.address, icon: location.iconImage, autoSelect: true)
        mapView.addControls()
        mapView.maxZoomLevel = (location.zoomLocked ? location.zoomLevel : -1)
    }

    fileprivate func animateToCenter() {
        mapView.setLocation(location.centerPoint, zoomLevel: location.zoomLevel, animated: true)
        mapView.selectedMarker = marker
    }

    // MARK: Actions
    private func playVideo(_ videoURL: URL) {
        closeDetailView()

        if let videoPlayerViewController = UIStoryboard.viewController(for: VideoPlayerViewController.self) as? VideoPlayerViewController {
            videoPlayerViewController.mode = VideoPlayerMode.supplementalInMovie

            videoPlayerViewController.view.frame = videoContainerView.bounds
            videoContainerView.addSubview(videoPlayerViewController.view)
            self.addChild(videoPlayerViewController)
            videoPlayerViewController.didMove(toParent: self)

            videoPlayerViewController.playAsset(withURL: videoURL)

            locationDetailView.isHidden = false
            self.videoPlayerViewController = videoPlayerViewController
        }
    }

    private func showGallery(_ gallery: Gallery) {
        closeDetailView()

        galleryScrollView.load(with: gallery)
        galleryScrollView.isHidden = false

        locationDetailView.isHidden = false
    }

    private func closeDetailView() {
        locationDetailView.isHidden = true

        galleryScrollView.load(with: nil)
        galleryScrollView.isHidden = true

        videoPlayerViewController?.willMove(toParent: nil)
        videoPlayerViewController?.view.removeFromSuperview()
        videoPlayerViewController?.removeFromParent()
        videoPlayerViewController = nil
    }

    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return location.mediaCount > 0 ? (location.mediaCount + 1) : 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 && location.mapImageURL == nil {
            let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: SimpleMapCollectionViewCell.ReuseIdentifier, for: indexPath)
            guard let cell = collectionViewCell as? SimpleMapCollectionViewCell else {
                return collectionViewCell
            }

            cell.setLocation(location.centerPoint, zoomLevel: location.zoomLevel - 4)
            return cell
        }

        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: SimpleImageCollectionViewCell.BaseReuseIdentifier, for: indexPath)
        guard let cell = collectionViewCell as? SimpleImageCollectionViewCell else {
            return collectionViewCell
        }

        if indexPath.row == 0 {
            cell.playButtonVisible = false
            cell.imageURL = location.mapImageURL
        } else if let experience = location.mediaAtIndex(indexPath.row - 1) {
            cell.playButtonVisible = experience.isType(.audioVisual)
            cell.imageURL = experience.thumbnailImageURL
        } else {
            cell.playButtonVisible = false
            cell.imageURL = nil
        }

        return cell
    }

    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            closeDetailView()
            animateToCenter()
            Analytics.log(event: .imeLocationAction, action: .selectMap, itemId: location.analyticsID)
        } else if let experience = location.mediaAtIndex(indexPath.row - 1) {
            if let video = experience.video, let videoURL = video.url {
                playVideo(videoURL)
                Analytics.log(event: .imeLocationAction, action: .selectVideo, itemId: video.analyticsID)
            } else if let gallery = experience.gallery {
                showGallery(gallery)
                Analytics.log(event: .imeLocationAction, action: .selectImageGallery, itemId: gallery.analyticsID)
            }
        }
    }

    // MARK: UICollectionViewDelegateFlowLayout
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.width / (DeviceType.IS_IPAD ? 4 : 2.5)), height: collectionView.frame.height)
    }

}

extension MapDetailViewController: MultiMapViewDelegate {

    @objc func mapView(_ mapView: MultiMapView, didTapMarker marker: MultiMapMarker) {
        animateToCenter()
    }

}
