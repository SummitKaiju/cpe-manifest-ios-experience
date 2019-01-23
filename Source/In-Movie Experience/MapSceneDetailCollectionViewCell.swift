//
//  MapSceneDetailCollectionViewCell.swift
//

import MapKit

class MapSceneDetailCollectionViewCell: SceneDetailCollectionViewCell {

    @objc static let NibName = "MapSceneDetailCollectionViewCell"
    @objc static let ReuseIdentifier = "MapSceneDetailCollectionViewCellReuseIdentifier"

    @IBOutlet weak var mapView: MultiMapView!

    override func timedEventDidChange() {
        super.timedEventDidChange()

        if let location = timedEvent?.location {
            mapView.setLocation(location.centerPoint, zoomLevel: location.zoomLevel - 4, animated: false, adjustView: false)
            _ = mapView.addMarker(location.centerPoint, title: location.name, subtitle: location.address, icon: location.iconImage, autoSelect: false)
        }

        mapView.isUserInteractionEnabled = false
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        mapView.clear()
    }

}
