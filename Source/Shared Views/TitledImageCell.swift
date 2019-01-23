//
//  ContentCell.swift
//

import UIKit
import CPEData

class TitledImageCell: UICollectionViewCell {

    @objc static let NibName = "TitledImageCell"
    @objc static let ReuseIdentifier = "TitledImageCellReuseIdentifier"

    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!

    var experience: Experience? {
        didSet {
            title = experience?.title
            imageURL = experience?.thumbnailImageURL
        }
    }

    @objc var title: String? {
        set {
            titleLabel.text = newValue?.uppercased()
        }

        get {
            return titleLabel.text
        }
    }

    @objc var imageURL: URL? {
        set {
            if let url = newValue {
                imageView.sd_setImage(with: url)
            } else {
                imageView.sd_cancelCurrentImageLoad()
                imageView.image = nil
            }
        }

        get {
            return nil
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        experience = nil
    }

}
