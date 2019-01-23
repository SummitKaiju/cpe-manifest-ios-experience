//
//  TalentImageGalleryViewController.swift
//

import UIKit
import CPEData

class TalentImageGalleryViewController: SceneDetailViewController {

    fileprivate struct Constants {
        static let CollectionViewItemSpacing: CGFloat = 10
        static let CollectionViewItemAspectRatio: CGFloat = 3 / 4
    }

    @IBOutlet weak fileprivate var galleryScrollView: ImageGalleryScrollView!
    @IBOutlet weak private var galleryCollectionView: UICollectionView!

    var talent: Person!
    @objc var initialPage = 0

    private var galleryDidScrollToPageObserver: NSObjectProtocol?

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        galleryScrollView.cleanInvisibleImages()
    }

    override func viewDidLoad() {
        self.title = String.localize("talentdetail.gallery")

        super.viewDidLoad()

        galleryScrollView.currentPage = initialPage
        galleryScrollView.removeToolbar()

        galleryDidScrollToPageObserver = NotificationCenter.default.addObserver(forName: .imageGalleryDidScrollToPage, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
            if let strongSelf = self, let page = notification.userInfo?[NotificationConstants.page] as? Int {
                let pageIndexPath = IndexPath(item: page, section: 0)
                strongSelf.galleryCollectionView.selectItem(at: pageIndexPath, animated: false, scrollPosition: UICollectionView.ScrollPosition())

                var cellIsShowing = false
                for cell in strongSelf.galleryCollectionView.visibleCells {
                    if let indexPath = strongSelf.galleryCollectionView.indexPath(for: cell), indexPath.row == page {
                        cellIsShowing = true
                        break
                    }
                }

                if !cellIsShowing {
                    strongSelf.galleryCollectionView.scrollToItem(at: pageIndexPath, at: .centeredHorizontally, animated: true)
                }
            }
        })

        galleryCollectionView.register(UINib(nibName: SimpleImageCollectionViewCell.NibName, bundle: Bundle.frameworkResources), forCellWithReuseIdentifier: SimpleImageCollectionViewCell.BaseReuseIdentifier)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let gallery = talent.gallery {
            galleryScrollView.load(with: gallery)
            galleryScrollView.gotoPage(initialPage, animated: false)
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return (DeviceType.IS_IPAD ? .landscape : .portrait)
    }

}

extension TalentImageGalleryViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (talent.gallery?.numPictures ?? 0)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: SimpleImageCollectionViewCell.BaseReuseIdentifier, for: indexPath)
        guard let cell = collectionViewCell as? SimpleImageCollectionViewCell else {
            return collectionViewCell
        }

        cell.showsSelectedBorder = true
        cell.isSelected = (indexPath.row == galleryScrollView.currentPage)
        cell.imageURL = talent.gallery?.picture(atIndex: indexPath.row)?.thumbnailImageURL
        return cell
    }

}

extension TalentImageGalleryViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        galleryScrollView.gotoPage(indexPath.row, animated: true)
        Analytics.log(event: .extrasTalentGalleryAction, action: .selectImage, itemId: talent.id)
    }

}

extension TalentImageGalleryViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.height
        return CGSize(width: height * Constants.CollectionViewItemAspectRatio, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.CollectionViewItemSpacing
    }

}
