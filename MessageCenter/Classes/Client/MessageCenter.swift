//
//  MessageCenter.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation
import SendBirdSDK

public enum ClientType {
    public static let CLIENT_SENDBIRD = "sendbird"
    public static let CLIENT_OTHER = "other"
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
    
    private static var LAST_CLIENT: String = ClientType.CLIENT_SENDBIRD
    private static var notificationInboxMessages: NSArray = []
    
    public static func connect(connectionRequest: ConnectionRequest, connectionInterface: ConnectionProtocol) {
        self.LAST_CLIENT = connectionRequest.client
        client.getClient(type: LAST_CLIENT).connect(connectionRequest: connectionRequest, connection: connectionInterface)
    }
    
    public static func join(chatId: String) {
        client.getClient(type: LAST_CLIENT).join(chatId: chatId, completionHandler: {(channel) in
            
            let podBundle = Bundle(for: MessageCenter.self)
            let groupChannelVC = GroupChannelChattingViewController(nibName: "GroupChannelChattingViewController", bundle: podBundle)
            groupChannelVC.groupChannel = channel as! SBDGroupChannel
                //        let fileURL = podBundle.url(forResource:"ChattingView", withExtension: "xib")
                
                parentVC.present(groupChannelVC, animated: true) {
                    NSLog("logged")
            }
        })
        
        
    }
    
    public static func disconnect(disconnectionInterface: DisconnectionProtocol) {
        client.getClient(type: LAST_CLIENT).disconnect(disconnectInterface: disconnectionInterface)
    }
    
    public static func handleNotification(next: AnyClass, icon: Int, title: String, remoteMessage: AnyClass) {
        client.getClient(type: LAST_CLIENT).handleNotification(next: next, icon: icon, title: title, remoteMessage: remoteMessage, messages: notificationInboxMessages)
    }
    
    public static func clearNotificationMessages() {
        notificationInboxMessages = []
    }
    
    public static func isConnected() -> Bool {
        return client.getClient(type: LAST_CLIENT).isConnected()
    }
    
    public static func setParentVC(vc: UIViewController) {
        parentVC = vc;
    }
}
