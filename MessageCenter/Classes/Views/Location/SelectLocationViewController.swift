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

enum MapType: Int, CaseIterable {
    case map = 0, hybrid, satellite
    
    var localizedName: String {
        get {
            switch self {
            case .map:
                return "send_location.map_settings.map_types.map".localized
            case .hybrid:
                return "send_location.map_settings.map_types.hybrid".localized
            case .satellite:
                return "send_location.map_settings.map_types.satellite".localized
            }
        }
    }
    
    var mkMapType : MKMapType {
        switch self {
        case .map:
            return .standard
        case .hybrid:
            return .hybrid
        case .satellite:
            return .satellite
        }
    }
}

public class SelectLocationViewController: UIViewController {
    
 
    @IBOutlet weak var navItem: UINavigationItem!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapButtonsContainer: UIStackView!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var mapSettingsView: UIView!
    
    @IBOutlet weak var mapSettingBtn: UIButton!
    @IBOutlet weak var myLocationBtn: UIButton!
    @IBOutlet weak var sendLocationBtn: UIButton!
    
    var didInitiallyZoomed: Bool = false
    let locationManager = CLLocationManager()
    var isShowingMapSettings: Bool = false
    
    var isMyLocationSelected: Bool = false {
        didSet {
            self.myLocationBtn.setTitle(self.isMyLocationSelected ? "*" : ".", for: .normal)
            sendLocationBtn.setTitle(isMyLocationSelected ? "send_location.send_button.case_my_location.title".localized : "send_location.send_button.case_pin_location.title".localized, for: .normal)
        }
    }
    
    var currentUserLocationRegion: MKCoordinateRegion?;
    var isMyLocationEnabled: Bool = false {
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
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navItem.title = "send_location.title".localized
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.prepareView()
        self.authorizeForMyLocation()
    }
    
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
    
    @objc func didTapMapView() {
        if isShowingMapSettings {
            self.dismissSettings(self)
        }
    }
    
    @objc func didHoldMapView(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }
        if isMyLocationSelected {
            // You cannot place a pin while your location is selected.
            return
        }
        
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
    }
    
    @IBAction func sendLocation(_ sender: Any) {
        print("send location!")
    }
    
    @IBAction func cencel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
}

extension SelectLocationViewController {
    
    func prepareView() {
        
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
    
    func authorizeForMyLocation() {
        
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
            break
            // Show Message
            
        case .restricted:
            break
        }
    }
}

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

extension SelectLocationViewController : CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            isMyLocationEnabled = true
        } else {
            isMyLocationEnabled = false
        }
    }
}

extension SelectLocationViewController {
    class func present(on vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        let podBundle = Bundle(for: MessageCenter.self)
        let locVC = SelectLocationViewController(nibName: "SelectLocationView", bundle: podBundle)
        
        vc.present(locVC, animated: animated, completion: completion)
    }
}


class DropPin : MKPointAnnotation {
    
}
