//
//  ShoppingSceneDetailCollectionViewCell.swift
//

import Foundation
import UIKit
import CPEData

enum ShoppingProductImageType {
    case product
    case scene
}

class ShoppingSceneDetailCollectionViewCell: SceneDetailCollectionViewCell {

    @objc static let NibName = "ShoppingSceneDetailCollectionViewCell"
    @objc static let ReuseIdentifier = "ShoppingSceneDetailCollectionViewCellReuseIdentifier"

    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var bullseyeImageView: UIImageView!
    @IBOutlet weak private var extraDescriptionLabel: UILabel!

    var productImageType = ShoppingProductImageType.product

    private var extraDescription: String? {
        set {
            extraDescriptionLabel?.text = newValue
        }

        get {
            return extraDescriptionLabel?.text
        }
    }

    private var currentProduct: ProductItem? {
        didSet {
            if currentProduct != oldValue {
                descriptionText = currentProduct?.brand
                extraDescription = currentProduct?.name
                if productImageType == .scene {
                    setImageURL(currentProduct?.sceneImageURL ?? currentProduct?.productImageURL)
                } else {
                    setImageURL(currentProduct?.productImageURL)
                }
            }

            if currentProduct == nil {
                currentProductFrameTime = -1
            }
        }
    }

    private var currentProductFrameTime = -1.0
    private var currentProductSessionDataTask: URLSessionDataTask?
    @objc var products: [ProductItem]? {
        didSet {
            currentProduct = products?.first
        }
    }

    override func currentTimeDidChange() {
        if let timedEvent = timedEvent, timedEvent.isType(.product) {
            if let product = timedEvent.product {
                products = [product]
            } else {
                DispatchQueue.global(qos: .userInteractive).async {
                    if let productAPIUtil = CPEXMLSuite.Settings.productAPIUtil {
                        let newFrameTime = productAPIUtil.closestFrameTime(self.currentTime)
                        if newFrameTime != self.currentProductFrameTime {
                            self.currentProductFrameTime = newFrameTime

                            if let currentTask = self.currentProductSessionDataTask {
                                currentTask.cancel()
                            }

                            self.currentProductSessionDataTask = productAPIUtil.getFrameProducts(self.currentProductFrameTime, completion: { [weak self] (products) -> Void in
                                self?.currentProductSessionDataTask = nil
                                DispatchQueue.main.async {
                                    self?.products = products
                                }
                            })
                        }
                    }
                }
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        products = nil
        bullseyeImageView.isHidden = true

        if let task = currentProductSessionDataTask {
            task.cancel()
            currentProductSessionDataTask = nil
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if productImageType == .scene, let product = currentProduct, product.bullseyePoint != CGPoint.zero {
            var bullseyeFrame = bullseyeImageView.frame
            let bullseyePoint = CGPoint(x: imageView.frame.width * product.bullseyePoint.x, y: imageView.frame.height * product.bullseyePoint.y)
            bullseyeFrame.origin = CGPoint(x: bullseyePoint.x + imageView.frame.minX - (bullseyeFrame.width / 2), y: bullseyePoint.y + imageView.frame.minY - (bullseyeFrame.height / 2))
            bullseyeImageView.frame = bullseyeFrame

            bullseyeImageView.layer.shadowColor = UIColor.black.cgColor
            bullseyeImageView.layer.shadowOffset = CGSize(width: 1, height: 1)
            bullseyeImageView.layer.shadowOpacity = 0.75
            bullseyeImageView.layer.shadowRadius = 2
            bullseyeImageView.clipsToBounds = false
            bullseyeImageView.isHidden = false
        } else {
            bullseyeImageView.isHidden = true
        }
    }

    private func setImageURL(_ imageURL: URL?) {
        if let url = imageURL {
            imageView.contentMode = .scaleAspectFit
            imageView.sd_setImage(with: url)
        } else {
            imageView.sd_cancelCurrentImageLoad()
            imageView.image = nil
        }
    }

}
