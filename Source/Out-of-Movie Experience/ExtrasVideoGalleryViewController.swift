//
//  SecondTemplateViewController.swift
//

import UIKit
import CPEData

class ExtrasVideoGalleryViewController: ExtrasExperienceViewController {

    fileprivate struct Constants {
        static let GalleryTableViewImageAspectRatio: CGFloat = 16 / 9
        static let GalleryTableViewLabelHeight: CGFloat = 10
        static let GalleryTableViewPadding: CGFloat = 50
        static let GalleryTableViewMobileAspectRatio: CGFloat = 600 / 195
    }

    @IBOutlet weak private var galleryTableView: UITableView!

    @IBOutlet weak private var videoContainerView: UIView!
    @IBOutlet weak private var previewImageView: UIImageView!
    @IBOutlet weak private var previewPlayButton: UIButton!
    @IBOutlet weak private var mediaTitleLabel: UILabel!
    @IBOutlet weak private var mediaDescriptionLabel: UILabel?
    @IBOutlet weak private var mediaDescriptionTextView: UITextView?
    private var videoPlayerViewController: VideoPlayerViewController?
    private var videoPlayerDidToggleFullScreenObserver: NSObjectProtocol?

    @IBOutlet weak private var galleryScrollView: ImageGalleryScrollView!
    @IBOutlet weak private var galleryPageControl: UIPageControl!
    private var galleryDidScrollToPageObserver: NSObjectProtocol?
    private var galleryDidToggleFullScreenObserver: NSObjectProtocol?

    @IBOutlet private var containerTopConstraint: NSLayoutConstraint?
    @IBOutlet private var containerBottomConstraint: NSLayoutConstraint?
    @IBOutlet private var containerAspectRatioConstraint: NSLayoutConstraint?

    @IBOutlet weak private var shareButton: UIButton!

    private var didInitialSetup = false
    fileprivate var didPlayFirstItem = false

    private var willPlayNextItemObserver: NSObjectProtocol?
    private var didEndLastVideoObserver: NSObjectProtocol?

    private var currentGallery: Gallery?
    private var currentVideoAnalyticsIdentifier: String?

    // MARK: Initialization
    deinit {
        let center = NotificationCenter.default

        if let observer = videoPlayerDidToggleFullScreenObserver {
            center.removeObserver(observer)
            videoPlayerDidToggleFullScreenObserver = nil
        }

        if let observer = willPlayNextItemObserver {
            center.removeObserver(observer)
            willPlayNextItemObserver = nil
        }

        if let observer = didEndLastVideoObserver {
            center.removeObserver(observer)
            didEndLastVideoObserver = nil
        }

        if let observer = galleryDidScrollToPageObserver {
            center.removeObserver(observer)
            galleryDidScrollToPageObserver = nil
        }

        if let observer = galleryDidToggleFullScreenObserver {
            center.removeObserver(observer)
            galleryDidToggleFullScreenObserver = nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        galleryScrollView.cleanInvisibleImages()
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        videoPlayerDidToggleFullScreenObserver = NotificationCenter.default.addObserver(forName: .videoPlayerDidToggleFullScreen, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
            if let isFullScreen = notification.userInfo?[NotificationConstants.isFullScreen] as? Bool, isFullScreen {
                Analytics.log(event: .extrasVideoGalleryAction, action: .setVideoFullScreen, itemId: self?.currentVideoAnalyticsIdentifier)
            }
        })

        willPlayNextItemObserver = NotificationCenter.default.addObserver(forName: .videoPlayerWillPlayNextItem, object: nil, queue: OperationQueue.main) { [weak self] (notification) -> Void in
            if let strongSelf = self, let index = notification.userInfo?[NotificationConstants.index] as? Int, index < max(strongSelf.experience.numChildExperiences, 1) {
                let indexPath = IndexPath(row: index, section: 0)
                strongSelf.galleryTableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableView.ScrollPosition.top)
                strongSelf.tableView(strongSelf.galleryTableView, didSelectRowAt: indexPath)
            }
        }

