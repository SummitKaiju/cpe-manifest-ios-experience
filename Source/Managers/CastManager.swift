//
//  CastManager.swift
//

import GoogleCast

@objc open class CastManager: NSObject {

    private struct Keys {
        static let AssetId = "assetId"
    }

    @objc public static let sharedInstance = CastManager()

    @objc public var isInitialized = false

    @objc open var hasDiscoveredDevices: Bool {
        return (isInitialized && GCKCastContext.sharedInstance().discoveryManager.hasDiscoveredDevices)
    }

    @objc open var currentSession: GCKCastSession? {
        if isInitialized {
            return GCKCastContext.sharedInstance().sessionManager.currentCastSession
        }

        return nil
    }

    @objc open var currentMediaStatus: GCKMediaStatus? {
        return currentSession?.remoteMediaClient?.mediaStatus
    }

    @objc open var hasConnectedCastSession: Bool {
        return (isInitialized && GCKCastContext.sharedInstance().sessionManager.hasConnectedCastSession())
    }

    @objc open var currentTime: Double {
        return (currentSession?.remoteMediaClient?.approximateStreamPosition() ?? 0)
    }

    @objc open var streamDuration: Double {
        return (currentMediaStatus?.mediaInformation?.streamDuration ?? 0)
    }

    @objc open var currentAssetId: String? {
        return ((currentMediaStatus?.mediaInformation?.customData as? [String: Any])?[Keys.AssetId] as? String)
    }

    @objc open var currentAssetURL: URL? {
        if let contentID = currentMediaStatus?.mediaInformation?.contentID {
            return URL(string: contentID)
        }

        return nil
    }

    @objc open var currentTextTracks: [GCKMediaTrack]? {
        return currentMediaStatus?.mediaInformation?.mediaTracks?.filter({ $0.type == .text })
    }

    @objc open var isPlaying: Bool {
        return (currentMediaStatus != nil && currentMediaStatus!.playerState == .playing)
    }

    @objc public var currentPlaybackAsset: PlaybackAsset?
    public var currentVideoPlayerMode = VideoPlayerMode.unknown

    @objc open func start(withReceiverAppID receiverAppID: String) {
        GCKCastContext.setSharedInstanceWith(GCKCastOptions(receiverApplicationID: receiverAppID))
        GCKCastContext.sharedInstance().sessionManager.add(self)
        GCKLogger.sharedInstance().delegate = self
        isInitialized = true
    }

    @objc open func load(mediaInfo: GCKMediaInformation, playPosition: Double = 0) {
        currentSession?.remoteMediaClient?.loadMedia(mediaInfo, autoplay: true, playPosition: playPosition)
    }

    @objc open func load(playbackAsset: PlaybackAsset) {
        let metadata = GCKMediaMetadata(metadataType: .movie)
        metadata.setString(playbackAsset.assetTitle ?? "", forKey: kGCKMetadataKeyTitle)
        if let imageURL = playbackAsset.assetImageURL {
            metadata.addImage(GCKImage(url: imageURL, width: 0, height: 0))
        }

        var mediaTracks: [GCKMediaTrack]?
        if let textTracks = playbackAsset.assetTextTracks {
            mediaTracks = [GCKMediaTrack]()
            for (identifier, textTrack) in textTracks.enumerated() {
                mediaTracks!.append(GCKMediaTrack(
                    identifier: identifier,
                    contentIdentifier: textTrack.textTrackURL.absoluteString,
                    contentType: textTrack.textTrackFormat.contentType,
                    type: .text,
                    textSubtype: textTrack.textTrackType.gckMediaTextTrackSubtype,
                    name: (textTrack.textTrackTitle ?? (Locale(identifier: textTrack.textTrackLanguageCode) as NSLocale).displayName(forKey: .identifier, value: textTrack.textTrackLanguageCode)),
                    languageCode: textTrack.textTrackLanguageCode,
                    customData: (textTrack.textTrackCastCustomData ?? nil)
                ))
            }
        }

        var customData = (playbackAsset.assetCastCustomData ?? nil) ?? [String: Any]()
        customData[Keys.AssetId] = playbackAsset.assetId

        load(mediaInfo: GCKMediaInformation(
            contentID: playbackAsset.assetURL.absoluteString,
            streamType: .buffered,
            contentType: (playbackAsset.assetContentType ?? "video/mp4"),
            metadata: metadata,
            streamDuration: 0,
            mediaTracks: mediaTracks,
            textTrackStyle: nil,
            customData: customData
        ), playPosition: playbackAsset.assetPlaybackPosition)

        currentPlaybackAsset = playbackAsset
    }

