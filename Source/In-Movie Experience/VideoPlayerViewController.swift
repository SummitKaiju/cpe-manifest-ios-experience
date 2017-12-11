//
//  VideoPlayerViewController.swift
//

import Foundation
import UIKit
import AVKit
import AVFoundation
import MediaPlayer
import MessageUI
import CoreMedia
import CPEData
import UAProgressView
import MBProgressHUD
import GoogleCast
import SDWebImage

public enum VideoPlayerMode {
    case unknown
    case mainFeature
    case supplemental
    case supplementalInMovie
    case basicPlayer
}

public enum VideoPlayerState {
    case unknown
    case readyToPlay
    case videoLoading
    case videoSeeking
    case videoPlaying
    case videoPaused
    case suspended
    case dismissed
    case error
}

class VideoPlayerPlaybackView: UIView {

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer? {
        return (self.layer as? AVPlayerLayer)
    }

    var player: AVPlayer? {
        get {
            return playerLayer?.player
        }

        set {
            playerLayer?.player = newValue
        }
    }

    var isCroppingToActivePicture = false {
        didSet {
            playerLayer?.videoGravity = (isCroppingToActivePicture ? AVLayerVideoGravityResizeAspectFill : AVLayerVideoGravityResizeAspect)
        }
    }

}

class VideoPlayerViewController: UIViewController {

    private struct Constants {
        static let CommentaryEnabled = false

        static let CountdownTimeInterval: CGFloat = 1
        static let CountdownTotalTime: CGFloat = 5
        static let PlayerControlsAutoHideTime = 5.0

        struct Keys {
            static let Rate = "rate"
            static let Tracks = "tracks"
            static let Playable = "playable"
            static let ExternalPlaybackActive = "externalPlaybackActive"
            static let CurrentItem = "currentItem"
            static let CurrentItemStatus = "currentItem.status"
            static let CurrentItemDuration = "currentItem.duration"
            static let CurrentItemPlaybackBufferEmpty = "currentItem.playbackBufferEmpty"
            static let CurrentItemPlaybackLikelyToKeepUp = "currentItem.playbackLikelyToKeepUp"
            static let CurrentItemPresentationSize = "currentItem.presentationSize"
            static let AreWirelessRoutesAvailable = "areWirelessRoutesAvailable"
        }
    }
    
    private struct ObservationContexts {
        static var Status = 0
        static var Duration = 1
        static var BufferEmpty = 2
        static var PlaybackLikelyToKeepUp = 3
        static var PresentationSize = 4
        static var CurrentItem = 5
        static var Rate = 6
        static var ExternalPlayback = 7
    }

    var mode = VideoPlayerMode.supplemental
    var shouldMute = false
    var shouldTrackOutput = false

    fileprivate var playbackAsset: PlaybackAsset? {
        didSet {
            if let playbackAsset = playbackAsset {
                if mode == .mainFeature || mode == .supplemental {
                    UIApplication.shared.beginReceivingRemoteControlEvents()

                    if mode == .supplemental {
                        SettingsManager.setVideoAsWatched(playbackAsset.assetURL)
                    }
                }
            } else {
                UIApplication.shared.endReceivingRemoteControlEvents()
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            }
        }
    }

    fileprivate var player: AVPlayer?
    private var playerItemVideoOutput: AVPlayerItemVideoOutput?
    private var originalContainerView: UIView?

    // State
    var didPlayInterstitial = false
    private var isManuallyPaused = false
    private var isSeeking = false
    private var lastNotifiedTime = -1.0

    fileprivate var state = VideoPlayerState.unknown {
        didSet {
            if state != oldValue {
                switch state {
                case .unknown:
                    removePlayerTimeObserver()
                    removeAutoHideTimer()
                    syncScrubber()
                    break

                case .readyToPlay:
                    // Play from playbackSyncStartTime
                    if playbackSyncStartTime > 1 && !hasSeekedToPlaybackSyncStartTime {
                        if !isSeeking {
                            seekPlayer(to: playbackSyncStartTime)
                        }
                    } else {
                        // Start from either beginning or from wherever left off
                        hasSeekedToPlaybackSyncStartTime = true
                        if !isPlaying {
                            playVideo()
                        }
                    }

                    // Hide activity indicator
                    activityIndicatorVisible = false

                    // Enable (not show) controls
                    playerControlsEnabled = true

                    // Scrubber timer
                    initScrubberTimer()
                    break

                case .videoPlaying:
                    // Hide activity indicator
                    activityIndicatorVisible = false

                    // Enable (not show) controls
                    playerControlsEnabled = true

                    // Auto Hide Timer
                    initAutoHideTimer()

                    if isCastingActive {
                        // Scrubber timer
                        initScrubberTimer()
                    }
                    break

                case .videoPaused:
                    // Hide activity indicator
                    activityIndicatorVisible = false

                    // Enable (not show) controls
                    playerControlsEnabled = true
                    break

                case .videoSeeking, .videoLoading:
                    // Show activity indicator
                    activityIndicatorVisible = true
                    break

                default:
                    break
                }

                NotificationCenter.default.post(name: .videoPlayerPlaybackStateDidChange, object: self)
            }
        }
    }

    private var isPlaying: Bool {
        return (
            previousScrubbingRate != 0 ||
            (player != nil && player!.rate != 0) ||
            (isCastingActive && CastManager.sharedInstance.isPlaying)
        )
    }

    private var isPlaybackLikelyToKeepUp: Bool {
        return (player?.currentItem?.isPlaybackLikelyToKeepUp ?? false)
    }

    private var isPlaybackBufferEmpty: Bool {
        return (player?.currentItem?.isPlaybackBufferEmpty ?? false)
    }

    var screenGrab: UIImage? {
        if let playerItem = player?.currentItem, let cvPixelBuffer = (playerItem.outputs.first as? AVPlayerItemVideoOutput)?.copyPixelBuffer(forItemTime: playerItem.currentTime(), itemTimeForDisplay: nil) {
            return UIImage(ciImage: CIImage(cvPixelBuffer: cvPixelBuffer))
        }

        return nil
    }

    // Asset
    var url: URL? {
        return (player?.currentItem?.asset as? AVURLAsset)?.url
    }

    // Playback Views
    @IBOutlet weak private var playbackView: VideoPlayerPlaybackView!
    @IBOutlet weak private var playbackOverlayView: UIView!
    @IBOutlet weak private var playbackOverlayImageView: UIImageView!
    @IBOutlet weak private var playbackOverlayLabel: UILabel!
    private var playbackOverlayTimedEvent: TimedEvent?
    private var nowPlayingInfoImage: UIImage?
    private var nowPlayingInfoTimedEvent: TimedEvent? {
        didSet {
            if let imageURL = nowPlayingInfoTimedEvent?.thumbnailImageURL {
                SDWebImageDownloader.shared().downloadImage(with: imageURL, options: .lowPriority, progress: nil, completed: { [weak self] (image, _, _, _) in
                    self?.nowPlayingInfoImage = image
                })
            } else {
                nowPlayingInfoImage = nil
            }
        }
    }

    // Controls
    @IBOutlet weak public var topToolbar: UIView?
    @IBOutlet weak fileprivate var commentaryButton: UIButton?
    @IBOutlet weak fileprivate var captionsButton: UIButton?
    @IBOutlet weak private var airPlayButton: AirPlayButton?
    @IBOutlet weak private var castButtonContainerView: UIView?
    private var castButton: UIButton?
    @IBOutlet weak private var playbackToolbar: UIView?
    @IBOutlet weak private var homeButton: UIButton?
    @IBOutlet weak private var scrubber: UISlider?
    @IBOutlet weak private var timeElapsedLabel: UILabel?
    @IBOutlet weak private var durationLabel: UILabel?
    @IBOutlet weak private var cropToActivePictureButton: UIButton?
    @IBOutlet weak private var playButton: UIButton?
    @IBOutlet weak private var pauseButton: UIButton?
    @IBOutlet weak fileprivate var pictureInPictureButton: UIButton?
    @IBOutlet weak var fullScreenButton: UIButton?
    private var previousScrubbingRate: Float = 0

    @IBOutlet private var airPlayTrailingToCropToActivePictureConstraint: NSLayoutConstraint?
    @IBOutlet private var castTrailingToAirPlayConstraint: NSLayoutConstraint?
    @IBOutlet private var castTrailingToCropToActivePictureConstraint: NSLayoutConstraint?
    @IBOutlet private var commentaryTrailingToCastConstraint: NSLayoutConstraint?
    @IBOutlet private var commentaryTrailingToAirPlayConstraint: NSLayoutConstraint?
    @IBOutlet private var commentaryTrailingToCropToActivePictureConstraint: NSLayoutConstraint?

    private var playerControlsAutoHideTimer: Timer?

    private var isScrubbing: Bool {
        return (previousScrubbingRate != 0)
    }