        didEndLastVideoObserver = NotificationCenter.default.addObserver(forName: .videoPlayerDidEndLastVideo, object: nil, queue: OperationQueue.main, using: { [weak self] (_) in
            self?.previewImageView.isHidden = false
            self?.previewPlayButton.isHidden = false
            self?.destroyVideoPlayer()

            if let selectedIndexPath = self?.galleryTableView.indexPathForSelectedRow, let cell = self?.galleryTableView.cellForRow(at: selectedIndexPath) as? VideoCell {
                cell.setWatched()
            }
        })

        galleryDidScrollToPageObserver = NotificationCenter.default.addObserver(forName: .imageGalleryDidScrollToPage, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
            if let gallery = self?.currentGallery, let page = notification.userInfo?[NotificationConstants.page] as? Int {
                self?.galleryPageControl.currentPage = page
                Analytics.log(event: .extrasImageGalleryAction, action: .scrollImageGallery, itemId: gallery.analyticsID)
            }
        })

        galleryDidToggleFullScreenObserver = NotificationCenter.default.addObserver(forName: .imageGalleryDidToggleFullScreen, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
            if let gallery = self?.currentGallery, let isFullScreen = notification.userInfo?[NotificationConstants.isFullScreen] as? Bool, isFullScreen {
                Analytics.log(event: .extrasImageGalleryAction, action: .setImageGalleryFullScreen, itemId: gallery.analyticsID)
            }
        })

        galleryTableView.register(UINib(nibName: VideoCell.NibName, bundle: Bundle.frameworkResources), forCellReuseIdentifier: VideoCell.ReuseIdentifier)
        galleryScrollView.allowsFullScreen = DeviceType.IS_IPAD
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return (DeviceType.IS_IPAD ? .landscape : .all)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didInitialSetup {
            let selectedPath = IndexPath(row: 0, section: 0)
            galleryTableView.selectRow(at: selectedPath, animated: false, scrollPosition: UITableView.ScrollPosition.top)
            self.tableView(galleryTableView, didSelectRowAt: selectedPath)
            didInitialSetup = true
        } else {
            galleryScrollView.layoutPages()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let toLandscape = (size.width > size.height)
        containerAspectRatioConstraint?.isActive = !toLandscape
        containerTopConstraint?.constant = (toLandscape ? 0 : ExtrasExperienceViewController.Constants.TitleImageHeight)
        containerBottomConstraint?.isActive = !toLandscape
        if #available(iOS 11.0, *) {
            self.setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return (containerBottomConstraint != nil && !containerBottomConstraint!.isActive)
    }

    private func playSelectedExperience() {
        if let selectedIndexPath = galleryTableView.indexPathForSelectedRow, let selectedExperience = (experience.childExperience(atIndex: selectedIndexPath.row) ?? experience) {
            if let imageURL = selectedExperience.largeImageURL {
                previewImageView.sd_setImage(with: imageURL)
            }

            let videoPlayerExists = videoPlayerViewController != nil
            if didPlayFirstItem, let videoURL = selectedExperience.video?.url, let videoPlayerViewController = (videoPlayerViewController ?? UIStoryboard.viewController(for: VideoPlayerViewController.self) as? VideoPlayerViewController) {
                previewImageView.isHidden = true
                previewPlayButton.isHidden = true

                videoPlayerViewController.removeCurrentItem()
                videoPlayerViewController.mode = VideoPlayerMode.supplemental
                videoPlayerViewController.queueTotalCount = max(experience.numChildExperiences, 1)
                videoPlayerViewController.queueCurrentIndex = selectedIndexPath.row

                if !videoPlayerExists {
                    videoPlayerViewController.view.frame = videoContainerView.bounds
                    videoContainerView.addSubview(videoPlayerViewController.view)
                    self.addChild(videoPlayerViewController)
                    videoPlayerViewController.didMove(toParent: self)
                }

                videoPlayerViewController.playAsset(withURL: videoURL, title: selectedExperience.title, imageURL: selectedExperience.thumbnailImageURL)
                if !DeviceType.IS_IPAD && videoPlayerViewController.fullScreenButton != nil {
                    videoPlayerViewController.fullScreenButton?.removeFromSuperview()
                }

                self.videoPlayerViewController = videoPlayerViewController
                self.currentVideoAnalyticsIdentifier = selectedExperience.video?.analyticsID
                Analytics.log(event: .extrasVideoGalleryAction, action: .selectVideo, itemId: self.currentVideoAnalyticsIdentifier)
            }
        }
    }

    private func destroyVideoPlayer() {
        videoPlayerViewController?.willMove(toParent: nil)
        videoPlayerViewController?.view.removeFromSuperview()
        videoPlayerViewController?.removeFromParent()
        videoPlayerViewController = nil
    }

    fileprivate func updateView(withExperience experience: Experience) {
        mediaTitleLabel.isHidden = true
        mediaDescriptionLabel?.isHidden = true
        mediaDescriptionTextView?.isHidden = true

        // Reset media detail views
        shareButton.isHidden = true
        galleryPageControl.isHidden = true
        galleryScrollView.isHidden = true
        videoContainerView.isHidden = false
        previewImageView.isHidden = didPlayFirstItem
        previewPlayButton.isHidden = didPlayFirstItem

        // Set new media detail views
        if let gallery = experience.gallery {
            mediaTitleLabel.text = nil
            galleryScrollView.isHidden = false
            videoContainerView.isHidden = true
            previewImageView.isHidden = true
            previewPlayButton.isHidden = true

            galleryScrollView.load(with: gallery)
            if !gallery.isTurntable {
                shareButton.isHidden = false
                shareButton.setTitle(String.localize("gallery.share_button").uppercased(), for: .normal)
                if gallery.numPictures < 20 {
                    galleryPageControl.isHidden = false
                    galleryPageControl.numberOfPages = gallery.numPictures
                }
            }

            currentGallery = gallery
            Analytics.log(event: .extrasImageGalleryAction, action: .selectImageGallery, itemId: gallery.analyticsID)
        } else if experience.isType(.audioVisual) {
            mediaTitleLabel.text = experience.title
            mediaDescriptionLabel?.text = experience.description
            mediaDescriptionTextView?.text = experience.description
            mediaTitleLabel.isHidden = false
            mediaDescriptionLabel?.isHidden = false
            mediaDescriptionTextView?.isHidden = false
            playSelectedExperience()
        }
    }

    // MARK: Actions
    @IBAction func onPlay() {
        didPlayFirstItem = true
        playSelectedExperience()
    }

    @IBAction func onShare(_ sender: UIButton?) {
        if !galleryScrollView.isHidden, let url = galleryScrollView.currentImageURL, let imageId = galleryScrollView.currentImageId, let title = CPEXMLSuite.current?.manifest.title {
            let showShareDialog = { [weak self] (url: URL) in
                let activityViewController = UIActivityViewController(activityItems: [String.localize("gallery.share_message", variables: ["movie_name": title, "url": url.absoluteString])], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = sender
                self?.present(activityViewController, animated: true, completion: nil)
                Analytics.log(event: .extrasImageGalleryAction, action: .shareImage, itemId: imageId)
            }

            if let delegate = ExperienceLauncher.delegate {
                delegate.urlForSharedContent(id: imageId, type: .image, completion: { (newUrl) in
                    showShareDialog(newUrl ?? url)
                })
            } else {
                showShareDialog(url)
            }
        }
    }

    @IBAction func onPageControlValueChanged() {
        galleryScrollView.gotoPage(galleryPageControl.currentPage, animated: true)
    }

}

extension ExtrasVideoGalleryViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: VideoCell.ReuseIdentifier, for: indexPath)
        guard let cell = tableViewCell as? VideoCell else {
            return tableViewCell
        }

        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        cell.experience = (experience.childExperience(atIndex: indexPath.row) ?? experience)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(experience.numChildExperiences, 1)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if DeviceType.IS_IPAD {
            return (tableView.frame.width / Constants.GalleryTableViewImageAspectRatio) + Constants.GalleryTableViewLabelHeight + Constants.GalleryTableViewPadding
        }

        return tableView.frame.width / Constants.GalleryTableViewMobileAspectRatio
    }

}

extension ExtrasVideoGalleryViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let cell = tableView.cellForRow(at: indexPath), !cell.isSelected {
            return indexPath
        }

        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row > 0 {
            didPlayFirstItem = true
        }

        if let thisExperience = (experience.childExperience(atIndex: indexPath.row) ?? experience) {
            updateView(withExperience: thisExperience)
        }
    }

}
