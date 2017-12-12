//
//  HomeViewController.swift
//

import UIKit
import AVFoundation
import CPEData

class HomeViewController: UIViewController {

    private struct Constants {
        static let OverlayFadeInDuration = 0.5
    }

    private struct SegueIdentifier {
        static let ShowInMovieExperience = "ShowInMovieExperienceSegueIdentifier"
        static let ShowOutOfMovieExperience = "ShowOutOfMovieExperienceSegueIdentifier"
    }

    @IBOutlet weak private var exitButton: UIButton!
    @IBOutlet weak private var backgroundImageView: UIImageView!
    @IBOutlet weak private var backgroundVideoView: UIView!
    private var backgroundVideoPlayerViewController: VideoPlayerViewController?

    private var buttonOverlayView: UIView!
    private var playButton: UIButton!
    private var extrasButton: UIButton!
    private var buyButton: UIButton?
    private var titleOverlayView: UIView?
    private var titleImageView: UIImageView?
    private var homeScreenViews = [UIView]()
    private var interfaceCreated = false
    private var onTapHomeViewGestureRecognizer: UITapGestureRecognizer?

    private var applicationWillResignActiveObserver: NSObjectProtocol?
    private var applicationWillEnterForegroundObserver: NSObjectProtocol?
    private var shouldLaunchExtrasObserver: NSObjectProtocol?

    private var backgroundAudioPlayer: AVPlayer?
    private var backgroundAudioDidFinishPlayingObserver: NSObjectProtocol?

    private var backgroundVideoLastTimecode = 0.0
    private var backgroundVideoPreviewImageView: UIImageView?
    private var backgroundVideoDidFinishPlayingObserver: NSObjectProtocol?
    private var backgroundVideoTimeObserver: NSObjectProtocol?
    private var backgroundVideoFadeTime: Double {
        if let loopTimecode = nodeStyle?.backgroundVideoLoopTimecode {
            return max(loopTimecode - Constants.OverlayFadeInDuration, 0)
        }

        return 0
    }

    private var nodeStyle: NodeStyle? {
        return CPEXMLSuite.current!.cpeStyle?.nodeStyle(withExperienceID: CPEXMLSuite.current!.manifest.mainExperience.id, interfaceOrientation: UIApplication.shared.statusBarOrientation)
    }

    private var backgroundVideoSize: CGSize {
        return (nodeStyle?.backgroundVideo?.size ?? CGSize.zero)
    }

    private var observedBackgroundImageSize: CGSize?
    private var backgroundImageSize: CGSize {
        return (nodeStyle?.backgroundImage?.size ?? observedBackgroundImageSize ?? CGSize.zero)
    }

    private var playButtonImage: Image? {
        return nodeStyle?.theme.baseImageForButton("Play")
    }

    private var extrasButtonImage: Image? {
        return nodeStyle?.theme.baseImageForButton("Extras")
    }

    private var buyButtonImage: Image? {
        return nodeStyle?.theme.baseImageForButton("Buy")
    }

    private var buttonOverlaySize: CGSize {
        return (nodeStyle?.buttonOverlayArea?.size ?? CGSize(width: 300, height: 100))
    }

    private var buttonOverlayBottomLeft: CGPoint {
        return (nodeStyle?.buttonOverlayArea?.bottomLeftPoint ?? CGPoint(x: 490, y: 25))
    }

    private var playButtonSize: CGSize {
        return (playButtonImage?.size ?? CGSize(width: 300, height: 55))
    }

    private var extrasButtonSize: CGSize {
        return (extrasButtonImage?.size ?? CGSize(width: 300, height: 60))
    }

    private var buyButtonSize: CGSize {
        return (buyButtonImage?.size ?? playButtonSize)
    }

    private var titleOverlaySize: CGSize {
        return (nodeStyle?.titleOverlayArea?.size ?? CGSize(width: 400, height: 133))
    }

