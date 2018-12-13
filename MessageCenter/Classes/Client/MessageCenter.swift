//
//  MessageCenter.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation
import UserNotifications
import SendBirdSDK

public enum ClientType: String {
    case sendBird = "sendbird"
    case other = "other"
}

public struct ThemeObject {
    let title: String?
    let subtitle:String?
    let welcomeMessage:String?
    
    let primaryColor: UIColor?
    let primaryAccentColor: UIColor?
    let primaryButtonColor: UIColor?
    let primaryBackgroundColor: UIColor?
    let primaryActionIconsColor: UIColor?
}

public class NotificationModel: NSObject {
    public var title: String = ""
    public var message: String = ""
    public var channelId: String = ""
    public var senderId: String = ""
    public var senderName: String = ""
}

public class MessageCenter {
    private static var client: Client {
        let client = Client()
        return client
    }
    public static var themeObject : ThemeObject?
    private static var _parentVC: UIViewController? = nil
    public static var parentVC: UIViewController {
        set { _parentVC = newValue}
        get { return _parentVC! }
    }
    
    private static var LAST_CLIENT: ClientType = ClientType.sendBird
    private static var notificationInboxMessages: NSArray = []
    private static var mainApplication: UIApplication? = nil
    private static var launchOptions: [UIApplicationLaunchOptionsKey: Any]? = [:]
    private static var deviceToken: Data? = nil
    
    public static func connect(_ connectionRequest: ConnectionRequest,
                               pushToken: Data?,
                               success: @escaping ConnectionSucceeded,
                               failure: @escaping MessageCenterFailureCompletion
        ) {
        
        self.LAST_CLIENT = connectionRequest.client
        self.deviceToken =  pushToken
        
        client.getClient(type: LAST_CLIENT).connect(with: connectionRequest, success: { (status) in
            
            if self.deviceToken == nil {
                NSLog("Failed to register for remote notification")
                success(status)
                return
            }
            
            client.getClient(type: LAST_CLIENT).registerDevicePushToken(self.deviceToken!) { (status, error) in
                if error == nil {
                    if status == Int(SBDPushTokenRegistrationStatus.pending.rawValue) {
                        NSLog("Succeeded to register for remote notification but pending status")
                    }
                    else {
                        NSLog("Succeeded to register for remote notification")
                    }
                }
                else {

                }
            }
            success(status)
        }, failure: failure)
    }
    
    
    public class func createThemeObject(title: String?, subtitle: String?, welcomeMessage: String? ,primaryColor: UIColor? , primaryAccentColor: UIColor?, primaryNavigationButtonColor: UIColor?, primaryBackgroundColor: UIColor?, primaryActionIconsColor: UIColor?) -> ThemeObject {
        
    
        var _title = ""
        
        var pColor = UIColor(red: 122.0/255.0, green: 188.0/255.0, blue: 65.0/255.0, alpha: 1.0)
        var sColor = UIColor(red: 237.0/255.0, green: 237.0/255.0, blue: 237.0/255.0, alpha: 1.0)
        
        if title != nil {
            _title = title!
        }
        if primaryColor != nil {
            pColor = primaryColor!
        }
//        if secondaryColor == nil {
//            sColor = secondaryColor!
//        }

        self.themeObject = ThemeObject(title: title, subtitle: subtitle, welcomeMessage: welcomeMessage, primaryColor: primaryColor, primaryAccentColor: primaryAccentColor, primaryButtonColor: primaryActionIconsColor, primaryBackgroundColor: primaryBackgroundColor, primaryActionIconsColor: primaryActionIconsColor)
        
        return themeObject!
    }
    
    public static func openChatView(forChannel channelId: String, welcomeMessage: String, withTheme theme: ThemeObject?, completion: @escaping (Bool) -> Void ) {
        
        client.getClient(type: LAST_CLIENT).openChatView(forChannel: channelId, welcomeMessage: welcomeMessage, withTheme: theme, completion:  {(channel) in
            
            guard let groupChannel = channel as? SBDGroupChannel else {
                completion(false)
                return
            }
            
            let podBundle = Bundle(for: MessageCenter.self)
            let groupChannelVC = GroupChannelChattingViewController(nibName: "GroupChannelChattingViewController", bundle: podBundle)
            groupChannelVC.groupChannel = groupChannel
            
            if theme != nil {
                groupChannelVC.themeObject = theme
            }
            
            if welcomeMessage != nil {
                groupChannelVC.welcomeMessage = welcomeMessage
            }
            if parentVC.navigationController != nil {
                parentVC.navigationController?.pushViewController(groupChannelVC, animated: true)
            }
            else {
                parentVC.present(groupChannelVC, animated: true, completion: nil)
            }
            
        })
        
    }
    
    public static func disconnect(completion: @escaping () -> Void) {
        client.getClient(type: LAST_CLIENT).disconnect(completion: completion)
    }
    
    public static func getUnReadMessagesCount(forChannel channel: String?, success: @escaping UnReadMessagesSuccessCompletion, failure: @escaping MessageCenterFailureCompletion) {
        client.getClient(type: LAST_CLIENT).getUnReadMessagesCount(forChannel: channel, success: success, failure: failure)
    }
    
    public static func clearNotificationMessages() {
        notificationInboxMessages = []
    }
    
    public static var isConnected : Bool {
        get {
            return client.getClient(type: LAST_CLIENT).isConnected
        }
    }
    
    public static func setParentVC(vc: UIViewController) {
        parentVC = vc
    }
    
    public static func handleNotification(
        _ userInfo: [AnyHashable : Any],
        match: @escaping (_ notification: NotificationModel) -> Void,
        noMatch: @escaping() -> Void) {
        
        client.getClient(type: LAST_CLIENT).handleNotification(userInfo: userInfo) { (status, payload) in
            if (status) {
                
                guard let sbPayload = payload["sendbird"] as? Dictionary<String, Any> else {
                    noMatch()
                    return
                }
                
                let message = sbPayload["message"] as! String
                
                guard let sbChannel = sbPayload["channel"] as? Dictionary<String, Any> else {
                    noMatch()
                    return
                }
                let channelURL = sbChannel["channel_url"] as! String
                
                guard let sbSender = sbPayload["sender"] as? Dictionary<String, Any> else {
                    noMatch()
                    return
                }
                let senderId = sbSender["id"] as! String
                let senderName = sbSender["name"] as! String
                
//                let notification = NotificationModel(
//                    title: "",
//                    message: message,
//                    channelId: channelURL,
//                    senderId: senderId,
//                    senderName: senderName
//                )
//                match(notification)
                
            }
            else {
                noMatch()
            }
        }
    }
}
