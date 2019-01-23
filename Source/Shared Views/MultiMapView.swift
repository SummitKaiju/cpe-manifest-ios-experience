//
//  MultiMapView.swift
//

import UIKit
import MapKit
import GoogleMaps
import CPEData

protocol MultiMapViewDelegate: class {
    func mapView(_ mapView: MultiMapView, didTapMarker marker: MultiMapMarker)
}

class MultiMapMarker: NSObject {
    @objc var dataObject: AnyObject?
    @objc var appleMapAnnotation: MKAnnotation?
    @objc var googleMapMarker: GMSMarker?
    var location: CLLocationCoordinate2D!
}

enum MultiMapType: Int {
    case road = 0
    case satellite = 1
}

class MultiMapView: UIView, MKMapViewDelegate, GMSMapViewDelegate {

    private struct Constants {
        static let MarkerAnnotationViewReuseIdentifier = "kMarkerAnnotationViewReuseIdentifier"
        static let ControlsPadding: CGFloat = (DeviceType.IS_IPAD ? 18 : 8)
        static let SegmentedControlWidth: CGFloat = (DeviceType.IS_IPAD ? 185 : 135)
        static let SegmentedControlHeight: CGFloat = (DeviceType.IS_IPAD ? 30 : 25)
        static let ZoomButtonWidth: CGFloat = (DeviceType.IS_IPAD ? 30 : 25)
        static let ZoomFitAllPadding: CGFloat = (DeviceType.IS_IPAD ? 50 : 20)
    }

    private var appleMapView: MKMapView?
    private var googleMapView: GMSMapView?
    private var mapTypeSegmentedControl: UISegmentedControl?
    private var zoomInButton: UIButton?
    private var zoomOutButton: UIButton?
    private var mapIconImage: UIImage?
    private var mapMarkers = [MultiMapMarker]()

    weak var delegate: MultiMapViewDelegate?

    @objc var maxZoomLevel: Int = -1 {
        didSet {
            if let mapView = googleMapView {
                mapView.setMinZoom(kGMSMinZoomLevel, maxZoom: (maxZoomLevel > 0 ? Float(maxZoomLevel) : kGMSMaxZoomLevel))
            }
        }
    }

    @objc var selectedMarker: MultiMapMarker? {
        didSet {
            if let mapView = googleMapView {
                mapView.selectedMarker = selectedMarker?.googleMapMarker
            } else if let mapView = appleMapView, let marker = selectedMarker?.appleMapAnnotation {
                mapView.selectAnnotation(marker, animated: true)
            }
        }
    }

