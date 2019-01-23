//
//  ClipShareSceneDetailViewController.swift
//

import UIKit
import CPEData

class ClipShareSceneDetailViewController: SceneDetailViewController {

    @IBOutlet weak private var clipShareTitleLabel: UILabel!
    @IBOutlet weak private var previousButton: UIButton!
    @IBOutlet weak private var nextButton: UIButton!
    @IBOutlet weak private var videoContainerView: UIView!
    @IBOutlet weak private var previewImageView: UIImageView!
    @IBOutlet weak private var previewPlayButton: UIButton!
    @IBOutlet weak private var clipNameLabel: UILabel!
    @IBOutlet weak private var shareButton: UIButton!

    private var videoPlayerViewController: VideoPlayerViewController?
    private var previousTimedEvent: TimedEvent?
    private var nextTimedEvent: TimedEvent?

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        nextButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi)

        reloadClipViews()

        // Localizations
        clipShareTitleLabel.text = String.localize("clipshare.select_clip_title").uppercased()
        shareButton.setTitle(String.localize("clipshare.share_button").uppercased(), for: .normal)
    }

    private func destroyVideoPlayer() {
        videoPlayerViewController?.willMove(toParent: nil)
        videoPlayerViewController?.view.removeFromSuperview()
        videoPlayerViewController?.removeFromParent()
        videoPlayerViewController = nil
        videoContainerView.isHidden = true
        previewImageView.isHidden = false
        previewPlayButton.isHidden = false
    }

    private func reloadClipViews() {
        destroyVideoPlayer()

        if let imageURL = timedEvent?.imageURL {
            previewImageView.sd_setImage(with: imageURL)
        } else {
            previewImageView.sd_cancelCurrentImageLoad()
            previewImageView.image = nil
        }

        videoContainerView.isHidden = true
        clipNameLabel.text = timedEvent?.description

        DispatchQueue.global(qos: .userInitiated).async {
            if let timedEvent = self.timedEvent {
                self.previousTimedEvent = CPEXMLSuite.current?.manifest.previousTimedEvent(from: timedEvent, ofType: .clipShare)
                self.nextTimedEvent = CPEXMLSuite.current?.manifest.nextTimedEvent(from: timedEvent, ofType: .clipShare)
            }

            DispatchQueue.main.async {
                self.previousButton.isHidden = (self.previousTimedEvent == nil)
                self.nextButton.isHidden = (self.nextTimedEvent == nil)
            }
        }
    }

    // MARK: Actions
    override internal func onClose() {
        super.onClose()

        destroyVideoPlayer()
    }

    @IBAction private func onPlay() {
        previewImageView.isHidden = true
        previewPlayButton.isHidden = true

        if let videoURL = timedEvent?.audioVisual?.presentation?.video?.url, let videoPlayerViewController = UIStoryboard.viewController(for: VideoPlayerViewController.self) as? VideoPlayerViewController {
            videoPlayerViewController.removeCurrentItem()
            videoPlayerViewController.mode = .supplementalInMovie
            videoPlayerViewController.view.frame = videoContainerView.bounds

            videoContainerView.isHidden = false
            videoContainerView.addSubview(videoPlayerViewController.view)
            self.addChild(videoPlayerViewController)
            videoPlayerViewController.didMove(toParent: self)

            videoPlayerViewController.playAsset(withURL: videoURL)
            self.videoPlayerViewController = videoPlayerViewController

            Analytics.log(event: .imeClipShareAction, action: .selectVideo, itemId: timedEvent?.analyticsID)
        }
    }

    @IBAction private func onTapPrevious() {
        if let timedEvent = previousTimedEvent {
            self.timedEvent = timedEvent
            reloadClipViews()
            Analytics.log(event: .imeClipShareAction, action: .selectPrevious, itemId: timedEvent.analyticsID)
        }
    }

    @IBAction private func onTapNext() {
        if let timedEvent = nextTimedEvent {
            self.timedEvent = timedEvent
            reloadClipViews()
            Analytics.log(event: .imeClipShareAction, action: .selectNext, itemId: timedEvent.analyticsID)
        }
    }

    @IBAction private func onShare(_ sender: UIButton) {
        if let video = timedEvent?.audioVisual?.presentation?.video, let videoURL = video.url {
            let showShareDialog = { [weak self] (url: URL) in
                let activityViewController = UIActivityViewController(activityItems: [String.localize("clipshare.share_message", variables: ["movie_name": CPEXMLSuite.current?.manifest.mainExperience.title, "url": url.absoluteString])], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = sender
                self?.present(activityViewController, animated: true, completion: nil)

                Analytics.log(event: .imeClipShareAction, action: .shareVideo, itemId: video.analyticsID)
                NotificationCenter.default.post(name: .videoPlayerShouldPause, object: nil)
            }

            if let delegate = ExperienceLauncher.delegate {
                delegate.urlForSharedContent(id: video.id, type: .video, completion: { (newURL) in
                    showShareDialog(newURL ?? videoURL)
                })
            } else {
                showShareDialog(videoURL)
            }
        }
    }

}
