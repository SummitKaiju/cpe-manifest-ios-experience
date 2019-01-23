//
//  ImageSceneDetailCollectionViewCell.swift
//

import Foundation
import UIKit

class ImageSceneDetailCollectionViewCell: SceneDetailCollectionViewCell {

    @objc static let NibName = "ImageSceneDetailCollectionViewCell"
    @objc static let NibNameClipShare = "ClipShareSceneDetailCollectionViewCell"
    @objc static let ReuseIdentifier = "ImageSceneDetailCollectionViewCellReuseIdentifier"
    @objc static let ClipShareReuseIdentifier = "ClipShareSceneDetailCollectionViewCellReuseIdentifier"

    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var playButton: UIButton!
    @IBOutlet weak private var extraDescriptionLabel: UILabel!

    private var imageURL: URL? {
        set {
            if let url = newValue {
                imageView.sd_setImage(with: url)
            } else {
                imageView.sd_cancelCurrentImageLoad()
                imageView.image = nil
                imageView.backgroundColor = UIColor.clear
            }
        }

        get {
            return nil
        }
    }

    override func timedEventDidChange() {
        super.timedEventDidChange()

        imageURL = timedEvent?.thumbnailImageURL
        playButton.isHidden = timedEvent == nil || (!timedEvent!.isType(.video) && !timedEvent!.isType(.clipShare))
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageURL = nil
        playButton.isHidden = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        imageView.contentMode = .scaleAspectFill
    }

}
