//
//  DropdownTableViewCell.swift
//

import UIKit

class DropdownTableViewCell: UITableViewCell {

    @objc static let NibName = "DropdownTableViewCell"
    @objc static let ReuseIdentifier = "DropdownTableViewCellReuseIdentifier"

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!

    @objc var title: String? {
        get {
            return titleLabel.text
        }

        set {
            titleLabel.text = newValue
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        title = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        titleLabel.textColor = (selected ? UIColor.themePrimary : UIColor.white)
        iconImageView.image = UIImage(named: (selected ? "DropdownRadio-Highlighted" : "DropdownRadio"), in: Bundle.frameworkResources, compatibleWith: nil)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateStyle()
    }

    @objc func updateStyle() {
        self.contentView.backgroundColor = UIColor.clear
        self.backgroundColor = UIColor.clear
    }

}
