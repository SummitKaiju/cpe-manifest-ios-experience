//
//  SocialButton.swift
//

import UIKit
import CPEData

class SocialButton: UIButton {

    var socialAccount: SocialAccount!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        initialize()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        initialize()
    }

    private func initialize() {
        self.isUserInteractionEnabled = true
        self.clipsToBounds = true
        self.layer.borderWidth = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.layer.cornerRadius = self.frame.size.width / 2
    }

    @objc func openURL() {
        socialAccount.url?.promptLaunch()
    }

}