    fileprivate var playerControlsEnabled = false {
        didSet {
            timeElapsedLabel?.isEnabled = playerControlsEnabled
            scrubber?.isEnabled = playerControlsEnabled
            durationLabel?.isEnabled = playerControlsEnabled
            playButton?.isEnabled = playerControlsEnabled
            pauseButton?.isEnabled = playerControlsEnabled
            commentaryButton?.isEnabled = (playerControlsEnabled && !isCastingActive)
            captionsButton?.isEnabled = (playerControlsEnabled && (captionsSelectionGroup != nil || ((CastManager.sharedInstance.currentTextTracks?.count ?? 0) > 0)))
            cropToActivePictureButton?.isEnabled = (playerControlsEnabled && !isExternalPlaybackActive && !isPictureInPictureActive)
            pictureInPictureButton?.isEnabled = (playerControlsEnabled && !isPictureInPictureActive)
            fullScreenButton?.isEnabled = playerControlsEnabled

            MPRemoteCommandCenter.shared().playCommand.isEnabled = (playerControlsEnabled && !isCastingActive)
            MPRemoteCommandCenter.shared().pauseCommand.isEnabled = (playerControlsEnabled && !isCastingActive)
            MPRemoteCommandCenter.shared().togglePlayPauseCommand.isEnabled = (playerControlsEnabled && !isCastingActive)
            MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = playerControlsEnabled
            MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = playerControlsEnabled
        }
    }

