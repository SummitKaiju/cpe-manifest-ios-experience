//
//  TalentDetailViewController.swift
//

import UIKit
import CPEData
import MBProgressHUD

protocol TalentDetailViewPresenter {
    func talentDetailViewShouldClose()
}

enum TalentDetailMode: String {
    case Synced = "TalentDetailModeSynced"
    case Extras = "TalentDetailModeExtras"
}

class TalentDetailViewController: SceneDetailViewController {

    fileprivate struct SegueIdentifier {
        static let TalentImageGallery = "TalentImageGallerySegueIdentifier"
    }

    fileprivate struct Constants {
        static let GalleryCollectionViewItemSpacing: CGFloat = 10
        static let GalleryCollectionViewItemAspectRatio: CGFloat = 3 / 4
        static let FilmographyCollectionViewItemSpacing: CGFloat = 10
        static let FilmographyCollectionViewItemAspectRatio: CGFloat = 27 / 40
    }

    @IBOutlet private var containerViewTopConstraint: NSLayoutConstraint!

    @IBOutlet weak private var talentImageView: UIImageView?
    @IBOutlet weak private var talentGalleryButton: UIButton?
    @IBOutlet weak private var talentNameLabel: UILabel!
    @IBOutlet weak private var talentBiographyContainerView: UIView?
    @IBOutlet weak private var talentBiographyHeaderLabel: UILabel?
    @IBOutlet weak private var talentBiographyLabel: UITextView?

    @IBOutlet weak private var galleryContainerView: UIView?
    @IBOutlet weak private var galleryHeaderLabel: UILabel?
    @IBOutlet weak fileprivate var galleryCollectionView: UICollectionView?

    @IBOutlet weak private var filmographyContainerView: UIView?
    @IBOutlet weak private var filmographyHeaderLabel: UILabel?
    @IBOutlet weak fileprivate var filmographyCollectionView: UICollectionView?

    @IBOutlet weak private var twitterButton: SocialButton?
    @IBOutlet weak private var facebookButton: SocialButton?
    @IBOutlet weak private var instagramButton: SocialButton?

    var images = [String]()
    var talent: Person!
    var mode = TalentDetailMode.Extras

    var currentAnalyticsEvent: AnalyticsEvent {
        return (mode == .Synced ? .imeTalentAction : .extrasTalentAction)
    }

    private var hud: MBProgressHUD?

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Localizations
        talentBiographyHeaderLabel?.text = (talent.biographyHeader ?? String.localize("talentdetail.biography")).uppercased()
        galleryHeaderLabel?.text = String.localize("talentdetail.gallery").uppercased()
        filmographyHeaderLabel?.text = String.localize("talentdetail.filmography").uppercased()

        // Mode Layout
        let talentHasGallery = talent.gallery != nil && talent.gallery!.numPictures > 1
        if mode == .Extras {
            titleLabel.removeFromSuperview()
            closeButton.removeFromSuperview()
            containerViewTopConstraint.constant = (DeviceType.IS_IPAD ? 20 : 10)
            talentGalleryButton?.removeFromSuperview()
            galleryCollectionView?.register(UINib(nibName: SimpleImageCollectionViewCell.NibName, bundle: Bundle.frameworkResources), forCellWithReuseIdentifier: SimpleImageCollectionViewCell.BaseReuseIdentifier)
            if !talentHasGallery {
                galleryContainerView?.removeFromSuperview()
            }
        } else {
            galleryHeaderLabel?.removeFromSuperview()
            galleryCollectionView?.removeFromSuperview()
            galleryContainerView?.removeFromSuperview()
            if talentHasGallery {
                talentGalleryButton?.isHidden = false
            }
        }

