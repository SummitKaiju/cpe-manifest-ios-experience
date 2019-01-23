//
//  SimpleImageCollectionViewCell.swift
//

import UIKit

open class SimpleImageCollectionViewCell: UICollectionViewCell {

    @objc public static let NibName = "SimpleImageCollectionViewCell"
    @objc public static let BaseReuseIdentifier = "SimpleImageCollectionViewCellReuseIdentifier"

    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var playButton: UIButton?

    @objc public var showsSelectedBorder = false

    @objc open var imageURL: URL? {
        set {
            if let url = newValue {
                self.imageView.sd_setImage(with: url)
            } else {
                self.imageView.sd_cancelCurrentImageLoad()
                self.imageView.image = nil
            }
        }

        get {
            return nil
        }
    }

    @objc open var playButtonVisible: Bool {
        set {
            playButton?.isHidden = !newValue
        }

        get {
            return playButton != nil && !playButton!.isHidden
        }
    }

    override open var isSelected: Bool {
        didSet {
            if self.isSelected && showsSelectedBorder {
                self.layer.borderWidth = 2
                self.layer.borderColor = UIColor.white.cgColor
            } else {
                self.layer.borderWidth = 0
                self.layer.borderColor = nil
            }
        }
    }

    override open func prepareForReuse() {
        super.prepareForReuse()

        self.isSelected = false

        imageURL = nil
        playButtonVisible = false
    }

}