    var mapType: MultiMapType = .road {
        didSet {
            if let mapView = googleMapView {
                mapView.mapType = (mapType == .satellite ? GMSMapViewType.satellite : GMSMapViewType.normal)
                self.addSubview(googleMapView!)
            } else if let mapView = appleMapView {
                mapView.mapType = (mapType == .satellite ? MKMapType.satellite : MKMapType.standard)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        if CPEXMLSuite.Settings.mapsAPIService == .googleMaps && googleMapView == nil {
            googleMapView = GMSMapView(frame: self.bounds)
            googleMapView?.delegate = self
            self.addSubview(googleMapView!)
        } else if appleMapView == nil {
            appleMapView = MKMapView(frame: self.bounds)
            appleMapView?.delegate = self
            self.addSubview(appleMapView!)
        }

        mapType = .road
    }

    @objc func addControls() {
        let segmentedControl = UISegmentedControl(items: [String.localize("locations.map.type_standard"), String.localize("locations.map.type_satellite")])
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key(rawValue: convertFromNSAttributedStringKey(NSAttributedString.Key.font)): UIFont.themeCondensedFont(16)], for: .normal)
        segmentedControl.backgroundColor = UIColor.white
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.layer.cornerRadius = 5
        segmentedControl.addTarget(self, action: #selector(self.onMapTypeChanged), for: .valueChanged)
        segmentedControl.frame = CGRect(x: Constants.ControlsPadding, y: Constants.ControlsPadding, width: Constants.SegmentedControlWidth, height: Constants.SegmentedControlHeight)
        self.addSubview(segmentedControl)
        mapTypeSegmentedControl = segmentedControl

        let zoomInButton = UIButton(frame: CGRect(x: Constants.ControlsPadding, y: segmentedControl.frame.maxY + Constants.ControlsPadding, width: Constants.ZoomButtonWidth, height: Constants.ZoomButtonWidth))
        zoomInButton.setImage(UIImage(named: "MapZoomIn", in: Bundle.frameworkResources, compatibleWith: nil), for: .normal)
        zoomInButton.addTarget(self, action: #selector(self.zoomIn), for: .touchUpInside)
        self.addSubview(zoomInButton)
        self.zoomInButton = zoomInButton

        let zoomOutButton = UIButton(frame: CGRect(x: Constants.ControlsPadding, y: zoomInButton.frame.maxY, width: Constants.ZoomButtonWidth, height: Constants.ZoomButtonWidth))
        zoomOutButton.setImage(UIImage(named: "MapZoomOut", in: Bundle.frameworkResources, compatibleWith: nil), for: .normal)
        zoomOutButton.addTarget(self, action: #selector(self.zoomOut), for: .touchUpInside)
        self.addSubview(zoomOutButton)
        self.zoomOutButton = zoomOutButton
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        googleMapView?.frame = self.bounds
        appleMapView?.frame = self.bounds

        if let mapTypeSegmentedControl = mapTypeSegmentedControl {
            self.bringSubviewToFront(mapTypeSegmentedControl)
        }

        if let button = zoomInButton {
            self.bringSubviewToFront(button)
        }

        if let button = zoomOutButton {
            self.bringSubviewToFront(button)
        }
    }

    @objc func destroy() {
        delegate = nil
        googleMapView = nil
        appleMapView = nil
    }

    @objc func clear() {
        if let mapView = googleMapView {
            mapView.clear()
        } else if let mapView = appleMapView {
            mapView.removeAnnotations(mapView.annotations)
        }
    }

    @objc func setLocation(_ location: CLLocationCoordinate2D, zoomLevel: Int, animated: Bool, adjustView: Bool = !DeviceType.IS_IPAD) {
        if let mapView = googleMapView {
            var location = location
            if adjustView {
                let currentCamera = mapView.camera
                mapView.camera = GMSCameraPosition(target: currentCamera.target, zoom: Float(zoomLevel), bearing: currentCamera.bearing, viewingAngle: currentCamera.viewingAngle)

                var mapPoint = mapView.projection.point(for: location)
                mapPoint.y -= 70
                location = mapView.projection.coordinate(for: mapPoint)

                mapView.camera = currentCamera
            }

            if animated {
                mapView.animate(with: GMSCameraUpdate.setTarget(location, zoom: Float(zoomLevel)))
            } else {
                mapView.camera = GMSCameraPosition(target: location, zoom: Float(zoomLevel), bearing: mapView.camera.bearing, viewingAngle: mapView.camera.viewingAngle)
            }
        } else if let mapView = appleMapView {
            let span = MKCoordinateSpan.init(latitudeDelta: 0, longitudeDelta: 360 / pow(2.0, Double(zoomLevel)) * Double(mapView.frame.width) / 256)
            mapView.setRegion(MKCoordinateRegion.init(center: location, span: span), animated: animated)
        }
    }

    @objc func addMarker(_ location: CLLocationCoordinate2D, title: String?, subtitle: String?) -> MultiMapMarker {
        return addMarker(location, title: title, subtitle: subtitle, icon: nil, autoSelect: false)
    }

    @objc func addMarker(_ location: CLLocationCoordinate2D, title: String?, subtitle: String?, icon: UIImage?, autoSelect: Bool) -> MultiMapMarker {
        let multiMapMarker = MultiMapMarker()
        multiMapMarker.location = location

        if let mapView = googleMapView {
            let marker = GMSMarker(position: location)
            marker.title = title
            marker.icon = icon
            marker.snippet = subtitle
            marker.map = mapView
            multiMapMarker.googleMapMarker = marker

            if autoSelect {
                mapView.selectedMarker = marker
            }
        } else if let mapView = appleMapView {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            annotation.title = title
            annotation.subtitle = subtitle
            mapIconImage = icon
            mapView.addAnnotation(annotation)
            multiMapMarker.appleMapAnnotation = annotation

            if autoSelect {
                mapView.selectAnnotation(annotation, animated: true)
            }
        }

        mapMarkers.append(multiMapMarker)
        return multiMapMarker
    }

    @objc func zoomToFitAllMarkers() {
        zoomToFitMarkers(mapMarkers)
    }

    @objc func zoomToFitMarkers(_ markers: [MultiMapMarker]) {
        if let mapView = googleMapView {
            var bounds = GMSCoordinateBounds()
            for marker in markers {
                if let mapMarker = marker.googleMapMarker {
                    bounds = bounds.includingCoordinate(mapMarker.position)
                }
            }

            var edgeInsets: UIEdgeInsets
            if let segmentedControl = mapTypeSegmentedControl {
                edgeInsets = UIEdgeInsets(top: (Constants.ControlsPadding * 2) + segmentedControl.frame.height + Constants.ZoomFitAllPadding, left: (Constants.ControlsPadding * 2) + Constants.ZoomButtonWidth, bottom: Constants.ZoomFitAllPadding, right: Constants.ZoomFitAllPadding)
            } else {
                edgeInsets = UIEdgeInsets(top: Constants.ZoomFitAllPadding, left: Constants.ZoomFitAllPadding, bottom: Constants.ZoomFitAllPadding, right: Constants.ZoomFitAllPadding)
            }

            mapView.animate(with: GMSCameraUpdate.fit(bounds, with: edgeInsets))
        } else if let mapView = appleMapView {
            var annotations = [MKAnnotation]()
            for marker in markers {
                if let mapMarker = marker.appleMapAnnotation {
                    annotations.append(mapMarker)
                }
            }

            mapView.showAnnotations(annotations, animated: true)
        }
    }

    @objc func zoomIn() {
        if let mapView = googleMapView {
            mapView.animate(with: GMSCameraUpdate.zoomIn())
        }
    }

    @objc func zoomOut() {
        if let mapView = googleMapView {
            mapView.animate(with: GMSCameraUpdate.zoomOut())
        }
    }

    // MARK: Actions
    @objc func onMapTypeChanged() {
        if let mapTypeSegmentedControl = mapTypeSegmentedControl, let type = MultiMapType(rawValue: mapTypeSegmentedControl.selectedSegmentIndex) {
            mapType = type
            NotificationCenter.default.post(name: .locationsMapTypeDidChange, object: nil, userInfo: [NotificationConstants.mapType: type])
        }
    }

    // MARK: MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let mapIconImage = mapIconImage {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.MarkerAnnotationViewReuseIdentifier)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: Constants.MarkerAnnotationViewReuseIdentifier)
                annotationView?.image = mapIconImage
            }

            annotationView?.annotation = annotation

            return annotationView
        }

        return nil
    }

    // MARK: GMSMapViewDelegate
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if let marker = mapMarkers.first(where: { $0.googleMapMarker == marker }) {
            if let delegate = delegate {
                delegate.mapView(self, didTapMarker: marker)
            } else {
                selectedMarker = marker
            }
        }

        return true
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
