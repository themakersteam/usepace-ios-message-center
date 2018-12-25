//
//  String+Extension.swift
//  Alamofire
//
//  Created by Muhamed ALGHZAWI on 28/11/2018.
//

import Foundation
import UIKit

public extension String {
    
    public var localized : String {
        get{
            let frameworkBundle = Bundle(for: MessageCenter.self)
            let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("MessageCenter.bundle")
            var podBundle = Bundle(url: bundleURL!)
            if NSLocalizedString(self, tableName: "MessageCenter", bundle: podBundle!, value: "", comment: "") == self {
                podBundle = Bundle(for: MessageCenter.self)
            }
            return NSLocalizedString(self, tableName: "MessageCenter", bundle: podBundle!, value: "", comment: "")
        }
    }
    
    public static func locationURL(strLocation: String) -> URL? {
        let locationURL = strLocation
        let strCoordinates = locationURL.replacingOccurrences(of: "location://?", with: "")
        let arrCordinates = strCoordinates.components(separatedBy: "&")
        if arrCordinates.count == 2 {
            let strLat = arrCordinates[0]
            let strLong = arrCordinates[1]
            
            let strLatValue = strLat.replacingOccurrences(of: "lat=", with: "")
            let strLongValue = strLong.replacingOccurrences(of: "long=", with: "")
            
            let query = "?ll=\(strLatValue),\(strLongValue)"
            let path = "http://maps.apple.com/" + query
            if let url = URL(string: path) {
//                UIApplication.sharedApplication().openURL(url)
                return url
            }
            else {
                return nil
            }
        }
        return nil
    }
    
}

extension NSAttributedString {
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.width)
    }
}
