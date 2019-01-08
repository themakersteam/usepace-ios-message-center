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
    let primaryNavigationButtonColor: UIColor?
}

public class NotificationModel: NSObject {
    public var title: String = ""
    public var message: String = ""
    public var channelId: String = ""
    public var senderId: String = ""
    public var senderName: String = ""
    public var image: String = ""
    
}

public class MessageCenter {
  public static var  isOpen = false
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

    public static var oldVC =  UIViewController()
    static var groupChannelVC = GroupChannelChattingViewController()

    public static var completionHandler : ((Bool) -> Void)? = nil
    
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


        self.themeObject = ThemeObject(title: title,
                                       subtitle: subtitle,
                                       welcomeMessage: welcomeMessage,
                                       primaryColor: primaryColor,
                                       primaryAccentColor: primaryAccentColor,
                                       primaryButtonColor: primaryActionIconsColor,
                                       primaryBackgroundColor: primaryBackgroundColor,
                                       primaryActionIconsColor: primaryActionIconsColor,
                                       primaryNavigationButtonColor: primaryNavigationButtonColor)
        
        return themeObject!
    }
    
    public static func openChatView(_ channelId: String, theme: ThemeObject?, completion: @escaping (Bool) -> Void ) {
        
        client.getClient(type: LAST_CLIENT).openChatView(channelId, theme: theme, completion:  {(channel) in
            
            guard let groupChannel = channel as? SBDGroupChannel else {
                completion(false)
                return
            }
            
            self.completionHandler = completion
            
            let resourceBundle = Bundle.bundleForXib(GroupChannelChattingViewController.self)
            
            if !isOpen {
             groupChannelVC = GroupChannelChattingViewController(nibName: "GroupChannelChattingViewController", bundle: resourceBundle)
            }
            groupChannelVC.groupChannel = groupChannel
            
            if theme != nil {
                groupChannelVC.themeObject = theme
            }
            else {
                let title = ""
                // Subtitle to be displayed below title on navigation bar
                let subtitle = ""
                // Welcome Message
                let welcomeMessage = ""
                // Sender bubble color
                let primaryColor = UIColor(red: 255.0/255.0, green: 247.0/255.0, blue: 214.0/255.0, alpha: 1.0)
                // Color for Title, welcome message background (with alpha 0.4) and Send button background
                let primaryAccentColor = UIColor(red: 245.0/255.0, green: 206.0/255.0, blue: 9.0/255.0, alpha: 1.0)
                // Back button color
                let primaryNavigationIconColor = UIColor(red: 255.0/255.0, green: 200.0/255.0, blue: 0.0/255.0, alpha: 1.0)
                // Chat background color
                let primaryBackgroundColor = UIColor(red: 244.0/255.0, green: 242.0/255.0, blue: 230.0/255.0, alpha: 1.0)
                // Action sheet icons, subtitles, and send button color
                let primaryActionIconsColor = UIColor(red: 82.0/255.0, green: 67.0/255.0, blue: 62.0/255.0, alpha: 1.0)
                let theme = MessageCenter.createThemeObject(title: title,
                                                            subtitle: subtitle,
                                                            welcomeMessage: welcomeMessage,
                                                            primaryColor: primaryColor,
                                                            primaryAccentColor: primaryAccentColor,
                                                            primaryNavigationButtonColor: primaryNavigationIconColor,
                                                            primaryBackgroundColor: primaryBackgroundColor,
                                                            primaryActionIconsColor: primaryActionIconsColor)
                groupChannelVC.themeObject = theme
            }
            
            if isOpen {

                groupChannelVC.themeObject = theme
                
                groupChannelVC.relaodChatView()
                
            }else{
            self.isOpen = true
            self.oldVC = parentVC
            let navController = UINavigationController(rootViewController: groupChannelVC)
            navController.isNavigationBarHidden = true
            parentVC.present(navController, animated: true, completion: nil)

                
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
    
    public static func handleMessageNotification(_ userInfo: [AnyHashable : Any]) -> NotificationModel? {
        
        let handle = client.getClient(type: LAST_CLIENT).handleNotification(userInfo: userInfo)
        if handle == true {
            var message = ""
            guard let sbPayload = userInfo["sendbird"] as? Dictionary<String, Any> else {
                return nil
            }
            
            if sbPayload["message"] as? String != nil {
                message = sbPayload["message"] as! String
            }
            
            guard let sbChannel = sbPayload["channel"] as? Dictionary<String, Any> else {
                return nil
            }
            let channelURL = sbChannel["channel_url"] as! String
            
            guard let sbSender = sbPayload["sender"] as? Dictionary<String, Any> else {
                return nil
            }
            let senderId = sbSender["id"] as! String
            let senderName = sbSender["name"] as! String
            
            let notification = NotificationModel()
            notification.channelId = channelURL
            notification.senderId = senderId
            notification.senderName = senderName
            notification.message = message
            
            return notification
        }
        else {
            return nil
        }
    }
}
