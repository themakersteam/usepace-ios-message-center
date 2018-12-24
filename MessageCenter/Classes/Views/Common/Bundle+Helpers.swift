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
        var resourceBundle = Bundle(url: bundleURL!)
        if resourceBundle?.path(forResource: String(describing: viewController), ofType: "xib") == nil {
            resourceBundle = Bundle(for: MessageCenter.self)
        }
        return resourceBundle
    }
}
