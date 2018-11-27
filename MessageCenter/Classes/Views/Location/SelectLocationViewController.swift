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
    
    @IBOutlet weak var centerPin: UIImageView!
    @IBOutlet weak var mapSettingBtn: UIButton!
    @IBOutlet weak var myLocationBtn: UIButton!
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareView()
        
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

    }
    
    @IBAction func cencel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

// - MARK: Map Implementation
extension SelectLocationViewController {
    
    func prepareView() {

        centerPin.image = UIImage(named: "btn_selected", in: Bundle(for: MessageCenter.self), compatibleWith: nil)
        
        self.applyMapButtonsStyle(to: myLocationBtn, corners: [.bottomRight, .bottomLeft])
        
        self.applyMapButtonsStyle(to: mapSettingBtn, corners: [.topLeft, .topRight])
        
    }
    
    func applyMapButtonsStyle(to btn: UIButton, corners: UIRectCorner) {
        
        let path = UIBezierPath(roundedRect: btn.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: 8, height: 8))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        btn.layer.mask = mask
        
    }
    
}


extension SelectLocationViewController {
    class func present(on vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        let podBundle = Bundle(for: MessageCenter.self)
        let locVC = SelectLocationViewController(nibName: "SelectLocationView", bundle: podBundle)
        
        vc.present(locVC, animated: animated, completion: completion)
    }
}

