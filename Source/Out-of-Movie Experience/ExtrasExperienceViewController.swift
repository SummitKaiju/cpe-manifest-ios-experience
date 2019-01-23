//
//  ExtrasExperienceViewController.swift
//

import UIKit
import CPEData
import SDWebImage

class ExtrasExperienceViewController: UIViewController {

    internal struct Constants {
        static let HeaderButtonWidth: CGFloat = (DeviceType.IS_IPAD ? 250 : 100)
        static let HeaderIconPadding: CGFloat = (DeviceType.IS_IPAD ? 30 : 15)
        static let TitleImageAspectRatio: CGFloat = 300 / 90
        static let TitleImageTopPadding: CGFloat = 10
        static let TitleImageHeight: CGFloat = (DeviceType.IS_IPAD ? 90 : 50)
        static let TitleLabelXOffset: CGFloat = -30
        static let TitleLabelYOffset: CGFloat = 5
    }

    var experience: Experience!
    @objc var customTitle: String?

    private var _homeButton: UIButton!
    private var _backButton: UIButton!

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        var titleView: UIView
        if experience.isOutOfMovieExperience, let titleImageURL = CPEXMLSuite.current!.cpeStyle?.nodeStyle(withExperienceID: experience.id, interfaceOrientation: UIApplication.shared.statusBarOrientation)?.theme.baseImageURLForButton("Title") {
            let titleImageView = UIImageView()
            titleImageView.contentMode = .scaleAspectFit
            titleImageView.sd_setImage(with: titleImageURL)
            self.view.addSubview(titleImageView)
            self.view.sendSubviewToBack(titleImageView)
            titleView = titleImageView
        } else {
            let titleLabel = UILabel()
            titleLabel.font = UIFont.themeCondensedBoldFont(DeviceType.IS_IPAD ? 30 : 18)
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.numberOfLines = 2
            titleLabel.minimumScaleFactor = 0.5
            titleLabel.text = (customTitle ?? (experience.title == "out-of-movie" ? String.localize("out_of_movie.extras_title") : experience.title))?.uppercased()
            titleLabel.textAlignment = .right
            titleLabel.textColor = UIColor(netHex: 0xdddddd)
            self.view.addSubview(titleLabel)
            self.view.sendSubviewToBack(titleLabel)
            titleView = titleLabel
        }

        titleView.clipsToBounds = true
        titleView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 9.0, *) {
            titleView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.28).isActive = true
            titleView.heightAnchor.constraint(equalToConstant: Constants.TitleImageHeight).isActive = true
            titleView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor).isActive = true
            titleView.trailingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.trailingAnchor, constant: 10).isActive = true
        } else {
            self.view.addConstraints([
                NSLayoutConstraint(item: titleView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 0.28, constant: 0),
                NSLayoutConstraint(item: titleView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: Constants.TitleImageHeight),
                NSLayoutConstraint(item: titleView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: titleView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -8)
            ])
        }

        _homeButton = headerButton(String.localize("label.home"), imageName: "Home")
        self.view.addSubview(_homeButton)
        self.view.sendSubviewToBack(_homeButton)

        _backButton = headerButton(String.localize("label.back"), imageName: "Back Nav")
        self.view.addSubview(_backButton)
        self.view.sendSubviewToBack(_backButton)

        if let titleTreatmentImageURL = CPEXMLSuite.current?.manifest.inMovieExperience.thumbnailImageURL {
            let titleTreatmentImageView = UIImageView()
            titleTreatmentImageView.translatesAutoresizingMaskIntoConstraints = false
            titleTreatmentImageView.contentMode = .scaleAspectFit
            titleTreatmentImageView.clipsToBounds = true
            titleTreatmentImageView.sd_setImage(with: titleTreatmentImageURL)
            self.view.addSubview(titleTreatmentImageView)
            self.view.sendSubviewToBack(titleTreatmentImageView)

            if #available(iOS 9.0, *) {
                titleTreatmentImageView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.4).isActive = true
                titleTreatmentImageView.heightAnchor.constraint(equalToConstant: Constants.TitleImageHeight - (Constants.TitleImageTopPadding * 2)).isActive = true
                titleTreatmentImageView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor, constant: Constants.TitleImageTopPadding).isActive = true
                titleTreatmentImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            } else {
                self.view.addConstraints([
                    NSLayoutConstraint(item: titleTreatmentImageView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 0.4, constant: 0),
                    NSLayoutConstraint(item: titleTreatmentImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: Constants.TitleImageHeight - (Constants.TitleImageTopPadding * 2)),
                    NSLayoutConstraint(item: titleTreatmentImageView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: Constants.TitleImageTopPadding),
                    NSLayoutConstraint(item: titleTreatmentImageView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0)
                ])
            }
        }

        if let nodeStyle = CPEXMLSuite.current!.cpeStyle?.nodeStyle(withExperienceID: CPEXMLSuite.current!.manifest.outOfMovieExperience.id, interfaceOrientation: UIApplication.shared.statusBarOrientation) {
            self.view.backgroundColor = nodeStyle.backgroundColor

            if let backgroundImageURL = nodeStyle.backgroundImage?.url {
                let backgroundImageView = UIImageView()
                backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
                backgroundImageView.sd_setImage(with: backgroundImageURL)
                backgroundImageView.contentMode = (nodeStyle.backgroundScaleMethod == .bestFit ? .scaleAspectFill : .scaleAspectFit)
                self.view.addSubview(backgroundImageView)
                self.view.sendSubviewToBack(backgroundImageView)

                if #available(iOS 9.0, *) {
                    backgroundImageView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                    backgroundImageView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
                    backgroundImageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
                    backgroundImageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
                } else {
                    self.view.addConstraints([
                        NSLayoutConstraint(item: backgroundImageView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0),
                        NSLayoutConstraint(item: backgroundImageView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0),
                        NSLayoutConstraint(item: backgroundImageView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0),
                        NSLayoutConstraint(item: backgroundImageView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0)
                    ])
                }
            }
        }

        showBackButton()
    }

    @objc internal func headerButton(_ title: String, imageName: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.isHidden = true
        button.frame = CGRect(x: 0, y: StatusBarSize.HEIGHT, width: Constants.HeaderButtonWidth, height: Constants.TitleImageHeight)
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: Constants.HeaderIconPadding + 10, bottom: 0, right: 0)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: Constants.HeaderIconPadding, bottom: 0, right: 0)
        button.titleLabel?.font = UIFont.themeFont(DeviceType.IS_IPAD ? 18 : 14)
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(named: imageName, in: Bundle.frameworkResources, compatibleWith: nil), for: .normal)
        button.addTarget(self, action: #selector(self.close), for: .touchUpInside)
        return button
    }

    @objc internal func showHomeButton() {
        _homeButton.isHidden = false
        _backButton.isHidden = true
    }

    @objc internal func showBackButton() {
        _homeButton.isHidden = true
        _backButton.isHidden = false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let presentedViewController = self.presentedViewController, presentedViewController.classForCoder != UIAlertController.self, !presentedViewController.isBeingDismissed {
            return presentedViewController.supportedInterfaceOrientations
        }

        return (DeviceType.IS_IPAD ? .landscape : .portrait)
    }

    // MARK: Actions
    @objc internal func close() {
        self.dismiss(animated: true, completion: nil)
    }

}
