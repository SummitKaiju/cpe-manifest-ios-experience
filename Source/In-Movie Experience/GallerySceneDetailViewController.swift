//
//  GallerySceneDetailViewController.swift
//

import UIKit
import CPEData

class GallerySceneDetailViewController: SceneDetailViewController, UIScrollViewDelegate {

    @IBOutlet weak private var videoContainerView: UIView?
    @IBOutlet weak private var galleryScrollView: ImageGalleryScrollView?
    @IBOutlet weak private var descriptionLabel: UILabel!
    @IBOutlet weak private var pageControl: UIPageControl?
    @IBOutlet weak private var shareButton: UIButton?

    private var galleryDidScrollToPageObserver: NSObjectProtocol?

    // MARK: Initialization
    deinit {
        if let observer = galleryDidScrollToPageObserver {
            NotificationCenter.default.removeObserver(observer)
            galleryDidScrollToPageObserver = nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        galleryScrollView?.cleanInvisibleImages()
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        galleryScrollView?.allowsFullScreen = false
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if let timedEvent = timedEvent {
            if timedEvent.isType(.video) {
                galleryScrollView?.removeFromSuperview()
                pageControl?.removeFromSuperview()
                shareButton?.removeFromSuperview()
                galleryScrollView = nil
                pageControl = nil
                shareButton = nil

                if let videoURL = timedEvent.audioVisual?.presentation?.video?.url {
                    descriptionLabel.text = timedEvent.description

                    if let videoContainerView = videoContainerView, let videoPlayerViewController = UIStoryboard.viewController(for: VideoPlayerViewController.self) as? VideoPlayerViewController {
                        videoPlayerViewController.mode = VideoPlayerMode.supplementalInMovie

                        videoPlayerViewController.view.frame = videoContainerView.bounds
                        videoContainerView.addSubview(videoPlayerViewController.view)
                        self.addChild(videoPlayerViewController)
                        videoPlayerViewController.didMove(toParent: self)

                        videoPlayerViewController.playAsset(withURL: videoURL)
                    }
                }
            } else if let gallery = timedEvent.gallery {
                videoContainerView?.removeFromSuperview()
                videoContainerView = nil

                galleryScrollView?.load(with: gallery)
                descriptionLabel.text = gallery.description

                if gallery.isTurntable {
                    shareButton?.removeFromSuperview()
                    shareButton = nil
                } else {
                    shareButton?.setTitle(String.localize("gallery.share_button").uppercased(), for: .normal)
                    galleryScrollView?.removeToolbar()
                    pageControl?.numberOfPages = gallery.numPictures
                    if pageControl != nil && pageControl!.numberOfPages > 0 {
                        galleryDidScrollToPageObserver = NotificationCenter.default.addObserver(forName: .imageGalleryDidScrollToPage, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
                            if let strongSelf = self, let page = notification.userInfo?[NotificationConstants.page] as? Int {
                                strongSelf.pageControl?.currentPage = page
                                Analytics.log(event: .imeImageGalleryAction, action: .scrollImageGallery, itemId: gallery.analyticsID)
                            }
                        })
                    }
                }
            }
        }
    }

    // MARK: Actions
    @IBAction func onShare(_ sender: UIButton?) {
        if let url = galleryScrollView?.currentImageURL, let imageId = galleryScrollView?.currentImageId, let title = CPEXMLSuite.current?.manifest.title {
            let showShareDialog = { [weak self] (url: URL) in
                let activityViewController = UIActivityViewController(activityItems: [String.localize("gallery.share_message", variables: ["movie_name": title, "url": url.absoluteString])], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = sender
                self?.present(activityViewController, animated: true, completion: nil)

                Analytics.log(event: .imeImageGalleryAction, action: .shareImage, itemId: imageId)
                NotificationCenter.default.post(name: .videoPlayerShouldPause, object: nil)
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
        if let pageControl = pageControl {
            galleryScrollView?.gotoPage(pageControl.currentPage, animated: true)
        }
    }

}
