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
public typealias HandleNotificationCompletion = (_ didMatch: Bool, _ message: [AnyHashable : Any]) -> Void
public typealias RegisterDevicePushTokenCompletion = (_ status: Int, _ error: Error?) -> Void

public struct ChatViewTheme {
    let title: String?
    let primaryColor: UIColor?
    let secondaryColor: UIColor?
}

public protocol ClientProtocol {
    var isConnected: Bool { get }
    func connect(with connectionRequest: ConnectionRequest, success:  @escaping ConnectionSucceeded, failure:  @escaping MessageCenterFailureCompletion)
    func openChatView(forChannel channelId: String, withTheme theme: ChatViewTheme?, completion: @escaping (Any?) -> Void)
    func closeChatView(completion: @escaping () -> Void)
    func disconnect(completion: @escaping () -> Void)
    func getUnReadMessagesCount(forChannel channel: String?, success: @escaping UnReadMessagesSuccessCompletion, failure: @escaping MessageCenterFailureCompletion)
    func handleNotification(userInfo: [AnyHashable : Any], completion: @escaping HandleNotificationCompletion)
    func registerDevicePushToken(_ deviceToken: Data, completion: @escaping RegisterDevicePushTokenCompletion)
}
