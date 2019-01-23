//
//  MapItemCell.swift
//

import UIKit
import CPEData

class MapItemCell: UICollectionViewCell {

    @objc static let NibName = "MapItemCell"
    @objc static let ReuseIdentifier = "MapItemCellReuseIdentifier"

    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var playButton: UIButton!

    @objc var title: String? {
        set {
            titleLabel.text = newValue
        }

        get {
            return titleLabel.text
        }
    }

    @objc var imageURL: URL? {
        set {
            if let imageURL = newValue {
                imageView.sd_setImage(with: imageURL)
            } else {
                imageView.sd_cancelCurrentImageLoad()
                imageView.image = nil
            }
        }

        get {
            return nil
        }
    }

    @objc var playButtonVisible: Bool {
        set {
            playButton.isHidden = !newValue
        }

        get {
            return !playButton.isHidden
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        title = nil
        imageURL = nil
        playButton.isHidden = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if !DeviceType.IS_IPAD {
            titleLabel.font = UIFont(name: titleLabel.font.fontName, size: 12)
        }
    }

}
