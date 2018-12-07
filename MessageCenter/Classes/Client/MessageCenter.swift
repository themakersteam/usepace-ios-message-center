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

public class MessageCenter {
    private static var client: Client {
        let client = Client()
        return client
    }
    
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
    public static func connect(with connectionRequest: ConnectionRequest, success: @escaping ConnectionSucceeded, failure: @escaping MessageCenterFailureCompletion) {
        self.LAST_CLIENT = connectionRequest.client
//        client.getClient(type: LAST_CLIENT).connect(with: connectionRequest, success: success, failure: failure)
        
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
    
    public static func openChatView(forChannel channelId: String, withTheme theme: ChatViewTheme?, completion: @escaping (Bool) -> Void ) {
        
        client.getClient(type: LAST_CLIENT).openChatView(forChannel: channelId, withTheme: theme, completion:  {(channel) in
            
            guard let groupChannel = channel as? SBDGroupChannel else {
                completion(false)
                return
            }
            
            let podBundle = Bundle(for: MessageCenter.self)
            let groupChannelVC = GroupChannelChattingViewController(nibName: "GroupChannelChattingViewController", bundle: podBundle)
            groupChannelVC.groupChannel = groupChannel
            
//            if theme != nil {
//                groupChannelVC.messageTheme = theme
//            }
            
            
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
    
    public static func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.mainApplication = application
        self.launchOptions = launchOptions
        self.registerForRemoteNotification()
        
        return true
    }
    
    static func registerForRemoteNotification() {
        guard mainApplication != nil else {
            NSLog("MainApplication is not properly configured.")
            return
        }
        if #available(iOS 10.0, *) {
            #if !(arch(i386) || arch(x86_64))
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                if granted {
                    UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings: UNNotificationSettings) -> Void  in
                        guard settings.authorizationStatus == UNAuthorizationStatus.authorized else {
                            return
                        }
                        DispatchQueue.main.async {
                            self.mainApplication?.registerForRemoteNotifications()
                        }
                    })
                }
            }
            #endif
        } else {
            #if !(arch(i386) || arch(x86_64))
            let notificationSettings = UIUserNotificationSettings(types: [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound], categories: nil)
            self.mainApplication?.registerUserNotificationSettings(notificationSettings)
            self.mainApplication?.registerForRemoteNotifications()
            #endif
        }
    }
    
    public static func registerForRemoteNotificationsWithDeviceToken(_ deviceToken: Data) {
        self.deviceToken = deviceToken
    }
    
    public static func failedToRegisterForRemoteNotificationsWithError(_ error: Error) {
        NSLog("Failed to register for remote notification")
    }
    
    public static func handleNotification(_ userInfo: [AnyHashable : Any]) {
        client.getClient(type: LAST_CLIENT).handleNotification(userInfo: userInfo) { (status, message) in
            if (status) {
                let sendBirdPayload = message["sendbird"] as! Dictionary<String, Any>
                let channelId = (sendBirdPayload["channel"]  as! Dictionary<String, Any>)["channel_url"] as! String
                client.getClient(type: LAST_CLIENT).openChatView(forChannel: channelId, withTheme: nil, completion:  {(channel) in
                    
                    guard let groupChannel = channel as? SBDGroupChannel else {
                        return
                    }
                    
                    let podBundle = Bundle(for: MessageCenter.self)
                    let groupChannelVC = GroupChannelChattingViewController(nibName: "GroupChannelChattingViewController", bundle: podBundle)
                    groupChannelVC.groupChannel = groupChannel
                    parentVC.present(groupChannelVC, animated: true) {
                        NSLog("logged")
                    }
                })
            }
        }
    }
}
