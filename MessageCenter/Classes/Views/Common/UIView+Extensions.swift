//
//  UIView+Extensions.swift
//  Alamofire
//
//  Created by Muhamed ALGHZAWI on 28/11/2018.
//

import Foundation
import UIKit

extension UIView {
    public func applyCornerRadius(to corners: UIRectCorner) {
        
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: 8, height: 8))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
    
    public func selectedCornerRadius () {
        
        let path = UIBezierPath(roundedRect:self.bounds,
                                byRoundingCorners:[.topRight, .topLeft, .bottomLeft],
                                cornerRadii: CGSize(width: 8, height:  8))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        self.layer.mask = maskLayer
    }
    
    
}
