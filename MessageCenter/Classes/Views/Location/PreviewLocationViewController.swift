//
//  PreviewLocationViewController.swift
//  MessageCenter
//
//  Created by Muhamed ALGHZAWI on 26/12/2018.
//

import UIKit
import MapKit

class PreviewLocationViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var backBtn: UIButton!
    
    var lat: Double?
    var long: Double?
    var locationTitle: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.prepareView()
    }
    
    
    private func prepareView() {
        navItem.title = self.locationTitle
        backBtn.setTitle("close".localized, for: .normal)
        for type in MapType.allCases {
            self.segmentedControl.setTitle(type.localizedName, forSegmentAt: type.rawValue)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        guard let lat = self.lat, let long = self.long else {
            return
        }
        
        let desierdLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let pin = DropPin()
        pin.coordinate = desierdLocation
        pin.title = locationTitle
        self.mapView!.addAnnotation(pin)
        self.mapView.setRegion(MKCoordinateRegion(center: desierdLocation, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)), animated: true)
    }
    
    @IBAction func mapTypeSelected(_ sender: Any) {
        guard let type = MapType(rawValue: self.segmentedControl.selectedSegmentIndex) else {
            return
        }
        self.mapView.mapType = type.mkMapType
    }
    
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func showNavigation(_ sender: Any) {
        self.showNavigationOptions()
    }
    
     private func showNavigationOptions() {
        guard let lat = self.lat, let long = self.long else {
            return
        }
        
        let navigationOptionsSheet = UIAlertController(title: self.locationTitle, message: "", preferredStyle: .actionSheet)
        
        let supportedNavApps = NavigationApps.listSupported()
        for app in supportedNavApps {
            let btn = UIAlertAction(title: app.actionTitle, style: .default) { action in
                app.open(withCoordinates: lat, long: long)
            }
            navigationOptionsSheet.addAction(btn)
        }
        
        let cancelBtn = UIAlertAction(title: "cancel".localized, style: .cancel, handler: nil)
        navigationOptionsSheet.addAction(cancelBtn)
        
        self.present(navigationOptionsSheet, animated: true, completion: nil)
    }
}

// -MARK: Class Helpers
extension PreviewLocationViewController {
    class func present(on vc: UIViewController, lat: Double, long: Double, title: String, animated: Bool = true, completion: (() -> Void)? = nil) {
        
        let podBundle = Bundle.bundleForXib(PreviewLocationViewController.self)
        let previewLocationVC = PreviewLocationViewController(nibName: "PreviewLocationView", bundle: podBundle)
        previewLocationVC.lat = lat
        previewLocationVC.long = long
        previewLocationVC.locationTitle = title
        vc.present(previewLocationVC, animated: animated, completion: completion)
    }
}