    private var playerControlsVisible = false {
        didSet {
            if let topToolbar = topToolbar {
                if playerControlsVisible {
                    topToolbar.isHidden = false
                    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                        topToolbar.transform = .identity
                    })
                } else {
                    audioOptionsVisible = false
                    captionsOptionsVisible = false
                    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                        topToolbar.transform = CGAffineTransform(translationX: 0, y: -topToolbar.bounds.height)
                    }, completion: { (_) in
                        topToolbar.isHidden = true
                    })
                }
            }

            if let playbackToolbar = playbackToolbar {
                if playerControlsVisible {
                    playbackToolbar.isHidden = false
                    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                        playbackToolbar.transform = .identity
                    })
                } else {
                    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                        playbackToolbar.transform = CGAffineTransform(translationX: 0, y: playbackToolbar.bounds.height)
                    }, completion: { (_) in
                        playbackToolbar.isHidden = true
                    })
                }
            }
        }
    }

    private var playerControlsLocked = false {
        didSet {
            if playerControlsLocked {
                topToolbar?.isHidden = true
                playbackToolbar?.isHidden = true
            }
        }
    }

    private var activityIndicator: MBProgressHUD?
    var activityIndicatorDisabled = false
    private var activityIndicatorVisible = false {
        didSet {
            if activityIndicatorVisible && !activityIndicatorDisabled {
                if activityIndicator == nil {
                    activityIndicator = MBProgressHUD.showAdded(to: (isExternalPlaybackActive ? playbackOverlayView : playbackView), animated: true)
                }
            } else {
                activityIndicator?.hide(true)
                activityIndicator = nil
            }
        }
    }

    // Captions
    @IBOutlet fileprivate var captionsOptionsTableView: UITableView?
    private var captionsOptionsVisible = false {
        didSet {
            captionsButton?.isHighlighted = captionsOptionsVisible
            if let captionsOptionsTableView = captionsOptionsTableView {
                if captionsOptionsVisible && captionsOptionsTableView.isHidden {
                    removeAutoHideTimer()
                    captionsOptionsTableView.alpha = 0
                    captionsOptionsTableView.isHidden = false
                    UIView.animate(withDuration: 0.2, animations: {
                        captionsOptionsTableView.alpha = 1
                    })
                } else if !captionsOptionsTableView.isHidden {
                    initAutoHideTimer()
                    UIView.animate(withDuration: 0.2, animations: {
                        captionsOptionsTableView.alpha = 0
                    }, completion: { (_) in
                        captionsOptionsTableView.isHidden = true
                    })
                }
            }
        }
    }

    fileprivate var captionsSelectionGroup: AVMediaSelectionGroup?
    fileprivate var currentCaptionsSelectionIndex = 0 {
        didSet {
            let captionsEnabled = (currentCaptionsSelectionIndex > 0)
            if let group = captionsSelectionGroup {
                if captionsEnabled && group.options.count > (currentCaptionsSelectionIndex - 1) {
                    player?.currentItem?.select(group.options[currentCaptionsSelectionIndex - 1], in: group)
                } else {
                    player?.currentItem?.select(nil, in: group)
                }
            } else if let textTracks = CastManager.sharedInstance.currentTextTracks {
                if captionsEnabled && textTracks.count > (currentCaptionsSelectionIndex - 1) {
                    CastManager.sharedInstance.selectTextTrack(withIdentifier: textTracks[currentCaptionsSelectionIndex - 1].identifier)
                } else {
                    CastManager.sharedInstance.disableTextTracks()
                }
            }

            captionsButton?.isSelected = captionsEnabled
            captionsOptionsTableView?.selectRow(at: IndexPath(row: currentCaptionsSelectionIndex, section: 0), animated: false, scrollPosition: .none)
        }
    }

    // Audio (Commentary)
    @IBOutlet fileprivate var audioOptionsTableView: UITableView?
    private var audioOptionsVisible = false {
        didSet {
            commentaryButton?.isHighlighted = audioOptionsVisible
            if let audioOptionsTableView = audioOptionsTableView {
                if audioOptionsVisible && audioOptionsTableView.isHidden {
                    removeAutoHideTimer()
                    audioOptionsTableView.alpha = 0
                    audioOptionsTableView.isHidden = false
                    UIView.animate(withDuration: 0.2, animations: {
                        audioOptionsTableView.alpha = 1
                    })
                } else if !audioOptionsTableView.isHidden {
                    initAutoHideTimer()
                    UIView.animate(withDuration: 0.2, animations: {
                        audioOptionsTableView.alpha = 0
                    }, completion: { (_) in
                        audioOptionsTableView.isHidden = true
                    })
                }
            }
        }
    }

    fileprivate var audioSelectionGroup: AVMediaSelectionGroup?
    fileprivate var mainAudioSelectionOption: AVMediaSelectionOption?
    fileprivate var commentaryAudioSelectionOption: AVMediaSelectionOption?

    // Picture-in-Picture
    fileprivate var pictureInPictureController: Any?

    private var isPictureInPictureActive: Bool {
        if #available(iOS 9.0, *) {
            if let pictureInPictureController = pictureInPictureController as? AVPictureInPictureController {
                return pictureInPictureController.isPictureInPictureActive
            }
        }

        return false
    }

    private var isPictureInPicturePossible: Bool {
        if #available(iOS 9.0, *) {
            if let pictureInPictureController = pictureInPictureController as? AVPictureInPictureController {
                return pictureInPictureController.isPictureInPicturePossible
            }
        }

        return false
    }

    // AirPlay & Casting
    private var availableWirelessRoutesDidChangeObserver: NSObjectProtocol?

    private var isAirPlayActive = false {
        didSet {
            isExternalPlaybackActive = isAirPlayActive
            ExternalPlaybackManager.isAirPlayActive = isAirPlayActive

            if isAirPlayActive != oldValue {
                DispatchQueue.main.async {
                    self.airPlayButton?.tintColor = (self.isAirPlayActive ? UIColor.themePrimary : UIColor.white)
                    self.castButton?.isEnabled = !self.isAirPlayActive
                }

                if isAirPlayActive {
                    logEvent(action: .airPlayOn)
                }
            }
        }
    }

    fileprivate var isCastingActive = false {
        didSet {
            isExternalPlaybackActive = isCastingActive
            commentaryButton?.isEnabled = !isCastingActive
            airPlayButton?.tintColor = (isCastingActive ? UIColor.gray : UIColor.white)
            airPlayButton?.isUserInteractionEnabled = !isCastingActive

            if isCastingActive != oldValue, isCastingActive {
                logEvent(action: .chromecastOn)
            }
        }
    }

    fileprivate var isExternalPlaybackActive = false {
        didSet {
            if isExternalPlaybackActive != oldValue && mode != .basicPlayer {
                DispatchQueue.main.async {
                    if self.isExternalPlaybackActive {
                        self.cropToActivePictureButton?.isEnabled = false

                        self.playbackOverlayView.alpha = 0
                        self.playbackOverlayView.isHidden = false
                        self.playbackOverlayView.layer.removeAllAnimations()

                        UIView.animate(withDuration: 0.2, animations: {
                            self.playbackOverlayView.alpha = 1
                        })

                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
                            self.currentCaptionsSelectionIndex = self.currentCaptionsSelectionIndex
                        }
                    } else {
                        self.cropToActivePictureButton?.isEnabled = self.playerControlsEnabled
                        self.playbackOverlayView.layer.removeAllAnimations()

                        UIView.animate(withDuration: 0.2, animations: {
                            self.playbackOverlayView.alpha = 0
                        }, completion: { (_) in
                            self.playbackOverlayView.isHidden = true
                        })
                    }
                }
            }
        }
    }

    // Playback Sync
    private var playbackSyncStartTime: Double = 0
    private var hasSeekedToPlaybackSyncStartTime = false

    private var isFullScreen = false {
        didSet {
            fullScreenButton?.setImage(UIImage(named: (isFullScreen ? "Minimize" : "Maximize"), in: Bundle.frameworkResources, compatibleWith: nil), for: .normal)
            fullScreenButton?.setImage(UIImage(named: (isFullScreen ? "Minimize Highlighted" : "Maximize Highlighted"), in: Bundle.frameworkResources, compatibleWith: nil), for: .highlighted)

            if isFullScreen {
                originalContainerView = self.view.superview
                UIApplication.shared.keyWindow?.addSubview(self.view)
            } else {
                originalContainerView?.addSubview(self.view)
                originalContainerView = nil
            }

            if let bounds = self.view.superview?.bounds {
                self.view.frame = bounds
            }

            NotificationCenter.default.post(name: .videoPlayerDidToggleFullScreen, object: nil, userInfo: [NotificationConstants.isFullScreen: isFullScreen])
        }
    }

    var playerItemDuration: Double = 0 {
        didSet {
            if !playerItemDuration.isFinite {
                playerItemDuration = 0
                return
            }

            durationLabel?.text = timeString(fromSeconds: playerItemDuration)

            if !didPlayInterstitial && playerItemDuration != oldValue && playerItemDuration > 1 {
                countdownDurationDidLoad()
            }

            playbackAsset?.assetPlaybackDuration = playerItemDuration
        }
    }

    var currentTime: Double {
        if isCastingActive {
            return CastManager.sharedInstance.currentTime
        }

        if let seconds = player?.currentItem?.currentTime().seconds, !seconds.isNaN, seconds.isFinite {
            return max(seconds, 0)
        }

        return 0
    }

    // Countdown/Queue
    var queueTotalCount = 0
    var queueCurrentIndex = 0
    private var countdownSeconds: CGFloat = 0 {
        didSet {
            countdownLabel.text = String.localize("label.time.seconds", variables: ["count": String(Int(Constants.CountdownTotalTime - countdownSeconds))])
            countdownProgressView?.setProgress(((countdownSeconds + 1) / Constants.CountdownTotalTime), animated: true)
        }
    }

    private var countdownTimer: Timer?
    private var countdownProgressView: UAProgressView?
    @IBOutlet weak private var countdownLabel: UILabel!

    // Skip interstitial
    @IBOutlet weak private var skipContainerView: UIView!
    @IBOutlet weak private var skipCountdownContainerView: UIView!
    @IBOutlet private var skipContainerLandscapeHeightConstraint: NSLayoutConstraint?
    @IBOutlet private var skipContainerPortraitHeightConstraint: NSLayoutConstraint?

    // Notifications & Observers
    private var applicationWillResignActiveObserver: NSObjectProtocol?
    private var applicationWillEnterForegroundObserver: NSObjectProtocol?
    private var videoPlayerDidPlayVideoObserver: NSObjectProtocol?
    private var videoPlayerShouldPauseObserver: NSObjectProtocol?
    private var videoPlayerCanResumeObserver: NSObjectProtocol?
    private var playerTimeObserver: Any?

    deinit {
        destroyPlayer()
    }

    fileprivate func destroyAVPlayer() {
        // Stop controls
        if #available(iOS 9.0, *) {
            (pictureInPictureController as? AVPictureInPictureController)?.stopPictureInPicture()
        }

        // Remove observers
        let center = NotificationCenter.default

        if let observer = applicationWillResignActiveObserver {
            center.removeObserver(observer)
            applicationWillResignActiveObserver = nil
        }

        if let observer = applicationWillEnterForegroundObserver {
            center.removeObserver(observer)
            applicationWillEnterForegroundObserver = nil
        }

        if let observer = videoPlayerDidPlayVideoObserver {
            center.removeObserver(observer)
            videoPlayerDidPlayVideoObserver = nil
        }

        if let observer = videoPlayerShouldPauseObserver {
            center.removeObserver(observer)
            videoPlayerShouldPauseObserver = nil
        }

        if let observer = videoPlayerCanResumeObserver {
            center.removeObserver(observer)
            videoPlayerCanResumeObserver = nil
        }

        if let player = player {
            if let playerItem = player.currentItem {
                NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            }

            player.removeObserver(self, forKeyPath: Constants.Keys.CurrentItemStatus)
            player.removeObserver(self, forKeyPath: Constants.Keys.CurrentItemDuration)
            player.removeObserver(self, forKeyPath: Constants.Keys.CurrentItemPlaybackBufferEmpty)
            player.removeObserver(self, forKeyPath: Constants.Keys.CurrentItemPlaybackLikelyToKeepUp)
            player.removeObserver(self, forKeyPath: Constants.Keys.CurrentItemPresentationSize)
            player.removeObserver(self, forKeyPath: Constants.Keys.CurrentItem)
            player.removeObserver(self, forKeyPath: Constants.Keys.Rate)
            player.removeObserver(self, forKeyPath: Constants.Keys.ExternalPlaybackActive)
        }

        removeCurrentItem()

        // Nullify stored objects
        previousScrubbingRate = 0
        captionsSelectionGroup = nil
        audioSelectionGroup = nil
        mainAudioSelectionOption = nil
        commentaryAudioSelectionOption = nil
        playerItemVideoOutput = nil
        player = nil
    }

    private func destroyPlayer() {
        destroyAVPlayer()

        // Remove timers
        removePlayerTimeObserver()
        removeAutoHideTimer()
        cancelCountdown()

        // Remove observers
        if let observer = availableWirelessRoutesDidChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            availableWirelessRoutesDidChangeObserver = nil
        }

        CastManager.sharedInstance.remove(discoveryManagerListener: self)
        CastManager.sharedInstance.remove(sessionManagerListener: self)
        CastManager.sharedInstance.remove(remoteMediaClientListener: self)

        // Nullify stored objects
        airPlayButton = nil
        playbackAsset = nil
    }

    func removeCurrentItem() {
        player?.replaceCurrentItem(with: nil)
        state = .unknown
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        // Setup audio to be heard even if device is on silent
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            print("Error setting AVAudioSession category: \(error)")
        }

        // Notifications
        if mode == .mainFeature {
            videoPlayerCanResumeObserver = NotificationCenter.default.addObserver(forName: .videoPlayerCanResume, object: nil, queue: OperationQueue.main, using: { [weak self] (_) in
                if let strongSelf = self, !strongSelf.isManuallyPaused {
                    strongSelf.playVideo()
                }
            })
        } else if mode == .basicPlayer {
            applicationWillEnterForegroundObserver = NotificationCenter.default.addObserver(forName: .applicationWillEnterForeground, object: nil, queue: OperationQueue.main, using: { [weak self] (_) in
                self?.playVideo()
            })
        }

        applicationWillResignActiveObserver = NotificationCenter.default.addObserver(forName: .applicationWillResignActive, object: nil, queue: OperationQueue.main, using: { [weak self] (_) in
            if let strongSelf = self, !strongSelf.isExternalPlaybackActive {
                if #available(iOS 9.0, *) {
                    if strongSelf.mode != .mainFeature || !AVPictureInPictureController.isPictureInPictureSupported() {
                        strongSelf.pauseVideo()
                    }
                } else {
                    strongSelf.pauseVideo()
                }
            }
        })

        videoPlayerDidPlayVideoObserver = NotificationCenter.default.addObserver(forName: .videoPlayerDidPlayVideo, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
            if let strongSelf = self, strongSelf.didPlayInterstitial, !strongSelf.isExternalPlaybackActive {
                if let videoURL = notification.userInfo?[NotificationConstants.videoUrl] as? URL, videoURL != strongSelf.url {
                    strongSelf.pauseVideo()
                }
            }
        })

        videoPlayerShouldPauseObserver = NotificationCenter.default.addObserver(forName: .videoPlayerShouldPause, object: nil, queue: OperationQueue.main, using: { [weak self] (_) in
            if let strongSelf = self, !strongSelf.isExternalPlaybackActive {
                strongSelf.pauseVideo()
            }
        })

        MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] (_) -> MPRemoteCommandHandlerStatus in
            if let strongSelf = self {
                strongSelf.onPlay(sender: nil)
                strongSelf.logEvent(action: .remotePlayButton)
                return .success
            }

            return .commandFailed
        }

        MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] (_) -> MPRemoteCommandHandlerStatus in
            if let strongSelf = self {
                strongSelf.onPause(sender: nil)
                strongSelf.logEvent(action: .remotePauseButton)
                return .success
            }

            return .commandFailed
        }

        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget { [weak self] (_) -> MPRemoteCommandHandlerStatus in
            if let strongSelf = self {
                if strongSelf.isPlaying {
                    strongSelf.onPause(sender: nil)
                } else {
                    strongSelf.onPlay(sender: nil)
                }

                strongSelf.logEvent(action: .remoteTogglePlayPauseButton)
                return .success
            }

            return .commandFailed
        }

        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            if let strongSelf = self, let event = event as? MPSkipIntervalCommandEvent {
                strongSelf.seekPlayer(to: strongSelf.currentTime - event.interval)
                strongSelf.logEvent(action: .remoteSkipBackButton)
                return .success
            }

            return .commandFailed
        }

        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            if let strongSelf = self, let event = event as? MPSkipIntervalCommandEvent {
                strongSelf.seekPlayer(to: strongSelf.currentTime + event.interval)
                strongSelf.logEvent(action: .remoteSkipForwardButton)
                return .success
            }

            return .commandFailed
        }

        updateToolbarButtons()

        if mode == .basicPlayer {
            playbackView.isCroppingToActivePicture = true
            didPlayInterstitial = true
            playerControlsVisible = false
        } else {
            if mode != .supplementalInMovie {
                CastManager.sharedInstance.add(discoveryManagerListener: self)
                CastManager.sharedInstance.add(sessionManagerListener: self)
            }

            isSeeking = false
            initScrubberTimer()
            syncPlayPauseButtons()
            syncScrubber()

            skipContainerView.isHidden = true
            skipContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapSkip)))

            // Localizations
            homeButton?.setTitle(String.localize("label.home"), for: .normal)
            commentaryButton?.setTitle(String.localize("label.commentary"), for: .normal)
            commentaryButton?.setTitle(String.localize("label.commentary_on"), for: .selected)
            commentaryButton?.setTitle(String.localize("label.commentary_on"), for: [.selected, .highlighted])
            playbackOverlayLabel.text = String.localize("player.message.external.playing").uppercased()

            // View setup
            captionsButton?.setImage(UIImage(named: "ClosedCaptions-Highlighted", in: Bundle.frameworkResources, compatibleWith: nil), for: [.selected, .highlighted])
            commentaryButton?.setImage(UIImage(named: "Commentary-Highlighted", in: Bundle.frameworkResources, compatibleWith: nil), for: [.selected, .highlighted])
            commentaryButton?.setTitleColor(UIColor.themePrimary, for: [.selected, .highlighted])

            if CastManager.sharedInstance.isInitialized, let containerView = castButtonContainerView {
                castButton = GCKUICastButton(frame: containerView.bounds)
                castButton!.tintColor = UIColor.white
                containerView.addSubview(castButton!)
            } else {
                castButtonContainerView?.removeFromSuperview()
            }

            airPlayButton?.tintColor = UIColor.white
            availableWirelessRoutesDidChangeObserver = NotificationCenter.default.addObserver(forName: .availableWirelessRoutesDidChange, object: nil, queue: OperationQueue.main, using: { [weak self] (_) in
                self?.updateToolbarButtons()
            })

            let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onSingleTapPlayer))
            singleTapGestureRecognizer.numberOfTapsRequired = 1
            playbackView.addGestureRecognizer(singleTapGestureRecognizer)

            let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onDoubleTapPlayer))
            doubleTapGestureRecognizer.numberOfTapsRequired = 2
            playbackView.addGestureRecognizer(doubleTapGestureRecognizer)

            if mode == .mainFeature {
                audioOptionsTableView?.register(UINib(nibName: DropdownTableViewCell.NibName, bundle: Bundle.frameworkResources), forCellReuseIdentifier: DropdownTableViewCell.ReuseIdentifier)
                captionsOptionsTableView?.register(UINib(nibName: DropdownTableViewCell.NibName, bundle: Bundle.frameworkResources), forCellReuseIdentifier: DropdownTableViewCell.ReuseIdentifier)

                // Picture-in-Picture setup
                if #available(iOS 10.0, *) {
                    if AVPictureInPictureController.isPictureInPictureSupported(), let playerLayer = playbackView.playerLayer {
                        pictureInPictureController = AVPictureInPictureController(playerLayer: playerLayer)
                        (pictureInPictureController as? AVPictureInPictureController)?.delegate = self
                    } else {
                        pictureInPictureButton?.removeFromSuperview()
                    }
                } else {
                    pictureInPictureButton?.removeFromSuperview()
                }

                if let delegate = ExperienceLauncher.delegate {
                    didPlayInterstitial = SettingsManager.didWatchInterstitial && !delegate.interstitialShouldPlayMultipleTimes()
                }

                playMainExperience()
            } else {
                didPlayInterstitial = true
                playerControlsVisible = false
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !isManuallyPaused {
            playVideo()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if didPlayInterstitial {
            playerControlsVisible = true
            initAutoHideTimer()
            coordinator.animate(alongsideTransition: nil, completion: { (_) in
                self.updateToolbarButtons()
            })
        } else {
            countdownProgressView?.frame = skipCountdownContainerView.frame
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if !didPlayInterstitial {
            let currentOrientation = UIApplication.shared.statusBarOrientation
            skipContainerLandscapeHeightConstraint?.isActive = UIInterfaceOrientationIsLandscape(currentOrientation)
            skipContainerPortraitHeightConstraint?.isActive = UIInterfaceOrientationIsPortrait(currentOrientation)
            countdownProgressView?.frame = skipCountdownContainerView.frame
        }
    }

    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)

        if parent == nil && !isCastingActive {
            pauseVideo()
        }
    }

    private func setViewDisplayName() {
        /* If the item has a AVMetadataCommonKeyTitle metadata, use that instead. */
        if let items = player?.currentItem?.asset.commonMetadata {
            for item in items {
                if item.commonKey == AVMetadataCommonKeyTitle {
                    self.title = item.stringValue
                    return
                }
            }
        }

        /* Or set the view title to the last component of the asset URL. */
        self.title = url?.lastPathComponent
    }

    fileprivate func updateToolbarButtons() {
        if mode == .mainFeature {
            fullScreenButton?.removeFromSuperview()
        } else {
            audioOptionsTableView?.removeFromSuperview()
            captionsOptionsTableView?.removeFromSuperview()
            commentaryTrailingToCastConstraint = nil
            commentaryTrailingToAirPlayConstraint = nil
            commentaryTrailingToCropToActivePictureConstraint = nil

            if mode == .basicPlayer {
                topToolbar?.removeFromSuperview()
                playbackToolbar?.removeFromSuperview()
                airPlayTrailingToCropToActivePictureConstraint = nil
                castTrailingToAirPlayConstraint = nil
                castTrailingToCropToActivePictureConstraint = nil
            } else {
                commentaryButton?.removeFromSuperview()
                captionsButton?.removeFromSuperview()
                pictureInPictureButton?.removeFromSuperview()
                homeButton?.removeFromSuperview()

                if mode == .supplementalInMovie {
                    fullScreenButton?.removeFromSuperview()
                    castButtonContainerView?.removeFromSuperview()
                    airPlayButton?.removeFromSuperview()
                    airPlayTrailingToCropToActivePictureConstraint = nil
                    castTrailingToAirPlayConstraint = nil
                    castTrailingToCropToActivePictureConstraint = nil
                }
            }
        }

        var canCropToActivePicture = false
        if mode != .basicPlayer, let presentationSize = player?.currentItem?.presentationSize, presentationSize != CGSize.zero {
            let roundedPresentationAspectRatio = (((presentationSize.width / presentationSize.height) * 100).rounded() / 100.0)
            let roundedPlaybackViewAspectRatio = (((playbackView.frame.size.width / playbackView.frame.size.height) * 100).rounded() / 100.0)
            canCropToActivePicture = (roundedPresentationAspectRatio != roundedPlaybackViewAspectRatio)
        }

        let canAirPlay = (airPlayButton != nil && airPlayButton!.areWirelessRoutesAvailable)
        let canCast = CastManager.sharedInstance.hasDiscoveredDevices
        let canEnableCommentary = (commentaryAudioSelectionOption != nil)

        cropToActivePictureButton?.isHidden = !canCropToActivePicture
        airPlayButton?.isHidden = !canAirPlay
        castButtonContainerView?.isHidden = !canCast
        commentaryButton?.isHidden = !canEnableCommentary

        airPlayTrailingToCropToActivePictureConstraint?.isActive = (canAirPlay && canCropToActivePicture)
        castTrailingToAirPlayConstraint?.isActive = (canCast && canAirPlay)
        castTrailingToCropToActivePictureConstraint?.isActive = (canCast && !canAirPlay && canCropToActivePicture)
        commentaryTrailingToCastConstraint?.isActive = (canEnableCommentary && canCast)
        commentaryTrailingToAirPlayConstraint?.isActive = (canEnableCommentary && !canCast && canAirPlay)
        commentaryTrailingToCropToActivePictureConstraint?.isActive = (canEnableCommentary && !canCast && !canAirPlay && canCropToActivePicture)
    }

    private func display(error: NSError) {
        let alertController = UIAlertController(title: "", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    // MARK: Video Playback
    /* ---------------------------------------------------------
     **  Called when the value at the specified key path relative
     **  to the given object has changed.
     **  Adjust the movie play and pause button controls when the
     **  player item "status" value changes. Update the movie
     **  scrubber control when the player item is ready to play.
     **  Adjust the movie scrubber control when the player item
     **  "rate" value changes. For updates of the player
     **  "currentItem" property, set the AVPlayer for which the
     **  player layer displays visual output.
     **  NOTE: this method is invoked on the main queue.
     ** ------------------------------------------------------- */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        /* AVPlayerItem "status" property value observer. */
        if context == &ObservationContexts.Status {
            if let statusNumber = (change?[NSKeyValueChangeKey.newKey] as? NSNumber)?.intValue, let status = AVPlayerStatus(rawValue: statusNumber) {
                switch status {
                    /* Indicates that the status of the player is not yet known because
                     it has not tried to load new media resources for playback */
                case .unknown:
                    state = .unknown
                    break

                case .readyToPlay:
                    /* Once the AVPlayerItem becomes ready to play, i.e.
                     [playerItem status] == AVPlayerItemStatusReadyToPlay,
                     its duration can be fetched from the item. */

                    if state != .videoPlaying {
                        state = .readyToPlay
                        NotificationCenter.default.post(name: .videoPlayerItemReadyToPlayer, object: nil)
                    }
                    break

                case .failed:
                    if let error = (object as? AVPlayerItem)?.error as NSError? {
                        assetFailedToPrepareForPlayback(error: error)
                    }
                    break
                }
            }
        }
        // AVPlayer "duration" property value observer
        else if context == &ObservationContexts.Duration {
            if let duration = player?.currentItem?.duration.seconds {
                playerItemDuration = duration
            }
        }
        /* AVPlayer "rate" property value observer. */
        else if context == &ObservationContexts.Rate {
            if let newRate = change?[NSKeyValueChangeKey.newKey] as? Bool, newRate {
                state = .videoPlaying
            } else {
                state = .videoPaused
            }
        }
        /* AVPlayer "externalPlaybackActive" propertly value observer. */
        else if context == &ObservationContexts.ExternalPlayback {
            if player != nil && player!.allowsExternalPlayback, let isAirPlayActive = change?[NSKeyValueChangeKey.newKey] as? Bool {
                self.isAirPlayActive = isAirPlayActive
            }
        }
        /* AVPlayer "currentItem" property observer.
         Called when the AVPlayer replaceCurrentItemWithPlayerItem:
         replacement will/did occur. */
        else if context == &ObservationContexts.CurrentItem {
            /* Replacement of player currentItem has occurred */
            if (change?[NSKeyValueChangeKey.newKey] as? AVPlayerItem) != nil {
                /* Set the AVPlayer for which the player layer displays visual output. */
                playbackView.player = player
                setViewDisplayName()
                selectInitialCaptions()
            } else {
                playerControlsEnabled = false
            }
        } else if context == &ObservationContexts.BufferEmpty {
            state = .videoLoading
            if isPlaybackBufferEmpty && currentTime > 0 && currentTime < (playerItemDuration - 1) && isPlaying {
                NotificationCenter.default.post(name: .videoPlayerPlaybackBufferEmpty, object: nil)
            }
        } else if context == &ObservationContexts.PlaybackLikelyToKeepUp {
            if state != .videoPaused && !isPlaying && isPlaybackLikelyToKeepUp {
                NotificationCenter.default.post(name: .videoPlayerPlaybackLikelyToKeepUp, object: nil)

                if !isSeeking && hasSeekedToPlaybackSyncStartTime {
                    playVideo()
                }
            }
        } else if context == &ObservationContexts.PresentationSize {
            updateToolbarButtons()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }

        syncPlayPauseButtons()

        if mode == .basicPlayer {
            player?.actionAtItemEnd = .none
        }
    }

    /* --------------------------------------------------------------
     **  Called when an asset fails to prepare for playback for any of
     **  the following reasons:
     **
     **  1) values of asset keys did not load successfully,
     **  2) the asset keys did load successfully, but the asset is not
     **     playable
     **  3) the item did not become ready to play.
     ** ----------------------------------------------------------- */
    private func assetFailedToPrepareForPlayback(error: NSError?) {
        state = .error
        removePlayerTimeObserver()
        removeAutoHideTimer()
        syncScrubber()
        playerControlsEnabled = false

        print("Asset failed to prepare for playback with error: \(error?.localizedDescription ?? "Unknown error")")

        if let error = error {
            display(error: error)
        }
    }

    /*
     Invoked at the completion of the loading of the values for all keys on the asset that we require.
     Checks whether loading was successfull and whether the asset is playable.
     If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
     */
    private func prepareToPlay(asset: AVURLAsset, withKeys keys: [String]? = nil) {
        state = .videoLoading

        /* Make sure that the value of each key has loaded successfully. */
        if let keys = keys {
            for key in keys {
                let error: NSErrorPointer = nil
                let status = asset.statusOfValue(forKey: key, error: error)
                if status == .failed {
                    assetFailedToPrepareForPlayback(error: error?.pointee)
                    return
                }
            }
        }

        /* Use the AVAsset playable property to detect whether the asset can be played. */
        if !asset.isPlayable {
            /* Generate and show an error describing the failure. */
            let errorDict = [NSLocalizedDescriptionKey: NSLocalizedString("player-generalError", comment: "Error"), NSLocalizedFailureReasonErrorKey: NSLocalizedString("player-asset-tracks-load-error", comment: "Can't load tracks")]
            assetFailedToPrepareForPlayback(error: NSError(domain: "VideoPlayer", code: 0, userInfo: errorDict))
            return
        }

        // At this point we're ready to set up for playback of the asset.

        // Create a new instance of AVPlayerItem from the now successfully loaded AVAsset.
        let playerItem = AVPlayerItem(asset: asset)

        /* When the player item has played to its end time we'll toggle
         the movie controller Pause button to be the Play button */
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)

        // Set up the captions options
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicLegible), group.options.first(where: { $0.locale != nil }) != nil {
            captionsSelectionGroup = group
            captionsButton?.isEnabled = true
            captionsOptionsTableView?.reloadData()
        } else {
            captionsButton?.isEnabled = false
        }

        // Set up commentary options
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicAudible), let option = group.options.first(where: { $0.displayName.lowercased().contains("commentary") }) {
            audioSelectionGroup = group
            mainAudioSelectionOption = group.options.first
            commentaryAudioSelectionOption = option
            audioOptionsTableView?.reloadData()
            audioOptionsTableView?.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        }

        updateToolbarButtons()

        // Set up AirPlay support
        let airPlayEnabled = (mode != .basicPlayer && mode != .supplementalInMovie && didPlayInterstitial)

        /* Create new player, if we don't already have one. */
        if player == nil {
            /* Get a new AVPlayer initialized to play the specified player item. */
            player = AVPlayer(playerItem: playerItem)
            player!.allowsExternalPlayback = airPlayEnabled

            /* Observe the AVPlayer "currentItem" property to find out when any
             AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did occur.*/
            player!.addObserver(self, forKeyPath: Constants.Keys.CurrentItem, options: [.initial, .new], context: &ObservationContexts.CurrentItem)

            /* Observe the AVPlayer "rate" property to update the scrubber control. */
            player!.addObserver(self, forKeyPath: Constants.Keys.Rate, options: [.initial, .new], context: &ObservationContexts.Rate)

            /* Observer the AVPlayer "externalPlaybackActive" property to update the UI when AirPlay connects or disconnects. */
            player!.addObserver(self, forKeyPath: Constants.Keys.ExternalPlaybackActive, options: [.initial, .new], context: &ObservationContexts.ExternalPlayback)

            player!.addObserver(self, forKeyPath: Constants.Keys.CurrentItemStatus, options: [.initial, .new], context: &ObservationContexts.Status)
            player!.addObserver(self, forKeyPath: Constants.Keys.CurrentItemDuration, options: [.initial, .new], context: &ObservationContexts.Duration)
            player!.addObserver(self, forKeyPath: Constants.Keys.CurrentItemPlaybackBufferEmpty, options: .new, context: &ObservationContexts.BufferEmpty)
            player!.addObserver(self, forKeyPath: Constants.Keys.CurrentItemPlaybackLikelyToKeepUp, options: .new, context: &ObservationContexts.PlaybackLikelyToKeepUp)
            player!.addObserver(self, forKeyPath: Constants.Keys.CurrentItemPresentationSize, options: .new, context: &ObservationContexts.PresentationSize)
        } else {
            player!.allowsExternalPlayback = airPlayEnabled
        }

        /* Make our new AVPlayerItem the AVPlayer's current item. */
        if player!.currentItem != playerItem {
            /* Replace the player item with a new player item. The item replacement occurs 
             asynchronously; observe the currentItem property to find out when the 
             replacement will/did occur
             
             If needed, configure player item here (example: adding outputs, setting text style rules,
             selecting media options) before associating it with a player
             */

            player!.replaceCurrentItem(with: playerItem)
        }

        playbackView.isCroppingToActivePicture = (mode == .basicPlayer || !didPlayInterstitial)
    }

    fileprivate func selectInitialCaptions() {
        captionsOptionsTableView?.reloadData()

        var selectedIndex = 0
        if UIAccessibilityIsClosedCaptioningEnabled() {
            if let index = captionsSelectionGroup?.options.index(where: { $0.locale?.identifier == Locale.current.identifier }) ?? captionsSelectionGroup?.options.index(where: { $0.locale?.identifier == Locale.current.identifier }) {
                selectedIndex = index + 1
            } else if let index = CastManager.sharedInstance.currentTextTracks?.index(where: { $0.languageCode != nil && Locale(identifier: $0.languageCode!).identifier == Locale.current.identifier }) {
                selectedIndex = index + 1
            }
        }

        currentCaptionsSelectionIndex = selectedIndex
    }

    private func playVideo() {
        isManuallyPaused = false

        var didPlay = false
        if isCastingActive && didPlayInterstitial {
            CastManager.sharedInstance.playMedia()
            didPlay = true
        } else if let player = player {
            player.play()
            didPlay = true
        }

        if didPlay {
            // Immediately show pause button. NOTE: syncPlayPauseButtons will actually update this
            // to reflect the playback "rate", e.g. 0.0 will automatically show the pause button.
            showPauseButton()

            // Send notification
            var userInfo: [AnyHashable: Any]? = nil
            if let url = url {
                userInfo = [NotificationConstants.videoUrl: url]
            }

            NotificationCenter.default.post(name: .videoPlayerDidPlayVideo, object: nil, userInfo: userInfo)
        }
    }

    public func pauseVideo() {
        // Pause media
        if isCastingActive {
            CastManager.sharedInstance.pauseMedia()
        } else {
            player?.pause()
        }

        // Immediately show play button. NOTE: syncPlayPauseButtons will actually update this
        // to reflect the playback "rate", e.g. 0.0 will automatically show the pause button.
        showPlayButton()
    }

    func playAsset(withURL url: URL, title: String? = nil, imageURL: URL? = nil, fromStartTime startTime: Double? = nil) {
        let sendToPlayer = { [weak self] (urlAsset: AVURLAsset) -> Void in
            self?.isCastingActive = false

            let requestedKeys = [Constants.Keys.Tracks, Constants.Keys.Playable]
            /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
            urlAsset.loadValuesAsynchronously(forKeys: requestedKeys) { [weak self] in
                /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                DispatchQueue.main.async {
                    self?.prepareToPlay(asset: urlAsset, withKeys: requestedKeys)
                }
            }
        }

        removeCurrentItem()
        cancelCountdown()
        playbackSyncStartTime = (startTime ?? 0)
        hasSeekedToPlaybackSyncStartTime = false

        if mode == .basicPlayer || !didPlayInterstitial {
            sendToPlayer(AVURLAsset(url: url))
        } else {
            ExperienceLauncher.delegate?.playbackAsset(withURL: url, title: title, imageURL: imageURL, forMode: mode, completion: { [weak self] (playbackAsset) in
                if let strongSelf = self {
                    strongSelf.playbackAsset = playbackAsset

                    if strongSelf.playbackSyncStartTime > 0 {
                        strongSelf.playbackAsset?.assetPlaybackPosition = strongSelf.playbackSyncStartTime
                    } else if let startTime = strongSelf.playbackAsset?.assetPlaybackPosition {
                        strongSelf.playbackSyncStartTime = startTime
                    }

                    if strongSelf.mode != .supplementalInMovie && CastManager.sharedInstance.hasConnectedCastSession && playbackAsset.assetIsCastable {
                        strongSelf.destroyAVPlayer()
                        strongSelf.isCastingActive = true
                        CastManager.sharedInstance.currentVideoPlayerMode = strongSelf.mode
                        CastManager.sharedInstance.add(remoteMediaClientListener: strongSelf)

                        if let currentAssetId = CastManager.sharedInstance.currentAssetId, currentAssetId == playbackAsset.assetId, let mediaStatus = CastManager.sharedInstance.currentMediaStatus {
                            strongSelf.captionsButton?.isEnabled = (CastManager.sharedInstance.currentTextTracks != nil && CastManager.sharedInstance.currentTextTracks!.count > 0)
                            strongSelf.selectInitialCaptions()
                            strongSelf.updateWithMediaStatus(mediaStatus)
                            strongSelf.syncScrubber()
                        } else {
                            if let currentCastPlaybackAsset = CastManager.sharedInstance.currentPlaybackAsset {
                                ExperienceLauncher.delegate?.didFinishPlayingAsset(currentCastPlaybackAsset, mode: CastManager.sharedInstance.currentVideoPlayerMode)
                            }

                            CastManager.sharedInstance.load(playbackAsset: playbackAsset)
                        }
                    } else {
                        sendToPlayer(playbackAsset.assetURLAsset ?? AVURLAsset(url: playbackAsset.assetURL))
                    }
                }
            })
        }
    }

    // MARK: Main Feature
    fileprivate func playMainExperience() {
        // Initial state of controls
        playerControlsVisible = false

        if !didPlayInterstitial {
            if let videoURL = CPEXMLSuite.current?.manifest.interstitialVideo?.url {
                playAsset(withURL: videoURL)

                playerControlsLocked = true
                skipContainerView.isHidden = !SettingsManager.didWatchInterstitial
                SettingsManager.didWatchInterstitial = true
                return
            }

            didPlayInterstitial = true
        }

        playerControlsLocked = false
        skipContainerView.isHidden = true

        if let videoURL = CPEXMLSuite.current?.manifest.featureVideo.url {
            NotificationCenter.default.post(name: .videoPlayerDidPlayMainExperience, object: nil)
            playAsset(withURL: videoURL)
        }
    }

    private func skipInterstitial() {
        didPlayInterstitial = true
        playMainExperience()
        logEvent(action: .skipInterstitial)
    }

    /* Set the scrubber based on the player current time. */
    @objc private func syncScrubber() {
        updateTimeLabels(time: currentTime)
        activityIndicatorVisible = false

        if let scrubber = scrubber {
            if playerItemDuration > 0 {
                let minValue = scrubber.minimumValue
                scrubber.value = (scrubber.maximumValue - minValue) * Float(currentTime) / Float(playerItemDuration) + minValue
            } else {
                scrubber.minimumValue = 0
            }
        }

        if mode == .mainFeature || mode == .basicPlayer {
            if lastNotifiedTime != currentTime {
                lastNotifiedTime = currentTime
                NotificationCenter.default.post(name: .videoPlayerDidChangeTime, object: nil, userInfo: [NotificationConstants.time: Double(currentTime)])
            }

            if currentTime > 0 && mode == .basicPlayer {
                activityIndicator?.removeFromSuperview()
            }

            player?.isMuted = shouldMute
            if shouldTrackOutput, let playerItem = player?.currentItem, playerItem.outputs.count == 0 {
                playerItem.add(AVPlayerItemVideoOutput())
            }
        }

        playbackAsset?.assetPlaybackPosition = currentTime
        syncSceneData()
    }

    private func syncSceneData() {
        if state != .unknown, let playbackAsset = playbackAsset {
            if var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo {
                if currentTime > 0 {
                    DispatchQueue.global(qos: .background).async {
                        if self.mode == .mainFeature {
                            if let triviaTimedEvent = CPEXMLSuite.current?.manifest.timedEvents(atTimecode: self.currentTime, type: .textItem)?.first {
                                if triviaTimedEvent != self.nowPlayingInfoTimedEvent, let description = triviaTimedEvent.description {
                                    self.nowPlayingInfoTimedEvent = triviaTimedEvent
                                    nowPlayingInfo[MPMediaItemPropertyTitle] = triviaTimedEvent.experience?.title
                                    nowPlayingInfo[MPMediaItemPropertyArtist] = description
                                }
                            } else if let clipShareTimedEvent = CPEXMLSuite.current?.manifest.timedEvents(atTimecode: self.currentTime, type: .clipShare)?.first {
                                if clipShareTimedEvent != self.nowPlayingInfoTimedEvent, let description = clipShareTimedEvent.description {
                                    self.nowPlayingInfoTimedEvent = clipShareTimedEvent
                                    nowPlayingInfo[MPMediaItemPropertyTitle] = clipShareTimedEvent.experience?.title
                                    nowPlayingInfo[MPMediaItemPropertyArtist] = description
                                }
                            } else {
                                self.nowPlayingInfoTimedEvent = nil

                                if let title = playbackAsset.assetTitle {
                                    nowPlayingInfo[MPMediaItemPropertyTitle] = title
                                }

                                nowPlayingInfo[MPMediaItemPropertyArtist] = ""
                            }
                        }

                        DispatchQueue.main.async {
                            if self.isCastingActive {
                                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = nil
                                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = nil
                            } else {
                                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: self.playerItemDuration)
                                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: self.currentTime)
                            }

                            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    var nowPlayingInfo = [String: Any]()

                    if let title = playbackAsset.assetTitle {
                        nowPlayingInfo[MPMediaItemPropertyTitle] = title
                    }

                    nowPlayingInfo[MPMediaItemPropertyArtist] = ""

                    if #available(iOS 10.0, *) {
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 768, height: 768), requestHandler: { [weak self] (_) -> UIImage in
                            return (self?.nowPlayingInfoImage ?? playbackAsset.assetImage)
                        })
                    }

                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                }
            }

            DispatchQueue.global(qos: .background).async {
                if let closestClipShareTimedEvent = CPEXMLSuite.current?.manifest.closestTimedEvent(toTimecode: self.currentTime, type: .clipShare) {
                    DispatchQueue.main.async {
                        if !self.playbackOverlayView.isHidden && closestClipShareTimedEvent != self.playbackOverlayTimedEvent {
                            if let imageURL = closestClipShareTimedEvent.thumbnailImageURL {
                                self.playbackOverlayImageView.sd_setImage(with: imageURL)
                                self.playbackOverlayTimedEvent = closestClipShareTimedEvent
                            }
                        }
                    }
                }
            }
        }
    }

    @objc private func playerItemDidReachEnd(_ notification: Notification!) {
        if let playerItem = notification.object as? AVPlayerItem, playerItem == player?.currentItem {
            if !didPlayInterstitial {
                didPlayInterstitial = true
                playMainExperience()
                return
            }

            goToNextVideo()
        }
    }

    fileprivate func goToNextVideo() {
        queueCurrentIndex += 1
        if queueCurrentIndex < queueTotalCount {
            pauseVideo()

            countdownLabel.isHidden = false
            countdownLabel.frame.origin = CGPoint(x: 30, y: 20)

            let progressView = UAProgressView(frame: countdownLabel.frame)
            progressView.centralView = countdownLabel
            progressView.borderWidth = 0
            progressView.lineWidth = 2
            progressView.fillOnTouch = false
            progressView.tintColor = UIColor.themePrimary
            progressView.animationDuration = Double(Constants.CountdownTimeInterval)
            self.view.addSubview(progressView)
            countdownProgressView = progressView

            countdownSeconds = 0
            countdownTimer = Timer.scheduledTimer(timeInterval: Double(Constants.CountdownTimeInterval), target: self, selector: #selector(onCountdownTimerFired), userInfo: nil, repeats: true)
        } else {
            NotificationCenter.default.post(name: .videoPlayerDidEndLastVideo, object: nil)
        }

        NotificationCenter.default.post(name: .videoPlayerDidEndVideo, object: nil)

        if mode == .mainFeature {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                self.dismissPlayer(completion: {
                    NotificationCenter.default.post(name: .outOfMovieExperienceShouldLaunch, object: nil)
                })
            }
        }
    }

    private func countdownDurationDidLoad() {
        if countdownProgressView == nil {
            let progressView = UAProgressView(frame: skipCountdownContainerView.frame)
            progressView.borderWidth = 0
            progressView.lineWidth = 2
            progressView.fillOnTouch = false
            progressView.tintColor = UIColor.white
            progressView.animationDuration = playerItemDuration
            skipContainerView.addSubview(progressView)
            countdownProgressView = progressView
            countdownProgressView?.setProgress(1, animated: true)
        }
    }

    @objc private func onCountdownTimerFired() {
        countdownSeconds += Constants.CountdownTimeInterval

        if countdownSeconds >= Constants.CountdownTotalTime {
            if let timer = countdownTimer {
                timer.invalidate()
                countdownTimer = nil
            }

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(Constants.CountdownTimeInterval) * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                self.cancelCountdown()
                NotificationCenter.default.post(name: .videoPlayerWillPlayNextItem, object: nil, userInfo: [NotificationConstants.index: self.queueCurrentIndex])
            }
        }
    }

    private func cancelCountdown() {
        if let timer = countdownTimer {
            timer.invalidate()
            countdownTimer = nil
        }

        countdownLabel.isHidden = true
        countdownProgressView?.removeFromSuperview()
        countdownProgressView = nil
    }

    private func updateTimeLabels(time: Double) {
        // Update time labels
        timeElapsedLabel?.text = timeString(fromSeconds: time)
    }

    private func timeString(fromSeconds seconds: Double) -> String? {
        let hours = Int(floor(seconds / 3600))
        let minutes = Int(floor((seconds / 60).truncatingRemainder(dividingBy: 60)))
        let secs = Int(floor(seconds.truncatingRemainder(dividingBy: 60)))

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }

        return String(format: "%02d:%02d", minutes, secs)
    }

    private func timeValue(forSlider slider: UISlider) -> Double {
        if playerItemDuration > 0 {
            let minValue = slider.minimumValue
            return Double(Float(playerItemDuration) * (slider.value - minValue) / (slider.maximumValue - minValue))
        }

        return 0
    }

    func seekPlayer(to time: Double) {
        isSeeking = true
        state = .videoSeeking

        if isCastingActive {
            CastManager.sharedInstance.seekMedia(to: time)
            isSeeking = false
            hasSeekedToPlaybackSyncStartTime = true
        } else if let player = player {
            let timescale = (player.currentItem?.duration.timescale ?? 1)
            let scaledTime = CMTimeMakeWithSeconds(time, timescale)
            if scaledTime.isValid {
                player.seek(to: scaledTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { [weak self] (finished) in
                    if finished {
                        DispatchQueue.main.async {
                            self?.isSeeking = false
                            self?.hasSeekedToPlaybackSyncStartTime = true
                            self?.playVideo()
                        }
                    }
                })
            } else {
                isSeeking = false
                hasSeekedToPlaybackSyncStartTime = true
                playVideo()
            }
        }
    }

    private func dismissPlayer(completion: (() -> Void)? = nil) {
        if let playbackAsset = playbackAsset {
            if !isCastingActive {
                pauseVideo()
                ExperienceLauncher.delegate?.didFinishPlayingAsset(playbackAsset, mode: mode)
            }
        }

        destroyPlayer()
        self.dismiss(animated: true, completion: completion)
    }

    // MARK: Actions
    @objc private func onSingleTapPlayer() {
        if !playerControlsLocked {
            if audioOptionsVisible || captionsOptionsVisible {
                audioOptionsVisible = false
                captionsOptionsVisible = false
            } else {
                playerControlsVisible = !playerControlsVisible
                initAutoHideTimer()
            }
        }
    }

    @objc private func onDoubleTapPlayer() {
        if !playerControlsLocked && !isExternalPlaybackActive {
            onCropToActivePicture()
        }
    }

    @objc private func onTapSkip() {
        if !didPlayInterstitial {
            skipInterstitial()
        }
    }

    @IBAction private func onPlay(sender: Any?) {
        initScrubberTimer()
        playVideo()

        if let button = sender as? UIButton, button == playButton {
            logEvent(action: .playButton)
        }
    }

    @IBAction private func onPause(sender: Any?) {
        pauseVideo()
        isManuallyPaused = true

        if let button = sender as? UIButton, button == pauseButton {
            logEvent(action: .pauseButton)
        }
    }

    @IBAction private func onToggleFullScreen() {
        isFullScreen = !isFullScreen
    }

    @IBAction private func onDone() {
        if isPictureInPictureActive {
            let alertController = UIAlertController(title: "", message: String.localize("player.message.pip.exit"), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: String.localize("label.cancel"), style: .cancel, handler: { [weak self] (_) in
                if let strongSelf = self, !strongSelf.isManuallyPaused {
                    strongSelf.playVideo()
                }
            }))

            alertController.addAction(UIAlertAction(title: String.localize("label.continue"), style: .default, handler: { [weak self] (_) in
                self?.dismissPlayer()
            }))

            pauseVideo()
            self.present(alertController, animated: true, completion: nil)
        } else {
            dismissPlayer()
        }
    }

    @IBAction private func onToggleCommentary() {
        captionsOptionsVisible = false
        audioOptionsVisible = !audioOptionsVisible

        if audioOptionsVisible {
            logEvent(action: .showCommentarySelection)
        }
    }

    @IBAction private func onCaptionSelection() {
        audioOptionsVisible = false
        captionsOptionsVisible = !captionsOptionsVisible

        if captionsOptionsVisible {
            logEvent(action: .showCaptionsSelection)
        }
    }

    @IBAction private func onCropToActivePicture() {
        playbackView.isCroppingToActivePicture = !playbackView.isCroppingToActivePicture

        if playbackView.isCroppingToActivePicture {
            cropToActivePictureButton?.setImage(UIImage(named: "CropActiveCancel", in: Bundle.frameworkResources, compatibleWith: nil), for: .normal)
            cropToActivePictureButton?.setImage(UIImage(named: "CropActiveCancel-Highlighted", in: Bundle.frameworkResources, compatibleWith: nil), for: .highlighted)
            logEvent(action: .cropActiveOn)
        } else {
            cropToActivePictureButton?.setImage(UIImage(named: "CropActive", in: Bundle.frameworkResources, compatibleWith: nil), for: .normal)
            cropToActivePictureButton?.setImage(UIImage(named: "CropActive-Highlighted", in: Bundle.frameworkResources, compatibleWith: nil), for: .highlighted)
            logEvent(action: .cropActiveOff)
        }
    }

    @IBAction private func onPictureInPicture() {
        if isPictureInPicturePossible {
            if #available(iOS 9.0, *) {
                (pictureInPictureController as? AVPictureInPictureController)?.startPictureInPicture()
            }

            pictureInPictureButton?.isEnabled = false
            logEvent(action: .pictureInPictureOn)
        } else {
            let alertController = UIAlertController(title: "", message: String.localize(isExternalPlaybackActive ? "player.message.pip.external" : "player.message.pip.unavailable"), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }

    /* The user is dragging the movie controller thumb to scrub through the movie. */
    @IBAction private func beginScrubbing() {
        previousScrubbingRate = (player?.rate ?? 0)
        pauseVideo()

        // Remove previous timer
        removePlayerTimeObserver()
        removeAutoHideTimer()
    }

    /* Set the player current time to match the scrubber position. */
    @IBAction private func scrub(sender: Any?) {
        if let slider = sender as? UISlider {
            updateTimeLabels(time: timeValue(forSlider: slider))
        }
    }

    @IBAction private func endScrubbing(sender: Any?) {
        if playerTimeObserver == nil {
            initScrubberTimer()
        }

        if let slider = sender as? UISlider {
            let time = timeValue(forSlider: slider)

            // Update time labels
            updateTimeLabels(time: time)

            // Seek
            seekPlayer(to: time)
        }

        if previousScrubbingRate > 0 {
            player?.rate = previousScrubbingRate
            previousScrubbingRate = 0
        }

        logEvent(action: .seekSlider)
    }

    // MARK: Controls
    /* Show the pause button in the movie player controller. */
    private func showPauseButton() {
        if state != .videoLoading {
            // Disable + Hide Play Button
            playButton?.isEnabled = false
            playButton?.isHidden = true

            // Enable + Show Pause Button
            pauseButton?.isEnabled = true
            pauseButton?.isHidden = false
        }
    }

    /* Show the play button in the movie player controller. */
    private func showPlayButton() {
        if state == .videoPaused || state == .readyToPlay {
            // Disable + Hide Pause Button
            pauseButton?.isEnabled = false
            pauseButton?.isHidden = true

            // Enable + Show Play Button
            playButton?.isEnabled = true
            playButton?.isHidden = false
        }
    }

    /* If the media is playing, show the stop button; otherwise, show the play button. */
    fileprivate func syncPlayPauseButtons() {
        if isPlaying {
            showPauseButton()
        } else {
            showPlayButton()
        }
    }

    private func initAutoHideTimer() {
        if playerControlsVisible {
            // Invalidate existing timer
            playerControlsAutoHideTimer?.invalidate()
            playerControlsAutoHideTimer = nil

            // Start timer
            playerControlsAutoHideTimer = Timer.scheduledTimer(timeInterval: Constants.PlayerControlsAutoHideTime, target: self, selector: #selector(autoHideControlsIfNecessary), userInfo: nil, repeats: false)
        }
    }

    @objc private func autoHideControlsIfNecessary() {
        if playerControlsVisible && state == .videoPlaying {
            playerControlsVisible = false
        }
    }

    private func initScrubberTimer() {
        removePlayerTimeObserver()

        /* Requests invocation of a given block during media playback to update the movie scrubber control. */
        if playerItemDuration > 0 {
            /* Update the scrubber during normal playback. */
            if isCastingActive {
                playerTimeObserver = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(syncScrubber), userInfo: nil, repeats: true)
            } else if let player = player {
                let timescale = (player.currentItem?.duration.timescale ?? 1)
                playerTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, timescale), queue: nil, using: { [weak self] (_) in
                    self?.syncScrubber()
                })
            }
        }
    }

    /* Cancels the previously registered time observer. */
    private func removePlayerTimeObserver() {
        // Player time
        if let timer = playerTimeObserver as? Timer {
            timer.invalidate()
        } else if let observer = playerTimeObserver {
            player?.removeTimeObserver(observer)
        }

        playerTimeObserver = nil
    }

    /* Cancels the previously registered controls auto-hide timer */
    private func removeAutoHideTimer() {
        playerControlsAutoHideTimer?.invalidate()
        playerControlsAutoHideTimer = nil
    }

    fileprivate func logEvent(action: AnalyticsAction, itemId: String? = nil, itemName: String? = nil) {
        if mode == .mainFeature {
            Analytics.log(event: .imeAction, action: action, itemId: itemId, itemName: itemName)
        }
    }

}

