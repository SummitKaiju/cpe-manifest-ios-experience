//
//  ExtrasShoppingItemsViewController.swift
//

import UIKit
import CPEData

class ExtrasShoppingItemsViewController: UIViewController {

    fileprivate struct Constants {
        static let ItemSpacing: CGFloat = 12
        static let LineSpacing: CGFloat = 12
        static let Padding: CGFloat = 15
        static let ItemAspectRatio: CGFloat = 338 / 230
    }

    @IBOutlet weak private var productsCollectionView: UICollectionView!

    @objc var products: [ProductItem]? {
        didSet {
            productsCollectionView.reloadData()
            if let products = products, products.count > 0 {
                let newIndex = IndexPath(item: 0, section: 0)
                self.productsCollectionView.scrollToItem(at: newIndex, at: .top, animated: false)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        productsCollectionView.register(UINib(nibName: ShoppingSceneDetailCollectionViewCell.NibName, bundle: Bundle.frameworkResources), forCellWithReuseIdentifier: ShoppingSceneDetailCollectionViewCell.ReuseIdentifier)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        productsCollectionView.collectionViewLayout.invalidateLayout()
    }

}

extension ExtrasShoppingItemsViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (products?.count ?? 0)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: ShoppingSceneDetailCollectionViewCell.ReuseIdentifier, for: indexPath)
        guard let cell = collectionViewCell as? ShoppingSceneDetailCollectionViewCell else {
            return collectionViewCell
        }

        cell.titleLabel?.removeFromSuperview()
        cell.productImageType = .scene
        if let products = products, products.count > indexPath.row {
            cell.products = [products[indexPath.row]]
        }

        return cell
    }

}

extension ExtrasShoppingItemsViewController: UICollectionViewDelegate {

     func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let shoppingDetailViewController = UIStoryboard.viewController(for: ShoppingDetailViewController.self) as? ShoppingDetailViewController, let cell = collectionView.cellForItem(at: indexPath) as? ShoppingSceneDetailCollectionViewCell {
            shoppingDetailViewController.products = cell.products
            shoppingDetailViewController.modalPresentationStyle = (DeviceType.IS_IPAD ? .overCurrentContext : .overFullScreen)
            shoppingDetailViewController.modalTransitionStyle = .crossDissolve
            self.present(shoppingDetailViewController, animated: true, completion: nil)
            Analytics.log(event: .extrasShopAction, action: .selectProduct, itemName: cell.products?.first?.name)
        }
    }

}

extension ExtrasShoppingItemsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var itemWidth: CGFloat
        if DeviceType.IS_IPAD {
            itemWidth = (collectionView.frame.width / 2) - (Constants.ItemSpacing * 2)
        } else {
            itemWidth = collectionView.frame.width
        }

        return CGSize(width: itemWidth, height: itemWidth / Constants.ItemAspectRatio)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.LineSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.ItemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: Constants.Padding, left: Constants.Padding, bottom: Constants.Padding, right: Constants.Padding)
    }

}
