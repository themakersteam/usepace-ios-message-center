//
//  MessageCenter.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation
import SendBirdSDK

//public enum ClientType {
//    public static let CLIENT_SENDBIRD = "sendbird"
//    public static let CLIENT_OTHER = "other"
//}

public enum ClientType: String {
    case sendBird = "sendbird"
    case other = "other"
}

public class MessageCenter {
    private static var client: Client {
        let client = Client()
        return client
    }
    
    private static var _parentVC: UIViewController? = nil;
    public static var parentVC: UIViewController {
        set { _parentVC = newValue}
        get { return _parentVC! }
    }
    
    private static var LAST_CLIENT: ClientType = ClientType.sendBird
    private static var notificationInboxMessages: NSArray = []
    
    public static func connect(with connectionRequest: ConnectionRequest, success: @escaping ConnectionSucceeded, failure: @escaping MessageCenterFailureCompletion) {
        self.LAST_CLIENT = connectionRequest.client
        client.getClient(type: LAST_CLIENT).connect(with: connectionRequest, success: success, failure: failure)
        
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
            //        let fileURL = podBundle.url(forResource:"ChattingView", withExtension: "xib")
            
            parentVC.present(groupChannelVC, animated: true) {
                NSLog("logged")
            }
        })
        
    }
    
    public static func disconnect(completion: @escaping () -> Void) {
        client.getClient(type: LAST_CLIENT).disconnect(completion: completion)
    }
    
    public static func handleNotification(_ userInfo: Dictionary<String, String>, completion: @escaping HandleNotificationCompletion) {
        client.getClient(type: LAST_CLIENT).handleNotification(userInfo, completion: completion)
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
        parentVC = vc;
    }
}
