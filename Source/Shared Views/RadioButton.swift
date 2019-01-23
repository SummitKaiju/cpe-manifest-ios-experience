//
//  RadioButton.swift
//

import UIKit

class RadioButton: UIButton {

    var section: Int?
    var index: Int?
    @objc var selection = CAShapeLayer()

    override var isSelected: Bool {
        didSet {
            toggleButon()
        }

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    @objc func initialize() {

        self.isUserInteractionEnabled = true
        self.clipsToBounds = true
        self.layer.borderWidth = 3
        self.layer.cornerRadius = 0.5*35
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.backgroundColor = UIColor.black.cgColor

        selection.frame = CGRect(x: 5, y: 5, width: 25, height: 25)
        selection.borderWidth = 3
        selection.cornerRadius = 0.5*25
        selection.borderColor = UIColor.clear.cgColor
        self.layer.addSublayer(selection)
    }

    @objc func toggleButon() {
        if self.isSelected {
            highlight()

        } else {
            removeHighlight()

    }
    }

    @objc func highlight() {
        //self.selected = !self.selected

        selection.backgroundColor = UIColor.init(red: 255/255, green: 205/255, blue: 77/255, alpha: 1).cgColor
        self.layer.borderColor = UIColor.white.cgColor

    }

    @objc func removeHighlight() {
        //self.selected = !self.selected

        selection.backgroundColor = UIColor.clear.cgColor
        self.layer.borderColor = UIColor.gray.cgColor

    }

}
