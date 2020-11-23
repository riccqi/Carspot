//
//  ViewController.swift
//  Carspot
//
//  Created by Richard Qi on 6/7/20.
//  Copyright © 2020 Qi. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SwiftCSV
import FloatingPanel

class ViewController: UIViewController, UISearchBarDelegate, FloatingPanelControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBAction func locationCenter(_ sender: UIButton) {
        let location = self.locationManager.location?.coordinate
        self.mapView.setRegion(MKCoordinateRegion.init(center: location!, latitudinalMeters: self.regionInMeters, longitudinalMeters: self.regionInMeters), animated: true)
    }
    
    var selectedPin : MKPlacemark!
    static var fpc: FloatingPanelController!
    var directionsArray: [MKDirections] = []

    
    let defaults = UserDefaults.standard
    var csv: CSV?
    var csvNew: [String] = []
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 1800
    var carparks: [Info] = []
    //let cellReuseIdentifier = "CarCell"
    var spec: Specs!
    var nameAvail: [String] = []
    var specList = CPManager.shared.getFullCarpark()
    var x: Double?
    var y: Double?
    //var nearbyList: [String] = []
    
    
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    
    
    var resultSearchController: UISearchController? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getDirections), name: Notification.Name("mapped"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showSpinningWheel1(_:)), name: NSNotification.Name("x_coord"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showSpinningWheel2(_:)), name: NSNotification.Name("y_coord"), object: nil)
    }
    
    @objc func showSpinningWheel1(_ notification: NSNotification) {
//          print(notification.userInfo ?? "")
          if let dict = notification.userInfo as NSDictionary? {
              x = dict["x"] as? Double
          }
   }
    
    @objc func showSpinningWheel2(_ notification: NSNotification) {
//           print(notification.userInfo ?? "")
           if let dict = notification.userInfo as NSDictionary? {
               y = dict["y"] as? Double
           }
    }


    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate = CLLocationCoordinate2D(latitude: y!, longitude: x!)
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = false //can be true for multiple routes
        
        return request
    }
    
    func resetMapView(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        let _ = directionsArray.map { $0.cancel() }
        directionsArray.append(directions)
    }
    
    @objc func getDirections() {
        guard let location = locationManager.location?.coordinate else {
            //TODO alert we do not have their location
            print("error 1")
            return
        }
        
        let request = createDirectionsRequest(from: location)
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        
        directions.calculate { [unowned self] (response, error) in
            //TODO HANDLE ERROR
            guard let response = response else {return} //TODO alert
            
            //because response is an array of routes due to alternate routes
            for route in response.routes {
//                let steps = route.steps
                self.mapView.addOverlay(route.polyline)
                var regionRect = route.polyline.boundingMapRect


                let wPadding = regionRect.size.width * 0.25
                let hPadding = regionRect.size.height * 0.25

                //Add padding to the region
                regionRect.size.width += wPadding
                regionRect.size.height += hPadding

                //Center the region on the line
                regionRect.origin.x -= wPadding / 2
                regionRect.origin.y -= hPadding / 2

                self.mapView.setRegion(MKCoordinateRegion(regionRect), animated: true)
                let location = self.locationManager.location?.coordinate
                Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (nil) in
                    self.mapView.setRegion(MKCoordinateRegion.init(center: location!, latitudinalMeters: 500, longitudinalMeters: 500), animated: true)
                }
                
                //self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
            
        }
        
    }


    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {

        return MyFloatingPanelLayout()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        //searchCompleter.delegate = self
        checkLocationServices()

        let locationSearchTable = storyboard!.instantiateViewController(identifier: "SearchViewController") as SearchViewController
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        
        //passes something to searchviewcontroller
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        
        
        let searchBar = resultSearchController?.searchBar
        searchBar!.sizeToFit()
        searchBar!.placeholder = "Search for location"
        navigationItem.titleView = resultSearchController?.searchBar
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true

        ViewController.fpc = FloatingPanelController()

        // Assign self as the delegate of the controller.
        //fpc.delegate = self // Optional

        // Set a content view controller.
        guard let contentVC = storyboard?.instantiateViewController(identifier: "fpc_content") as? ModalViewController else {return}
        ViewController.fpc.set(contentViewController: contentVC)

        // Track a scroll view(or the siblings) in the content view controller.
        ViewController.fpc.track(scrollView: contentVC.myTableView)

        // Add and show the views managed by the `FloatingPanelController` object to self.view.
        ViewController.fpc.addPanel(toParent: self)
        
        

        let createdSql = defaults.bool(forKey: "createdsql")
        
        if createdSql == false {
            CPManager.shared.createDatabase()
            _ = CPManager.shared.createContent()
            defaults.set(true, forKey: "createdsql")
        }
        

        do {
            // From a file inside the app bundle, with a custom delimiter, errors, and custom encoding
            csv = try CSV(
                name: "hdb-carpark-information",
                extension: "csv",
                bundle: .main,
                encoding: .utf8)
            
        } catch {
            print("wtf")
            return
        }

        
        guard let url = URL(string: "https://api.data.gov.sg/v1/transport/carpark-availability") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                return
            }
            
            do {
                let entries = try JSONDecoder().decode(Items.self, from: data)
                for i in entries.items
                {
                    self.carparks.append(contentsOf: i.carpark_data)
                }
                
                for carpark in self.carparks
                {
                    if (self.csv?.namedColumns["car_park_no"]!.contains(carpark.carpark_number))!
                    {
                    
                        CPManager.shared.updateLots(carpark: carpark.carpark_number, dets: carpark.carpark_info)
                        self.nameAvail.append(carpark.carpark_number)
                        //print("appended \(carpark.carpark_number)")
                    }
                    else {
                        //print(carpark.carpark_number)
                        if createdSql == false {
                            CPManager.shared.filterCarpark(x: carpark)
                        }
                    }
                }
            
            }
            catch let error {
                print(error)
            }
            
        }.resume()
        
        //tableView.delegate = self
        //tableView.dataSource = self
    }
    
    
    //MAP STUFF FROM HERE ON
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            var mapCentre = location
            mapCentre.latitude = mapCentre.latitude - 0.006
            //mapCentre.longitude = mapCentre.longitud
            let region = MKCoordinateRegion.init(center: mapCentre, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            print(location)
            let placemark = MKPlacemark.init(coordinate: location)
            checkNearby(placemark: placemark)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        }
        else {
            //alert user to turn on
        }
    }
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true //can be done in storyboard too
            centerViewOnUserLocation()
            //locationManager.startUpdatingLocation() //using delegate method from below
            break
        case .denied:
            //show alert to turn on permission
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            //show alert to turn on permission
            break
        case .authorizedAlways:
            break
        @unknown default:
            //show alert to turn on permission
            break
        }
    }
    
    
    static var secondFpc: FloatingPanelController!
    
    
    override func show(_ vc: UIViewController, sender: Any?) {

        
        ViewController.secondFpc = FloatingPanelController()
        ViewController.secondFpc.delegate = self
        ViewController.secondFpc.isRemovalInteractionEnabled = true

        ViewController.secondFpc.set(contentViewController: vc)
        ViewController.secondFpc.surfaceView.contentInsets = .init(top: -25, left: 0, bottom: 15, right: 0)
        ViewController.secondFpc.surfaceView.containerMargins = .init(top: 20.0, left: 8.0, bottom: 20.0, right: 8.0)
        ViewController.secondFpc.surfaceView.cornerRadius = 26.0
        //secondFpc.surfaceView.borderWidth = 1.0 / traitCollection.displayScale
        //secondFpc.surfaceView.borderColor = UIColor.black.withAlphaComponent(0.2)
    
        ViewController.secondFpc.addPanel(toParent: self, animated: true)
        
        
    }
    
    
    
    func checkNearby(placemark: MKPlacemark) {
        //TODO FOR NEARBY PINS
        let nearby = CLCircularRegion(center: placemark.coordinate, radius: 600, identifier: "Nearby")
        nearbyList.nearbyList.removeAll()
        for speck in specList {
            //print("check")
            let lon = Double(speck.x_coord)!
            let lat = Double(speck.y_coord)!
            let coordinate = CLLocationCoordinate2DMake(lat, lon)
            if nearby.contains(coordinate) {
                nearbyList.nearbyList.append(speck.car_park_no)
                let nearbyAnn = MKPointAnnotation()
                nearbyAnn.coordinate = coordinate
                nearbyAnn.title = speck.car_park_no
                
                mapView.addAnnotation(nearbyAnn)
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newDataNotif"), object: nil)
        //handleDataTransferDelegate?.HandDataOver(list: nearbyList)
        //print(nearbyList)
        
    }

}

//extension of viewcontroller to contain all the delegates
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {return}
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}


