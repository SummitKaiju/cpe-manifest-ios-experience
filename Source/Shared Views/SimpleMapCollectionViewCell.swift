//
//  SimpleMapCollectionViewCell.swift
//

import UIKit
import MapKit

class SimpleMapCollectionViewCell: UICollectionViewCell {

    @objc static let NibName = "SimpleMapCollectionViewCell"
    @objc static let ReuseIdentifier = "SimpleMapCollectionViewCellReuseIdentifier"

    @IBOutlet weak private var mapView: MultiMapView!
    @IBOutlet weak private var mapTextLabel: UILabel?

    @objc func setLocation(_ location: CLLocationCoordinate2D, zoomLevel: Int) {
        mapView.setLocation(location, zoomLevel: zoomLevel, animated: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        mapTextLabel?.text = String.localize("locations.map")
    }

}
