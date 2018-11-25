//
//  ClientInterface.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation

public typealias MessageCenterFailureCompletion = (_ errorCode: Int, _ errorMessage: String) -> Void
public typealias ConnectionSucceeded = (_ userId: String) -> Void
public typealias UnReadMessagesSuccessCompletion = (_ unReadMessagesCount: Int) -> Void
public typealias HandleNotificationCompletion = (_ didMatch: Bool, _ message: Dictionary<String, String>?) -> Void

public struct ChatViewTheme {
    var title: String;
    var primaryColor: UIColor;
    var secondaryColor: UIColor;
}

public protocol ClientProtocol {
    var isConnected: Bool { get }
    //func connect(connectionRequest: ConnectionRequest, connection: ConnectionProtocol)
    func connect(with connectionRequest: ConnectionRequest, success:  @escaping ConnectionSucceeded, failure:  @escaping MessageCenterFailureCompletion)
    //func join(chatId: String, completionHandler: @escaping (Any?) -> Swift.Void)
    func openChatView(forChannel channelId: String, withTheme theme: ChatViewTheme?, completion: @escaping (Any?) -> Void)
    func closeChatView(completion: @escaping () -> Void)
    //func disconnect(disconnectInterface: DisconnectionProtocol)
    func disconnect(completion: @escaping () -> Void)
    func getUnReadMessagesCount(forChannel channel: String?, success: @escaping UnReadMessagesSuccessCompletion, failure: @escaping MessageCenterFailureCompletion)
    //func handleNotification(next: AnyClass,  icon: Int, title: String, remoteMessage: AnyClass, messages: NSArray)
    func handleNotification(_ userInfo: Dictionary<String, String>, completion: @escaping HandleNotificationCompletion)
}
