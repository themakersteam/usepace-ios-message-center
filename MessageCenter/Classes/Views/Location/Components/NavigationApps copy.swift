//
//  NavigationApps.swift
//  MessageCenter
//
//  Created by Muhamed ALGHZAWI on 26/12/2018.
//

import Foundation

/// Listing the Maps apps that is supported for navigation.
enum NavigationApps : CaseIterable {
    case appleMaps
    case googleMaps
    case waze
    case sygic
    
    /// The base scheme for the app used to check the availability of this app.
    var scheme: String {
        get {
            switch self {
            case .appleMaps:
                return "http://maps.apple.com"
            case .googleMaps:
                return "comgooglemaps://"
            case .sygic:
                return "com.sygic.aura://"
            case .waze:
                return "waze://"
            }
        }
    }
    
    /// The complete scheme with parameters used to open the app.
    func scheme(formattedWith lat: Double, long: Double) -> URL {
        switch self {
        case .appleMaps:
            return URL(string: "http://maps.apple.com/?q=\(lat),\(long)&sll=\(lat),\(long)")!
        case .googleMaps:
            return URL(string: "comgooglemaps://?q=\(lat),\(long)&center=\(lat),\(long)&zoom=14")!
        case .sygic:
            return URL(string: "com.sygic.aura://coordinate|\(long)|\(lat)|show".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)!
        case .waze:
            return URL(string: "https://waze.com/ul?ll=\(lat),\(long)&z=14")!
        }
    }
    
    /// The app action title.
    var actionTitle: String {
        get {
            switch self {
            case .appleMaps:
                return "navigation_apps.apple.action_title".localized
            case .googleMaps:
                return "navigation_apps.google.action_title".localized
            case .sygic:
                return "navigation_apps.sygic.action_title".localized
            case .waze:
                return "navigation_apps.waze.action_title".localized
            }
        }
    }
    
    /// Check if the app is installed.
    /// - Important: This method will return `false` even if the app exists if you didn't specify the supported schemes in the info.plist under this key: `LSApplicationQueriesSchemes`.
    ///
    /// [Reference: TP40009250-SW14](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/LaunchServicesKeys.html#//apple_ref/doc/uid/TP40009250-SW14)
    var canOpen: Bool {
        get {
            return UIApplication.shared.canOpenURL(URL(string: self.scheme)!)
        }
    }
    
    /// Invoke `UIApplication.shared.open` for the specified scheme with parameters if supported.
    func open(withCoordinates lat: Double, long: Double) {
        if !canOpen {
            return
        }
        
        let url = self.scheme(formattedWith: lat, long: long)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    /// List the supported apps by checking `canOpen` for each case.
    static func listSupported() -> [NavigationApps] {
        return NavigationApps.allCases.filter( { $0.canOpen })
    }
}

