//
//  ClientInterface.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation

public protocol ClientProtocol {
    func connect(connectionRequest: ConnectionRequest, connection: ConnectionProtocol)
    func join(chatId: String, completionHandler: @escaping (Any?) -> Swift.Void)
    func disconnect(disconnectInterface: DisconnectionProtocol)
    func handleNotification(next: AnyClass,  icon: Int, title: String, remoteMessage: AnyClass, messages: NSArray)
    func isConnected() -> Bool
}
