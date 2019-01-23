//
//  VideoCell.swift
//

import UIKit
import CPEData
import SDWebImage

class VideoCell: UITableViewCell {

    @objc static let ReuseIdentifier = "VideoCellReuseIdentifier"
    @objc static let NibName = "VideoCell" + (DeviceType.IS_IPAD ? "" : "_iPhone")

    @IBOutlet weak private var thumbnailContainerView: UIView!
    @IBOutlet weak private var thumbnailImageView: UIImageView!
    @IBOutlet weak private var playIconImageView: UIImageView!
    @IBOutlet weak private var runtimeLabel: UILabel!
    @IBOutlet weak private var captionLabel: UILabel!

    private var didPlayVideoObserver: NSObjectProtocol?

    var experience: Experience? {
        didSet {
            captionLabel.text = experience?.title
            if !DeviceType.IS_IPAD {
                captionLabel.sizeToFit()
            }

            if let video = experience?.video, let videoURL = video.url {
                if video.runtimeInSeconds > 0 {
                    runtimeLabel.isHidden = false
                    runtimeLabel.text = SettingsManager.didWatchVideo(videoURL) ? String.localize("label.watched") : video.runtimeInSeconds.formattedTime()
                } else {
                    runtimeLabel.isHidden = true
                }

                didPlayVideoObserver = NotificationCenter.default.addObserver(forName: .videoPlayerDidPlayVideo, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
                    if let strongSelf = self, let playingVideoURL = notification.userInfo?[NotificationConstants.videoUrl] as? URL, playingVideoURL == videoURL {
                        strongSelf.runtimeLabel.text = String.localize("label.playing")
                    }
                })
            } else {
                runtimeLabel.isHidden = true
            }

            if let imageURL = experience?.thumbnailImageURL {
                thumbnailImageView.sd_setImage(with: imageURL)
            } else {
                thumbnailImageView.sd_cancelCurrentImageLoad()
                thumbnailImageView.image = nil
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        experience = nil

        if let observer = didPlayVideoObserver {
            NotificationCenter.default.removeObserver(observer)
            didPlayVideoObserver = nil
        }

        runtimeLabel.text = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateCellStyle()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        updateCellStyle()

        if selected {
            UIView.animate(withDuration: 0.25, animations: {
                self.thumbnailImageView.alpha = 1
                self.captionLabel.alpha = 1
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.25, animations: {
                self.thumbnailImageView.alpha = 0.5
                self.captionLabel.alpha = 0.5
                if let video = self.experience?.video {
                    if let videoURL = video.url {
                        self.runtimeLabel.text = SettingsManager.didWatchVideo(videoURL) ? String.localize("label.watched") : video.runtimeInSeconds.formattedTime()
                    } else {
                        self.runtimeLabel.text = video.runtimeInSeconds.formattedTime()
                    }
                }
            }, completion: nil)
        }
    }

    @objc func updateCellStyle() {
        thumbnailContainerView.layer.borderColor = UIColor.white.cgColor
        thumbnailContainerView.layer.borderWidth = (self.isSelected ? 2 : 0)
        captionLabel.textColor = (self.isSelected ? UIColor.themePrimary : UIColor.white)
        playIconImageView.isHidden = (experience == nil || experience!.isType(.gallery)) || self.isSelected
    }

    @objc func setWatched() {
        self.runtimeLabel.text = String.localize("label.watched")
    }

}
