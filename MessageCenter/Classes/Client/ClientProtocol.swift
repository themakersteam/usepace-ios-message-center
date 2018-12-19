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
public typealias RegisterDevicePushTokenCompletion = (_ status: Int, _ error: Error?) -> Void


public protocol ClientProtocol {
    var isConnected: Bool { get }
    func connect(with connectionRequest: ConnectionRequest, success:  @escaping ConnectionSucceeded, failure:  @escaping MessageCenterFailureCompletion)
    //
    func openChatView(_ channelId: String, theme: ThemeObject?, completion: @escaping (Any?) -> Void)
    func closeChatView(completion: @escaping () -> Void)
    func disconnect(completion: @escaping () -> Void)
    func getUnReadMessagesCount(forChannel channel: String?, success: @escaping UnReadMessagesSuccessCompletion, failure: @escaping MessageCenterFailureCompletion)
    func handleNotification(userInfo: [AnyHashable : Any]) -> Bool
    func registerDevicePushToken(_ deviceToken: Data, completion: @escaping RegisterDevicePushTokenCompletion)
}