    private var titleOverlayBottomLeft: CGPoint {
        return (nodeStyle?.titleOverlayArea?.bottomLeftPoint ?? CGPoint(x: 440, y: backgroundImageSize.height - (titleOverlaySize.height + 15)))
    }

    deinit {
        unloadBackground()

        if let observer = applicationWillResignActiveObserver {
            NotificationCenter.default.removeObserver(observer)
            applicationWillResignActiveObserver = nil
        }

        if let observer = applicationWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
            applicationWillEnterForegroundObserver = nil
        }

        if let observer = shouldLaunchExtrasObserver {
            NotificationCenter.default.removeObserver(observer)
            shouldLaunchExtrasObserver = nil
        }
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        applicationWillResignActiveObserver = NotificationCenter.default.addObserver(forName: .applicationWillResignActive, object: nil, queue: OperationQueue.main, using: { [weak self] (_) in
            self?.unloadBackground()
        })

        applicationWillEnterForegroundObserver = NotificationCenter.default.addObserver(forName: .applicationWillEnterForeground, object: nil, queue: OperationQueue.main, using: { [weak self] (_) in
            if let strongSelf = self, strongSelf.isViewLoaded, strongSelf.view.window != nil {
                strongSelf.unloadBackground()
                strongSelf.loadBackground()
            }
        })

