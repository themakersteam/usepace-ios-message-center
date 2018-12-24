//
//  SelectLocationViewController.swift
//  MessageCenter
//
//  Created by Muhamed ALGHZAWI on 27/11/2018.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

protocol SelectLocationDelegate {
    func userDidSelect(location uri: String?)
    func userDidDismiss()
}


public class SelectLocationViewController: UIViewController {
    
    // -MARK: Outlets
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapButtonsContainer: UIStackView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var mapSettingsView: UIView!
    @IBOutlet weak var mapSettingBtn: UIButton!
    @IBOutlet weak var myLocationBtn: UIButton!
    @IBOutlet weak var sendLocationBtn: UIButton!
    @IBOutlet weak var sendLocationIcon: UIImageView!
    
    // -MARK: Properties
    var delegate: SelectLocationDelegate?
    private var clAuthorizationStatus: CLAuthorizationStatus?
    private var didInitiallyZoomed: Bool = false
    private let locationManager = CLLocationManager()
    private var isShowingMapSettings: Bool = false
    private var isMyLocationSelected: Bool = false {
        didSet {
            self.myLocationBtn.imageView?.tintColor = self.isMyLocationSelected ? .blue : .gray
        }
    }
    private var currentUserLocationRegion: MKCoordinateRegion?;
    private var isMyLocationEnabled: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.isMyLocationSelected = self.isMyLocationEnabled
                self.myLocationBtn.isEnabled = self.isMyLocationEnabled
                self.myLocationBtn.alpha = self.isMyLocationEnabled ? CGFloat(1) : CGFloat(0.9)
                if self.isMyLocationEnabled && !self.didInitiallyZoomed {
                    self.didInitiallyZoomed = true
                    self.setRegionToMyLocation()
                }
            }
        }
    }
    private var hasDroppedPin : Bool {
        get{
            return self.mapView!.annotations.contains(where: {$0 is DropPin})
        }
    }
    
    // -MARK: Initialization
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navItem.title = "send_location.title".localized
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        sendLocationBtn.setTitle("send_location.send_button.case_my_location.title".localized, for: .normal)
        self.prepareView()
        self.authorizeForMyLocation()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Shoe location message if needed.
        guard let locationAuthorizationStatus = self.clAuthorizationStatus else {
            return
        }
        
        if locationAuthorizationStatus == .authorizedAlways || locationAuthorizationStatus == .authorizedWhenInUse {
            return
        }
        
        let alert = UIAlertController(title: "send_location.title".localized, message: "send_location.location_disabled_notice.message".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok".localized, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func prepareView() {
        
        let mapTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapMapView))
        let mapLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.didHoldMapView))
        self.mapView.addGestureRecognizer(mapTapGesture)
        self.mapView.addGestureRecognizer(mapLongPressGesture)
        mapSettingsView.transform = CGAffineTransform(translationX: 0, y: self.view.frame.height)
        
        self.mapSettingsView!.applyCornerRadius(to: [.topRight, .topLeft])
        self.myLocationBtn!.applyCornerRadius(to: [.bottomRight, .bottomLeft])
        self.mapSettingBtn!.applyCornerRadius(to: [.topLeft, .topRight])
        
        
        for type in MapType.allCases {
            self.segmentedControl.setTitle(type.localizedName, forSegmentAt: type.rawValue)
        }
    }
    private func authorizeForMyLocation() {
        
        if !CLLocationManager.locationServicesEnabled() {
            isMyLocationEnabled = false
            return
        }
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            isMyLocationEnabled = true
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            isMyLocationEnabled = false
        case .restricted:
            isMyLocationEnabled = false
        }
        
        self.clAuthorizationStatus = authorizationStatus
    }
    
    // -MARK: Outlet Actions
    @IBAction func mapTypeSelected(_ sender: Any) {
        
        guard let type = MapType(rawValue: self.segmentedControl.selectedSegmentIndex) else {
            return
        }
        
        self.mapView.mapType = type.mkMapType
    }
    @IBAction func invokeMyLocation(_ sender: Any) {
        if !self.isMyLocationEnabled {
            // Cannot select my location if it's not enabled
            return
        }
        // Flip isMyLocationSelected, i.e.: Enable, Disable adding an annotation.
        isMyLocationSelected = !isMyLocationSelected
        
        if isMyLocationSelected {
            setRegionToMyLocation()
        }
        
        switchSendButtonState()
    }
    @IBAction func showMapSettings(_ sender: Any) {
        if isShowingMapSettings {
            return
        }
        isShowingMapSettings = true
        
        var newY = CGFloat(0)
        // If > iOS 10, iPhone X is supported.. count for safeArea
        if #available(iOS 11.0, *) {
            newY = self.view.safeAreaInsets.bottom
        }
        
        UIView.animate(withDuration: 0.3) {
            self.mapButtonsContainer.alpha = CGFloat(0)
            self.mapView.alpha = CGFloat(0.8)
            self.mapSettingsView.transform = CGAffineTransform(translationX: 0, y: newY)
        }
    }
    @IBAction func dismissSettings(_ sender: Any) {
        if !isShowingMapSettings {
            return
        }
        isShowingMapSettings = false
        
        UIView.animate(withDuration: 0.2) {
            self.mapButtonsContainer.alpha = CGFloat(1)
            self.mapView.alpha = CGFloat(1)
            self.mapSettingsView.transform = CGAffineTransform(translationX: 0, y: self.view.frame.height)
        }
    }
    @IBAction func sendLocation(_ sender: Any) {
        
        var choosenCoordinates: CLLocationCoordinate2D?
        if hasDroppedPin, let pin = self.mapView!.annotations.first(where: {$0 is DropPin}) {
            choosenCoordinates = pin.coordinate
        } else if !isMyLocationEnabled {
            // If the user has the location services disabled and he hasn't selected any location yet.
            return
        } else if let userLocation = locationManager.location {
            choosenCoordinates = userLocation.coordinate
        }
        
        guard let finalCoordinates = choosenCoordinates else {
            self.delegate?.userDidSelect(location: nil)
            return
        }
        
        let locationUri = "location://?lat=\(finalCoordinates.latitude)&long=\(finalCoordinates.longitude)"
//        let locationUri = "\(finalCoordinates.latitude),\(finalCoordinates.longitude)"
        self.delegate?.userDidSelect(location: locationUri)
    }
    @IBAction func cencel(_ sender: Any) {
        self.delegate?.userDidDismiss()
        self.dismiss(animated: true, completion: nil)
    }
    
    // -MARK: Private Funcs
    private func switchSendButtonState() {
        
        if hasDroppedPin {
            sendLocationBtn.setTitle("send_location.send_button.case_pin_location.title".localized, for: .normal)
            sendLocationIcon.image = UIImage(named: "icredpin.png", in: Bundle(for: MessageCenter.self), compatibleWith: nil)
        }
        else  {
            sendLocationBtn.setTitle("send_location.send_button.case_my_location.title".localized, for: .normal)
            sendLocationIcon.image = UIImage(named: "sendlocation.png", in: Bundle(for: MessageCenter.self), compatibleWith: nil)
        } 
    }
    private func setRegionToMyLocation(){
        guard let loc = self.locationManager.location else {
            return
        }
        
        // Remove any annotations since my location will be disgnated location:
        if self.mapView!.annotations.count > 0{
            self.mapView!.removeAnnotations(self.mapView!.annotations)
        }
        
        // Set region w/ animation to my location:
        let span = MKCoordinateSpanMake(0.01, 0.01)
        self.currentUserLocationRegion = MKCoordinateRegionMake(loc.coordinate, span)
        self.mapView.setRegion(self.currentUserLocationRegion!, animated: true)
    }
    @objc private func didTapMapView() {
        if isShowingMapSettings {
            self.dismissSettings(self)
        }
    }
    @objc private func didHoldMapView(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }
        if self.isMyLocationSelected{
            self.isMyLocationSelected = false
        }
        //        if isMyLocationSelected {
        //            // You cannot place a pin while your location is selected.
        //            return
        //        }
        
        let pin = DropPin()
        let point = sender.location(in: self.mapView!)
        let location = self.mapView!.convert(point, toCoordinateFrom: self.mapView!)
        pin.coordinate = location
        // Remove any existed pins before placing a new one:
        if self.mapView!.annotations.count > 0 {
            self.mapView!.removeAnnotations(self.mapView!.annotations)
        }
        
        // Place a pin!
        self.mapView!.addAnnotation(pin)
        
        switchSendButtonState()
    }
    
}

// -MARK: MKMapViewDelegate Implementation
extension SelectLocationViewController : MKMapViewDelegate {
    
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if isMyLocationSelected, let coord = currentUserLocationRegion?.center {
            let epsilon = 0.0001
            if abs(mapView.region.center.latitude - coord.latitude) <= epsilon && abs(mapView.region.center.longitude -  coord.longitude) <= epsilon {
                // Same region w/ margin error
                return
            }
            else {
                // User changed the region
                self.isMyLocationSelected = false
            }
        }
    }
}

// -MARK: CLLocationManagerDelegate Implementation
extension SelectLocationViewController : CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            isMyLocationEnabled = true
        } else {
            isMyLocationEnabled = false
        }
    }
}


// -MARK: Class Helpers
extension SelectLocationViewController {
    class func present(on vc: UIViewController, withDelegate delegate: SelectLocationDelegate, animated: Bool = true, completion: (() -> Void)? = nil) {
        
        let podBundle = Bundle.bundleForXib(SelectLocationViewController.self)
        let selectLocationVC = SelectLocationViewController(nibName: "SelectLocationView", bundle: podBundle)
        selectLocationVC.delegate = delegate
        vc.present(selectLocationVC, animated: animated, completion: completion)
    }
}