protocol HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark)
}

extension ViewController: HandleMapSearch {
    
    func dropPinZoomIn(placemark: MKPlacemark) {
        selectedPin = placemark
        for i in mapView.annotations {
            mapView.removeAnnotation(i)
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.subtitle = "Searched Location"
        
        //TO REDO FOR MORE ACCURATE DISPLAY ON PIN
        if let city = placemark.locality, let state = placemark.administrativeArea {
            annotation.title = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
        var mapCor = annotation.coordinate
        mapCor.latitude = mapCor.latitude - 0.006
        let region = MKCoordinateRegion(center: mapCor, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)

        checkNearby(placemark: placemark)
        
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "AnnotationView")
        
        //let smallConfiguration = UIImage.SymbolConfiguration(scale: .large)
        if annotation.subtitle == "Searched Location" {
            annotationView.markerTintColor = .systemGreen
            
        }
        else {return nil}
        annotationView.canShowCallout = true
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .systemBlue
        
        return renderer
    }

}

class MyFloatingPanelLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .tip
    }

    var positionReference: FloatingPanelLayoutReference {
        return .fromSuperview
    }

    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
            // A top inset from safe area
            case .full: return 400.0
            case .half: return 500.0 // A bottom inset from the safe area
            case .tip: return 180.0 // A bottom inset from the safe area
            default: return nil // Or `case .hidden: return nil`
        }
    }
}

