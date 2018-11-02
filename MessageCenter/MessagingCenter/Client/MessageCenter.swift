//
//  MessageCenter.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation

enum ClientType {
    static let CLIENT_SENDBIRD = "sendbird"
    static let CLIENT_OTHER = "other"
}

class MessageCenter {
    private static var client: Client {
        let client = Client()
        return client
    }
    
    private static var LAST_CLIENT: String = ClientType.CLIENT_SENDBIRD
    private static var notificationInboxMessages: NSArray = []
    
    public static func connect(connectionRequest: ConnectionRequest, connectionInterface: ConnectionaProtocol) {
        self.LAST_CLIENT = connectionRequest.client
        client.getClient(type: self.LAST_CLIENT).connect(connectionRequest: connectionRequest, connection: connectionInterface)
    }
    
    public static func join(chatId: String) {
        client.getClient(type: self.LAST_CLIENT).join(chatId: chatId)
    }
    
    public static func disconnect(disconnectionInterface: DisconnectionProtocol) {
        client.getClient(type: self.LAST_CLIENT).disconnect(disconnectInterface: disconnectionInterface)
    }
    
    public static func handleNotification(next: AnyClass, icon: Int, title: String, remoteMessage: AnyClass) {
        client.getClient(type: self.LAST_CLIENT).handleNotification(next: next, icon: icon, title: title, remoteMessage: remoteMessage, messages: notificationInboxMessages)
    }
    
    public static func clearNotificationMessages() {
        notificationInboxMessages = []
    }
}
