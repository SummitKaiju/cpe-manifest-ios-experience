//
//  MenuItemCell.swift
//

import UIKit
import QuartzCore

class MenuItemCell: UITableViewCell {

    @objc static let NibName = "MenuItemCell"
    @objc static let ReuseIdentifier = "MenuItemCellReuseIdentifier"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet var titleLabelLargePaddingConstraint: NSLayoutConstraint!

    var menuItem: MenuItem? {
        didSet {
            titleLabel.text = menuItem?.title
        }
    }

    @objc var active = false {
        didSet {
            updateCellStyle()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        menuItem = nil
        active = false
        titleLabelLargePaddingConstraint.isActive = true
    }

    @objc func updateCellStyle() {
        titleLabel.textColor = (self.active ? UIColor.themePrimary : UIColor.white)
    }

}