extension VideoPlayerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == audioOptionsTableView {
            return 2
        }

        if tableView == captionsOptionsTableView {
            if let options = captionsSelectionGroup?.options {
                return options.count + 1
            } else if let textTracks = CastManager.sharedInstance.currentTextTracks {
                return textTracks.count + 1
            }
        }

        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: DropdownTableViewCell.ReuseIdentifier, for: indexPath)
        guard let cell = tableViewCell as? DropdownTableViewCell else {
            return tableViewCell
        }

        if tableView == audioOptionsTableView, let option = commentaryAudioSelectionOption {
            cell.title = (indexPath.row == 0 ? String.localize("label.off") : option.displayName)
        } else if tableView == captionsOptionsTableView {
            if indexPath.row == 0 {
                cell.title = String.localize( "label.off")
            } else {
                if let options = captionsSelectionGroup?.options, options.count > (indexPath.row - 1) {
                    cell.title = options[indexPath.row - 1].displayName
                } else if let textTracks = CastManager.sharedInstance.currentTextTracks, textTracks.count > (indexPath.row - 1) {
                    let textTrack = textTracks[indexPath.row - 1]
                    if let title = textTrack.name {
                        cell.title = title
                    } else if let languageCode = textTrack.languageCode {
                        cell.title = (Locale(identifier: languageCode) as NSLocale).displayName(forKey: .identifier, value: languageCode)
                    } else {
                        cell.title = "CC"
                    }
                }
            }

            cell.isSelected = (currentCaptionsSelectionIndex == indexPath.row)
        }

        return cell
    }

}