        if talentHasGallery {
            let launchGalleryTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onLaunchGallery))
            launchGalleryTapGestureRecognizer.numberOfTapsRequired = 1
            talentImageView?.addGestureRecognizer(launchGalleryTapGestureRecognizer)
            talentImageView?.isUserInteractionEnabled = true
        }

        filmographyCollectionView?.register(UINib(nibName: SimpleImageCollectionViewCell.NibName, bundle: Bundle.frameworkResources), forCellWithReuseIdentifier: SimpleImageCollectionViewCell.BaseReuseIdentifier)

        if !talent.detailsLoaded {
            hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        }

        // Fill data
        self.talentNameLabel.text = talent.name.uppercased()

        DispatchQueue.global(qos: .userInitiated).async {
            if let imageURL = self.talent.largeImageURL {
                self.talentImageView?.sd_setImage(with: imageURL)
            } else {
                DispatchQueue.main.async {
                    self.talentImageView?.removeFromSuperview()
                }
            }

            self.talent.getTalentDetails({ (biography, socialAccounts, films) in
                DispatchQueue.main.async(execute: {
                    if let biography = biography, !biography.isEmpty {
                        self.talentBiographyContainerView?.isHidden = false
                        self.talentBiographyLabel?.scrollRectToVisible(CGRect.zero, animated: false)

                        // Wrap the full biography in an HTML element with the font in CSS to preserve all the italic and bold tags of the original HTML
                        let biographyHTML = "<span style=\"color: #fff; font-family: \(UIFont.themeCondensedFont(14).fontName); font-size: 14\">\(biography)</span>"
                        if let biographyData = biographyHTML.data(using: .utf8) {
                            do {

                                let options: [String: Any] = [
                                    NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                    NSCharacterEncodingDocumentAttribute: NSNumber(value: String.Encoding.utf8.rawValue)
                                ]

                                let attributedString = try NSAttributedString(data: biographyData, options: options, documentAttributes: nil)
                                self.talentBiographyLabel?.attributedText = attributedString
                            } catch {
                                self.talentBiographyLabel?.text = biography
                            }
                        } else {
                            self.talentBiographyLabel?.text = biography
                        }
                    } else {
                        self.talentBiographyContainerView?.removeFromSuperview()
                    }

                    if let socialAccounts = socialAccounts {
                        for socialAccount in socialAccounts {
                            switch socialAccount.type {
                            case .facebook:
                                self.facebookButton?.isHidden = false
                                self.facebookButton?.socialAccount = socialAccount
                                break

                            case .twitter:
                                self.twitterButton?.isHidden = false
                                self.twitterButton?.socialAccount = socialAccount
                                break

                            case .instagram:
                                self.instagramButton?.isHidden = false
                                self.instagramButton?.socialAccount = socialAccount
                                break

                            default:
                                break
                            }
                        }
                    }

                    if let button = self.facebookButton, button.isHidden {
                        button.removeFromSuperview()
                    }

                    if let button = self.twitterButton, button.isHidden {
                        button.removeFromSuperview()
                    }

                    if let button = self.instagramButton, button.isHidden {
                        button.removeFromSuperview()
                    }

                    let hasFilms = films != nil && films!.count > 0
                    if hasFilms {
                        self.filmographyContainerView?.isHidden = false
                        self.filmographyCollectionView?.reloadData()
                        self.filmographyCollectionView?.setContentOffset(CGPoint(), animated: false)
                    } else {
                        self.filmographyContainerView?.removeFromSuperview()
                    }

                    self.hud?.hide(true)
                })
            })
        }

        galleryCollectionView?.reloadData()
    }

    // MARK: Actions
    override internal func onClose() {
        if let parent = self.parent as? TalentDetailViewPresenter {
            parent.talentDetailViewShouldClose()
        } else {
            super.onClose()
        }
    }

    @IBAction func openSocialURL(_ sender: SocialButton) {
        sender.openURL()
        Analytics.log(event:currentAnalyticsEvent, action: .selectSocial, itemId: talent.id, itemName: sender.socialAccount.type.rawValue)
    }

    @IBAction func onLaunchGallery() {
        self.performSegue(withIdentifier: SegueIdentifier.TalentImageGallery, sender: nil)
    }

    // MARK: Storyboard Methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.TalentImageGallery, let talentImageGalleryViewController = segue.destination as? TalentImageGalleryViewController {
            talentImageGalleryViewController.talent = talent
            talentImageGalleryViewController.initialPage = (sender as? Int) ?? 0
            Analytics.log(event:currentAnalyticsEvent, action: .selectGallery, itemId: talent.id)
        }
    }

}

extension TalentDetailViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == filmographyCollectionView {
            return talent?.films?.count ?? 0
        }

        if let numPictures = talent?.gallery?.numPictures {
            return (numPictures - 1)
        }

        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: SimpleImageCollectionViewCell.BaseReuseIdentifier, for: indexPath)
        guard let cell = collectionViewCell as? SimpleImageCollectionViewCell else {
            return collectionViewCell
        }

        if collectionView == filmographyCollectionView {
            cell.imageURL = talent?.films?[indexPath.row].imageURL
        } else if collectionView == galleryCollectionView {
            cell.imageURL = talent?.gallery?.picture(atIndex: indexPath.row + 1)?.thumbnailImageURL
        }

        return cell
    }

}

extension TalentDetailViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == filmographyCollectionView {
            if let film = talent?.films?[indexPath.row], let delegate = ExperienceLauncher.delegate {
                delegate.didTapFilmography(forTitle: film.title, fromViewController: self)
                Analytics.log(event:currentAnalyticsEvent, action: .selectFilm, itemId: talent.id, itemName: film.title)
            }
        } else if collectionView == galleryCollectionView {
            self.performSegue(withIdentifier: SegueIdentifier.TalentImageGallery, sender: indexPath.row + 1)
        }
    }

}

extension TalentDetailViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.height
        let width = (height * (collectionView == filmographyCollectionView ? Constants.FilmographyCollectionViewItemAspectRatio : Constants.GalleryCollectionViewItemAspectRatio))
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == filmographyCollectionView {
            return Constants.FilmographyCollectionViewItemSpacing
        }

        return Constants.GalleryCollectionViewItemSpacing
    }

}