    @objc open func add(remoteMediaClientListener listener: GCKRemoteMediaClientListener) {
        currentSession?.remoteMediaClient?.add(listener)
    }

    @objc open func add(sessionManagerListener listener: GCKSessionManagerListener) {
        if isInitialized {
            GCKCastContext.sharedInstance().sessionManager.add(listener)
        }
    }

    @objc open func add(discoveryManagerListener listener: GCKDiscoveryManagerListener) {
        if isInitialized {
            GCKCastContext.sharedInstance().discoveryManager.add(listener)
        }
    }

    @objc open func remove(remoteMediaClientListener listener: GCKRemoteMediaClientListener) {
        currentSession?.remoteMediaClient?.remove(listener)
    }

    @objc open func remove(sessionManagerListener listener: GCKSessionManagerListener) {
        if isInitialized {
            GCKCastContext.sharedInstance().sessionManager.remove(listener)
        }
    }

    @objc open func remove(discoveryManagerListener listener: GCKDiscoveryManagerListener) {
        if isInitialized {
            GCKCastContext.sharedInstance().discoveryManager.remove(listener)
        }
    }

    @objc open func playMedia() {
        currentSession?.remoteMediaClient?.play()
    }

    @objc open func pauseMedia() {
        currentSession?.remoteMediaClient?.pause()
    }

    @objc open func stopMedia() {
        currentSession?.remoteMediaClient?.stop()
    }

    @objc open func seekMedia(to time: Double) {
        currentSession?.remoteMediaClient?.seek(toTimeInterval: time, resumeState: .play)
    }

    @objc open func selectTextTrack(withLanguageCode languageCode: String) {
        if let identifier = currentMediaStatus?.mediaInformation?.mediaTracks?.first(where: { $0.languageCode != nil && $0.languageCode! == languageCode })?.identifier {
            selectTextTrack(withIdentifier: identifier)
        }
    }

    @objc open func selectTextTrack(withIdentifier identifier: Int) {
        currentSession?.remoteMediaClient?.setActiveTrackIDs([NSNumber(value: identifier)])
    }

    @objc open func disableTextTracks() {
        currentSession?.remoteMediaClient?.setActiveTrackIDs(nil)
    }

}

extension CastManager: GCKSessionManagerListener {

    public func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        print("Cast session started")
        ExternalPlaybackManager.isChromecastActive = true
    }

    public func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        print("Cast session resumed")
        ExternalPlaybackManager.isChromecastActive = true
    }

    public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        print("Cast session ended with error: \(error?.localizedDescription ?? "Unknown error")")
        ExternalPlaybackManager.isChromecastActive = false

        if let playbackAsset = currentPlaybackAsset {
            ExperienceLauncher.delegate?.didFinishPlayingAsset(playbackAsset, mode: currentVideoPlayerMode)
            currentPlaybackAsset = nil
        }
    }

    public func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        print("Cast session failed to start: \(error)")
        ExternalPlaybackManager.isChromecastActive = false

        currentPlaybackAsset = nil
    }

}

extension CastManager: GCKLoggerDelegate {

    public func logMessage(_ message: String, fromFunction function: String) {
        print("GCKLoggerDelegate: \(function) \(message)")
    }

}
