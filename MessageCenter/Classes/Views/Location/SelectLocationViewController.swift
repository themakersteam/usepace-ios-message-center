//
//  SelectLocationViewController.swift
//  MessageCenter
//
//  Created by Muhamed ALGHZAWI on 27/11/2018.
//

import Foundation
import UIKit
import MapKit

public class SelectLocationViewController: UIViewController {
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapButtonsContainer: UIStackView!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var mapSettingsView: UIView!
    
    @IBOutlet weak var centerPin: UIImageView!
    @IBOutlet weak var mapSettingBtn: UIButton!
    @IBOutlet weak var myLocationBtn: UIButton!
    
    
    var isShowingMapSettings: Bool = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareView()
        
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    @IBAction func showMapSettings(_ sender: Any) {
        if isShowingMapSettings {
            return
        }
        
        isShowingMapSettings = true
        
        var newY = CGFloat(0)
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
    
    @IBAction func cencel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapMapView() {
        if isShowingMapSettings {
            self.dismissSettings(self)
            
        }
        
    }
    
    @objc func didHoldMapView(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            
            print("Hoold")
        }
    }
}

// - MARK: Map Implementation
extension SelectLocationViewController {
    
    func prepareView() {
        
        let mapTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapMapView))
        let mapLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.didHoldMapView))
        
        
        self.mapView.addGestureRecognizer(mapTapGesture)
        self.mapView.addGestureRecognizer(mapLongPressGesture)
        
        
        mapSettingsView.transform = CGAffineTransform(translationX: 0, y: self.view.frame.height)
        
        
        centerPin.image = UIImage(named: "btn_selected", in: Bundle(for: MessageCenter.self), compatibleWith: nil)
        
        applyCornerRadius(to: self.mapSettingsView, corners: [.topRight, .topLeft])
        
        self.applyCornerRadius(to: myLocationBtn, corners: [.bottomRight, .bottomLeft])
        
        self.applyCornerRadius(to: mapSettingBtn, corners: [.topLeft, .topRight])
        
    }
    
    func applyCornerRadius(to view: UIView, corners: UIRectCorner) {
        
        let path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: 8, height: 8))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        view.layer.mask = mask
        
    }
    
}


extension SelectLocationViewController {
    class func present(on vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        let podBundle = Bundle(for: MessageCenter.self)
        let locVC = SelectLocationViewController(nibName: "SelectLocationView", bundle: podBundle)
        
        vc.present(locVC, animated: animated, completion: completion)
    }
}