        shouldLaunchExtrasObserver = NotificationCenter.default.addObserver(forName: .outOfMovieExperienceShouldLaunch, object: nil, queue: OperationQueue.main, using: { [weak self] (_) in
            self?.onExtras()
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !interfaceCreated {
            homeScreenViews.removeAll()

            backgroundImageView.isUserInteractionEnabled = false

            exitButton.setTitle(String.localize("label.exit"), for: .normal)
            exitButton.titleLabel?.layer.shadowColor = UIColor.black.cgColor
            exitButton.titleLabel?.layer.shadowOpacity = 0.75
            exitButton.titleLabel?.layer.shadowRadius = 2
            exitButton.titleLabel?.layer.shadowOffset = CGSize(width: 0, height: 1)
            exitButton.titleLabel?.layer.masksToBounds = false
            exitButton.titleLabel?.layer.shouldRasterize = true
            homeScreenViews.append(exitButton)

            onTapHomeViewGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapHomeView))
            self.view.addGestureRecognizer(onTapHomeViewGestureRecognizer!)

            buttonOverlayView = UIView()
            buttonOverlayView.isHidden = true
            buttonOverlayView.isUserInteractionEnabled = true
            homeScreenViews.append(buttonOverlayView)

            // Play button
            playButton = UIButton()
            playButton.addTarget(self, action: #selector(self.onPlay), for: .touchUpInside)
            playButton.layer.shadowRadius = 5
            playButton.layer.shadowColor = UIColor.black.cgColor
            playButton.layer.shadowOffset = CGSize.zero
            playButton.layer.masksToBounds = false

            if let playButtonImageURL = playButtonImage?.url {
                playButton.sd_setImage(with: playButtonImageURL, for: .normal)
                playButton.contentHorizontalAlignment = .fill
                playButton.contentVerticalAlignment = .fill
                playButton.imageView?.contentMode = .scaleAspectFit
            } else {
                playButton.setTitle(String.localize("label.play_movie"), for: .normal)
                playButton.titleLabel?.font = UIFont.themeCondensedBoldFont(15)
                playButton.backgroundColor = UIColor.red
            }

            // Extras button
            extrasButton = UIButton()
            extrasButton.addTarget(self, action: #selector(self.onExtras), for: .touchUpInside)
            extrasButton.layer.shadowRadius = 5
            extrasButton.layer.shadowColor = UIColor.black.cgColor
            extrasButton.layer.shadowOffset = CGSize.zero
            extrasButton.layer.masksToBounds = false

            let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.didLongPressExtrasButton(_:)))
            longPressGestureRecognizer.minimumPressDuration = 5
            extrasButton.addGestureRecognizer(longPressGestureRecognizer)

            if let extrasButtonImageURL = extrasButtonImage?.url {
                extrasButton.sd_setImage(with: extrasButtonImageURL, for: .normal)
                extrasButton.contentHorizontalAlignment = .fill
                extrasButton.contentVerticalAlignment = .fill
                extrasButton.imageView?.contentMode = .scaleAspectFit
            } else {
                extrasButton.setTitle(String.localize("label.extras"), for: .normal)
                extrasButton.titleLabel?.font = UIFont.themeCondensedBoldFont(15)
                extrasButton.backgroundColor = UIColor.gray
            }

            // Buy button
            if let buyButtonImage = buyButtonImage, let buyButtonImageUrl = buyButtonImage.url {
                buyButton = UIButton()
                buyButton!.addTarget(self, action: #selector(self.onBuy), for: .touchUpInside)
                buyButton!.layer.shadowRadius = 5
                buyButton!.layer.shadowColor = UIColor.black.cgColor
                buyButton!.layer.shadowOffset = CGSize.zero
                buyButton!.layer.masksToBounds = false
                buyButton!.sd_setImage(with: buyButtonImageUrl, for: .normal)
                buyButton!.contentHorizontalAlignment = .fill
                buyButton!.contentVerticalAlignment = .fill
                buyButton!.imageView?.contentMode = .scaleAspectFit
                buttonOverlayView.addSubview(buyButton!)
            }

            buttonOverlayView.addSubview(playButton)
            buttonOverlayView.addSubview(extrasButton)
            self.view.addSubview(buttonOverlayView)

            // Title treatment
            if nodeStyle == nil || nodeStyle!.titleOverlayArea?.size != nil, let imageURL = CPEXMLSuite.current?.manifest.titleTreatmentImageURL {
                titleOverlayView = UIView()
                titleOverlayView!.isHidden = true
                titleOverlayView!.isUserInteractionEnabled = false
                homeScreenViews.append(titleOverlayView!)

                titleImageView = UIImageView()
                titleImageView!.contentMode = .scaleAspectFit
                titleImageView!.sd_setImage(with: imageURL)
                titleOverlayView!.addSubview(titleImageView!)

                self.view.addSubview(titleOverlayView!)
                homeScreenViews.append(titleOverlayView!)
            }

            loadBackground()
            interfaceCreated = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if interfaceCreated && !ExperienceLauncher.isBeingDismissed {
            loadBackground()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        backgroundVideoPreviewImageView?.removeFromSuperview()
        backgroundVideoPreviewImageView = nil
        backgroundVideoLastTimecode = 0

        if let image = backgroundVideoPlayerViewController?.screenGrab {
            backgroundVideoLastTimecode = backgroundVideoPlayerViewController!.currentTime
            backgroundVideoPreviewImageView = UIImageView(frame: backgroundVideoView.frame)
            backgroundVideoPreviewImageView!.contentMode = .scaleAspectFill
            backgroundVideoPreviewImageView!.image = image
            self.view.addSubview(backgroundVideoPreviewImageView!)
            self.view.bringSubview(toFront: exitButton)
            self.view.bringSubview(toFront: buttonOverlayView)
            if let titleOverlayView = titleOverlayView {
                self.view.bringSubview(toFront: titleOverlayView)
            }
        }

        unloadBackground()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if self.view.window != nil && !self.isBeingDismissed {
            coordinator.animate(alongsideTransition: { [weak self] (_) in
                if let strongSelf = self, strongSelf.interfaceCreated {
                    if let currentURL = strongSelf.backgroundVideoPlayerViewController?.url {
                        if let newURL = self?.nodeStyle?.backgroundVideo?.url, currentURL != newURL {
                            strongSelf.unloadBackground()
                            strongSelf.loadBackground()
                        } else {
                            strongSelf.seekBackgroundVideoToLoopTimecode()
                            strongSelf.showHomeScreenViews(animated: false)
                        }
                    } else {
                        strongSelf.unloadBackground()
                        strongSelf.loadBackground()
                    }
                }
            }, completion: nil)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if interfaceCreated && !self.isBeingDismissed && (backgroundVideoSize != CGSize.zero || backgroundImageSize != CGSize.zero) {
            let viewWidth = self.view.frame.width
            let viewHeight = self.view.frame.height
            let viewAspectRatio = viewWidth / viewHeight

            if backgroundVideoSize != CGSize.zero {
                var backgroundPoint = CGPoint(x: 0, y: StatusBarSize.HEIGHT)
                var backgroundSize = CGSize.zero
                let backgroundVideoAspectRatio = backgroundVideoSize.width / backgroundVideoSize.height

                if nodeStyle?.backgroundScaleMethod == .full {
                    if backgroundVideoAspectRatio > viewAspectRatio {
                        backgroundSize.width = viewWidth
                        backgroundSize.height = backgroundSize.width / backgroundVideoAspectRatio

                        if nodeStyle?.backgroundPositioningMethod == .centered {
                            backgroundPoint.y = (viewHeight - backgroundSize.height) / 2
                        }
                    } else {
                        backgroundSize.height = viewHeight
                        backgroundSize.width = backgroundSize.height * backgroundVideoAspectRatio

                        if nodeStyle?.backgroundPositioningMethod == .centered {
                            backgroundPoint.x = (viewWidth - backgroundSize.width) / 2
                        }
                    }
                } else {
                    if backgroundVideoAspectRatio > viewAspectRatio {
                        backgroundSize.height = viewHeight
                        backgroundSize.width = backgroundSize.height * backgroundVideoAspectRatio
                    } else {
                        backgroundSize.width = viewWidth
                        backgroundSize.height = backgroundSize.width / backgroundVideoAspectRatio
                    }

                    if nodeStyle?.backgroundPositioningMethod == .centered {
                        backgroundPoint.x = (backgroundSize.width - viewWidth) / -2
                        backgroundPoint.y = (backgroundSize.height - viewHeight) / -2
                    }
                }

                backgroundVideoView.frame = CGRect(x: backgroundPoint.x, y: backgroundPoint.y, width: backgroundSize.width, height: backgroundSize.height)
                backgroundVideoPreviewImageView?.frame = backgroundVideoView.frame
            }

            if backgroundImageSize != CGSize.zero {
                var backgroundPoint = CGPoint.zero
                var backgroundSize = CGSize.zero
                let backgroundImageAspectRatio = backgroundImageSize.width / backgroundImageSize.height

                if nodeStyle?.backgroundScaleMethod == .full && nodeStyle?.backgroundVideo?.url == nil {
                    if backgroundImageAspectRatio > viewAspectRatio {
                        backgroundSize.width = viewWidth
                        backgroundSize.height = backgroundSize.width / backgroundImageAspectRatio

                        if nodeStyle?.backgroundPositioningMethod == .centered {
                            backgroundPoint.y = (viewHeight - backgroundSize.height) / 2
                        }
                    } else {
                        backgroundSize.height = viewHeight
                        backgroundSize.width = backgroundSize.height * backgroundImageAspectRatio

                        if nodeStyle?.backgroundPositioningMethod == .centered {
                            backgroundPoint.x = (viewWidth - backgroundSize.width) / 2
                        }
                    }
                } else {
                    if backgroundImageAspectRatio > viewAspectRatio {
                        backgroundSize.height = viewHeight
                        backgroundSize.width = backgroundSize.height * backgroundImageAspectRatio
                    } else {
                        backgroundSize.width = viewWidth
                        backgroundSize.height = backgroundSize.width / backgroundImageAspectRatio
                    }

                    if nodeStyle == nil || nodeStyle?.backgroundVideo?.url != nil || nodeStyle?.backgroundPositioningMethod == .centered {
                        backgroundPoint.x = (backgroundSize.width - viewWidth) / -2
                        backgroundPoint.y = (backgroundSize.height - viewHeight) / -2
                    }
                }

                backgroundImageView.frame = CGRect(x: backgroundPoint.x, y: backgroundPoint.y, width: backgroundSize.width, height: backgroundSize.height)
            }

            var backgroundBaseSize = CGSize.zero
            var backgroundNewSize = CGSize.zero
            var backgroundPoint = CGPoint.zero

            if backgroundImageSize != CGSize.zero {
                backgroundBaseSize = backgroundImageSize
                backgroundNewSize = backgroundImageView.frame.size
                backgroundPoint = backgroundImageView.frame.origin
            } else if backgroundVideoSize != CGSize.zero {
                backgroundBaseSize = backgroundVideoSize
                backgroundNewSize = backgroundVideoView.frame.size
                backgroundPoint = backgroundVideoView.frame.origin
            }

            if backgroundBaseSize != CGSize.zero {
                let backgroundNewScale = (backgroundNewSize.height / backgroundBaseSize.height)
                let buttonOverlayWidth = min(buttonOverlaySize.width * backgroundNewScale, viewWidth - 20)
                let buttonOverlayHeight = buttonOverlayWidth / (buttonOverlaySize.width / buttonOverlaySize.height)
                let buttonOverlayX = (buttonOverlayBottomLeft.x * backgroundNewScale) - ((backgroundNewSize.width - viewWidth) / 2)

                buttonOverlayView.frame = CGRect(
                    x: buttonOverlayX < 0 || (buttonOverlayX + buttonOverlayWidth > viewWidth) ? 10 : buttonOverlayX,
                    y: backgroundNewSize.height - (buttonOverlayBottomLeft.y * backgroundNewScale) - buttonOverlayHeight + backgroundPoint.y,
                    width: buttonOverlayWidth,
                    height: buttonOverlayHeight
                )

                playButton.frame = CGRect(x: 0, y: 0, width: buttonOverlayView.frame.width, height: buttonOverlayView.frame.width / (playButtonSize.width / playButtonSize.height))

                let extrasButtonWidth = playButton.frame.width * 0.675
                let extrasButtonHeight = extrasButtonWidth / (extrasButtonSize.width / extrasButtonSize.height)
                extrasButton.frame.size = CGSize(width: extrasButtonWidth, height: extrasButtonHeight)
                if let buyButton = buyButton {
                    extrasButton.center = CGPoint(x: buttonOverlayWidth / 2, y: buttonOverlayHeight / 2)

                    buyButton.frame.size = playButton.frame.size
                    buyButton.frame.origin = CGPoint(x: (buttonOverlayWidth - buyButton.frame.size.width) / 2, y: buttonOverlayHeight - buyButton.frame.size.height)
                } else {
                    extrasButton.frame.origin = CGPoint(x: (buttonOverlayWidth - extrasButtonWidth) / 2, y: buttonOverlayHeight - extrasButtonHeight)
                }

                if let titleOverlayView = titleOverlayView {
                    let titleOverlayWidth = min(titleOverlaySize.width * backgroundNewScale, viewWidth * 0.9)
                    let titleOverlayHeight = titleOverlayWidth / (titleOverlaySize.width / titleOverlaySize.height)
                    let titleOverlayX = (titleOverlayBottomLeft.x * backgroundNewScale) - ((backgroundNewSize.width - viewWidth) / 2)

                    titleOverlayView.frame = CGRect(
                        x: titleOverlayX < 0 || (titleOverlayX + titleOverlaySize.width > viewWidth) ? (viewWidth - titleOverlayWidth) / 2 : titleOverlayX,
                        y: viewHeight - titleOverlayBottomLeft.y * backgroundNewScale - titleOverlayHeight,
                        width: titleOverlayWidth,
                        height: titleOverlayHeight
                    )

                    titleImageView?.frame = titleOverlayView.bounds
                }
            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return (DeviceType.IS_IPAD ? .landscape : .all)
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if DeviceType.IS_IPAD {
            let interfaceOrientation = UIApplication.shared.statusBarOrientation
            return UIInterfaceOrientationIsLandscape(interfaceOrientation) ? interfaceOrientation : .landscapeLeft
        }

        return super.preferredInterfaceOrientationForPresentation
    }

    @objc private func didLongPressExtrasButton(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            ExperienceLauncher.delegate?.experienceWillEnterDebugMode()
        }
    }

    // MARK: Helpers
    private func showHomeScreenViews(animated: Bool, exitButtonOnly: Bool = false) {
        if homeScreenViews.count > 0 {
            if exitButtonOnly, let exitButtonIndex = homeScreenViews.index(of: exitButton) {
                homeScreenViews.remove(at: exitButtonIndex)
            }

            if animated {
                if exitButtonOnly {
                    exitButton.alpha = 0
                    exitButton.isHidden = false
                } else {
                    homeScreenViews.forEach {
                        $0.alpha = 0
                        $0.isHidden = false
                    }
                }

                UIView.animate(withDuration: Constants.OverlayFadeInDuration, animations: {
                    if exitButtonOnly {
                        self.exitButton.alpha = 1
                    } else {
                        self.homeScreenViews.forEach { $0.alpha = 1 }
                    }
                }, completion: { (_) in
                    if !exitButtonOnly {
                        self.homeScreenViews.removeAll()
                    }
                })
            } else {
                if exitButtonOnly {
                    exitButton.isHidden = false
                } else {
                    homeScreenViews.forEach { $0.isHidden = false }
                    homeScreenViews.removeAll()
                }
            }

            backgroundVideoPlayerViewController?.activityIndicatorDisabled = true
            if let tapGestureRecognizer = onTapHomeViewGestureRecognizer {
                self.view.removeGestureRecognizer(tapGestureRecognizer)
                onTapHomeViewGestureRecognizer = nil
            }
        }
    }

    private func seekBackgroundVideoToLoopTimecode() {
        if let nodeStyle = nodeStyle, nodeStyle.backgroundVideoLoops, let videoPlayerViewController = backgroundVideoPlayerViewController {
            videoPlayerViewController.seekPlayer(to: nodeStyle.backgroundVideoLoopTimecode)
            videoPlayerViewController.shouldMute = true
        }
    }

    // MARK: Video Player
    private func loadBackground() {
        if let nodeStyle = nodeStyle, let backgroundVideoURL = nodeStyle.backgroundVideo?.url, let videoPlayerViewController = UIStoryboard.viewController(for: VideoPlayerViewController.self) as? VideoPlayerViewController {
            videoPlayerViewController.mode = .basicPlayer

            videoPlayerViewController.view.frame = backgroundVideoView.bounds
            backgroundVideoView.addSubview(videoPlayerViewController.view)
            self.addChildViewController(videoPlayerViewController)
            videoPlayerViewController.didMove(toParentViewController: self)

            backgroundVideoTimeObserver = NotificationCenter.default.addObserver(forName: .videoPlayerDidChangeTime, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
                if let strongSelf = self, let time = notification.userInfo?[NotificationConstants.time] as? Double {
                    if time > strongSelf.backgroundVideoLastTimecode {
                        strongSelf.backgroundVideoPreviewImageView?.removeFromSuperview()
                        strongSelf.backgroundVideoPreviewImageView = nil
                        strongSelf.backgroundVideoLastTimecode = 0
                    }

                    if strongSelf.backgroundVideoFadeTime > 0 {
                        if strongSelf.homeScreenViews.count > 0 && time > strongSelf.backgroundVideoFadeTime {
                            strongSelf.showHomeScreenViews(animated: true)
                        }
                    } else {
                        strongSelf.showHomeScreenViews(animated: false)
                    }
                }
            })

            if nodeStyle.backgroundVideoLoops {
                backgroundVideoDidFinishPlayingObserver = NotificationCenter.default.addObserver(forName: .videoPlayerDidEndVideo, object: nil, queue: OperationQueue.main, using: { [weak self] (_) in
                    self?.seekBackgroundVideoToLoopTimecode()
                })
            }

            videoPlayerViewController.view.isUserInteractionEnabled = false
            videoPlayerViewController.shouldMute = interfaceCreated
            videoPlayerViewController.shouldTrackOutput = true
            videoPlayerViewController.playAsset(withURL: backgroundVideoURL, fromStartTime: (backgroundVideoLastTimecode > 0 || !interfaceCreated ? backgroundVideoLastTimecode : backgroundVideoFadeTime))
            backgroundVideoPlayerViewController = videoPlayerViewController
        } else {
            showHomeScreenViews(animated: false)
        }

        if let backgroundImageURL = nodeStyle?.backgroundImage?.url {
            backgroundImageView.sd_setImage(with: backgroundImageURL)
        } else if nodeStyle?.backgroundVideo?.url == nil {
            if let backgroundImageURL = CPEXMLSuite.current?.manifest.backgroundImageURL {
                backgroundImageView.sd_setImage(with: backgroundImageURL, completed: { [weak self] (image, _, _, _) in
                    if let image = image {
                        self?.observedBackgroundImageSize = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
                        self?.view.setNeedsLayout()
                    }
                })
            } else {
                observedBackgroundImageSize = CGSize(width: 1280, height: 720)
            }
        }

        if !interfaceCreated, let backgroundAudioUrl = nodeStyle?.backgroundAudio?.url {
            let audioPlayerItem = AVPlayerItem(asset: AVAsset(url: backgroundAudioUrl))
            backgroundAudioDidFinishPlayingObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: audioPlayerItem, queue: nil, using: { (_) in
                DispatchQueue.main.async {
                    self.backgroundAudioPlayer?.seek(to: kCMTimeZero)
                    self.backgroundAudioPlayer?.play()
                }
            })

            backgroundAudioPlayer = AVPlayer(playerItem: audioPlayerItem)
            backgroundAudioPlayer?.allowsExternalPlayback = false
            backgroundAudioPlayer?.play()
        }
    }

    private func unloadBackground() {
        if let observer = backgroundVideoTimeObserver {
            NotificationCenter.default.removeObserver(observer)
            backgroundVideoTimeObserver = nil
        }

        if let observer = backgroundVideoDidFinishPlayingObserver {
            NotificationCenter.default.removeObserver(observer)
            backgroundVideoDidFinishPlayingObserver = nil
        }

        if let observer = backgroundAudioDidFinishPlayingObserver {
            NotificationCenter.default.removeObserver(observer)
            backgroundAudioDidFinishPlayingObserver = nil
        }

        backgroundVideoPlayerViewController?.willMove(toParentViewController: nil)
        backgroundVideoPlayerViewController?.view.removeFromSuperview()
        backgroundVideoPlayerViewController?.removeFromParentViewController()
        backgroundVideoPlayerViewController = nil
        backgroundImageView.image = nil
        backgroundAudioPlayer = nil
    }

    // MARK: Actions
    @objc private func onTapHomeView() {
        showHomeScreenViews(animated: true)
    }

    @objc private func onPlay() {
        self.performSegue(withIdentifier: SegueIdentifier.ShowInMovieExperience, sender: nil)
        Analytics.log(event: .homeAction, action: .launchInMovie)
    }

    @objc private func onExtras() {
        self.performSegue(withIdentifier: SegueIdentifier.ShowOutOfMovieExperience, sender: CPEXMLSuite.current?.manifest.outOfMovieExperience)
        Analytics.log(event: .homeAction, action: .launchExtras)
    }

    @objc private func onBuy() {
        ExperienceLauncher.delegate?.previewModeShouldLaunchBuy()
        Analytics.log(event: .homeAction, action: .launchBuy)
    }

    @IBAction private func onExit() {
        Analytics.log(event: .homeAction, action: .exit)
        ExperienceLauncher.close()
    }

    // MARK: Storyboard
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? ExtrasExperienceViewController, let experience = sender as? Experience {
            viewController.experience = experience
        }
    }

}
