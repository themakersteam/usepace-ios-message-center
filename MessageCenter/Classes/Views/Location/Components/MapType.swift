//  File.swift
//  MessageCenter
//
//  Created by Muhamed ALGHZAWI on 29/11/2018.
//

import Foundation
import MapKit


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
