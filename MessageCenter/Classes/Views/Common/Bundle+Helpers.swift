//
//  Bundle+Helpers.swift
//  MessageCenter
//
//  Created by Ikarma Khan on 23/12/2018.
//

import UIKit
import Foundation

extension Bundle {
    
    class func bundleForXib(_ viewController: AnyClass) -> Bundle? {
        let frameworkBundle = Bundle(for: viewController )
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("MessageCenter.bundle")
        let resourceBundle = Bundle(url: bundleURL!)

        // Uncomment these lines if you are using example project.
        // Only for development pod. Not to be used otherwise. Should be commented
//        if resourceBundle?.path(forResource: String(describing: viewController), ofType: "xib") == nil {
//            resourceBundle = Bundle(for: MessageCenter.self)
//        }
        return resourceBundle
    }
}
