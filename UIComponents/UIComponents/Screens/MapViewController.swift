//
//  MapViewController.swift
//  UIComponents
//
//  Created by Semih Emre ÜNLÜ on 9.01.2022.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    var myRouteArray = [MKPolyline]()
    var myRenderArray = [MKPolylineRenderer]()
    var activeNumber = 0
    
    private var currentCoordinate : CLLocationCoordinate2D?
    private var destinationCoordinate : CLLocationCoordinate2D?
    
    private lazy var locationManager : CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        return locationManager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        checkLocationPermission()
        addLongGestureRecognizer()
    }

    func addLongGestureRecognizer() {
        let longPressGesture = UILongPressGestureRecognizer(target: self,
                                                            action: #selector(handleLongPressGesture(_ :)))
        self.view.addGestureRecognizer(longPressGesture)
    }

    @objc func handleLongPressGesture(_ sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        destinationCoordinate = coordinate

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Pinned"
        mapView.addAnnotation(annotation)
    }

    func checkLocationPermission() {
        switch self.locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            locationManager.requestLocation()
        case .denied, .restricted:
            //popup gosterecegiz. go to settings butonuna basildiginda
            //kullaniciyi uygulamamizin settings sayfasina gonder
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            fatalError()
        }
    }

    @IBAction func showCurrentLocationTapped(_ sender: UIButton) {
        locationManager.requestLocation()
    }

    @IBAction func drawRouteButtonTapped(_ sender: UIButton) {
        guard let currentCoordinate = currentCoordinate,
              let destinationCoordinate = destinationCoordinate else {
                  // log
                  // alert
            return
        }

        let sourcePlacemark = MKPlacemark(coordinate: currentCoordinate)
        let source = MKMapItem(placemark: sourcePlacemark)

        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        let destination = MKMapItem(placemark: destinationPlacemark)

        let directionRequest = MKDirections.Request()
        directionRequest.source = source
        directionRequest.destination = destination
        directionRequest.transportType = .automobile
        directionRequest.requestsAlternateRoutes = true

        let direction = MKDirections(request: directionRequest)

        direction.calculate { response, error in
            guard error == nil else {
                //log error
                //show error
                print(error?.localizedDescription)
                return
            }

            guard let polyline: MKPolyline = response?.routes.first?.polyline else { return }
            self.mapView.addOverlay(polyline, level: .aboveLabels)

            let rect = polyline.boundingMapRect
            let region = MKCoordinateRegion(rect)
            self.mapView.setRegion(region, animated: true)
            
            for route in response?.routes ?? [] {
                self.myRouteArray.append(route.polyline)
            }
            self.mapView.addOverlays(self.myRouteArray, level: .aboveLabels)
        }
    }

    @IBAction func backRouteButton(_ sender: UIButton) {
        let index = myRenderArray.count
        
        if activeNumber == 0 {
            myRenderArray[activeNumber].strokeColor = .red
            activeNumber = index - 1
            myRenderArray[activeNumber].strokeColor = .systemRed
            let rect = self.myRouteArray[activeNumber].boundingMapRect
            let region = MKCoordinateRegion(rect)
            self.mapView.setRegion(region, animated: true)
            self.mapView.overlays(in: .aboveLabels)
        } else {
            myRenderArray[activeNumber].strokeColor = .red
            activeNumber = index - 1
            myRenderArray[activeNumber].strokeColor = .systemRed
            let rect = self.myRouteArray[activeNumber].boundingMapRect
            let region = MKCoordinateRegion(rect)
     
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    @IBAction func forwardRouteButton(_ sender: UIButton) {
        let index = myRenderArray.count
        if activeNumber < index - 1 {
            myRenderArray[activeNumber].strokeColor = .systemGray
            activeNumber = activeNumber + 1
            myRenderArray[activeNumber].strokeColor = .gray
            let rect = self.myRouteArray[activeNumber].boundingMapRect
            let region = MKCoordinateRegion(rect)
            self.mapView.setRegion(region, animated: true)
        } else {
            myRenderArray[activeNumber].strokeColor = .systemGray
            activeNumber = 0
            myRenderArray[activeNumber].strokeColor = .gray
            let rect = self.myRouteArray[activeNumber].boundingMapRect
            let region = MKCoordinateRegion(rect)
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.first?.coordinate else { return }
        currentCoordinate = coordinate
        print("latitude: \(coordinate.latitude)")
        print("longitude: \(coordinate.longitude)")

        mapView.setCenter(coordinate, animated: true)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationPermission()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {

    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        myRenderArray.append(renderer)
        for renderer in myRenderArray {
            if myRenderArray.count > 2 {
                myRenderArray[0].strokeColor = .systemRed
                myRenderArray[1].strokeColor = .systemGray
                myRenderArray[2].strokeColor = .systemBrown
            } else {
                renderer.strokeColor = .red
            }
        }
        return renderer
    }
}
