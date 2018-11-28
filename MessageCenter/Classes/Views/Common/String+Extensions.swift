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
            return NSLocalizedString(self, tableName: "Localization", bundle: Bundle(for: MessageCenter.self), value: "", comment: "")
        }
    }
}