extension VideoPlayerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (tableView.cellForRow(at: indexPath) as? DropdownTableViewCell)?.updateStyle()

        if tableView == audioOptionsTableView, let group = audioSelectionGroup {
            if indexPath.row > 0, let option = commentaryAudioSelectionOption {
                player?.currentItem?.select(option, in: group)
                commentaryButton?.isSelected = true
                logEvent(action: .commentaryOn)
            } else if let option = mainAudioSelectionOption {
                player?.currentItem?.select(option, in: group)
                commentaryButton?.isSelected = false
                logEvent(action: .commentaryOff)
            }
        } else if tableView == captionsOptionsTableView {
            currentCaptionsSelectionIndex = indexPath.row
        }
    }

}

@available(iOS 9.0, *)
extension VideoPlayerViewController: AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        self.pictureInPictureButton?.isEnabled = playerControlsEnabled
    }

    func picture(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        let alertController = UIAlertController(title: "", message: String.localize("player.message.pip.error"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

}

extension VideoPlayerViewController: GCKDiscoveryManagerListener {

    func didUpdateDeviceList() {
        updateToolbarButtons()
    }

}

extension VideoPlayerViewController: GCKSessionManagerListener {

    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        if let playbackAsset = playbackAsset {
            ExperienceLauncher.delegate?.didFinishPlayingAsset(playbackAsset, mode: mode)
            playAsset(withURL: playbackAsset.assetURL, title: playbackAsset.assetTitle, imageURL: playbackAsset.assetImageURL, fromStartTime: playbackAsset.assetPlaybackPosition)
        }
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        isCastingActive = true
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        if let playbackAsset = playbackAsset {
            CastManager.sharedInstance.currentPlaybackAsset = nil
            ExperienceLauncher.delegate?.didFinishPlayingAsset(playbackAsset, mode: mode)
            playAsset(withURL: playbackAsset.assetURL, title: playbackAsset.assetTitle, imageURL: playbackAsset.assetImageURL, fromStartTime: playbackAsset.assetPlaybackPosition)
        }
    }

}

extension VideoPlayerViewController: GCKRemoteMediaClientListener {

    fileprivate func updateWithMediaStatus(_ mediaStatus: GCKMediaStatus?) {
        if didPlayInterstitial, let mediaStatus = mediaStatus {
            if let duration = mediaStatus.mediaInformation?.streamDuration {
                playerItemDuration = duration
            }

            switch mediaStatus.playerState {
            case .unknown:
                state = .unknown
                break

            case .idle:
                if mediaStatus.idleReason == .finished {
                    goToNextVideo()
                    state = .videoPaused
                } else {
                    state = .unknown
                }
                break

            case .playing:
                state = .videoPlaying
                break

            case .paused:
                state = .videoPaused
                break

            case .buffering, .loading:
                state = .videoLoading
                break
            }

            syncPlayPauseButtons()
        }
    }

    func remoteMediaClient(_ client: GCKRemoteMediaClient, didStartMediaSessionWithID sessionID: Int) {
        captionsButton?.isEnabled = ((CastManager.sharedInstance.currentTextTracks?.count ?? 0) > 0)
        selectInitialCaptions()
    }

    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        updateWithMediaStatus(mediaStatus)
    }

}
