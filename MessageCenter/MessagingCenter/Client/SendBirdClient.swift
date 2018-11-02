//
//  SendBirdClient.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation
import SendBirdSDK

let ErrorDomainConnection = "com.sendbird.sample.connection"
let ErrorDomainUser = "com.sendbird.sample.user"

class SendBirdClient: ClientProtocol {
    private static var sendbirdClient: SendBirdClient = {
        let client = SendBirdClient()
        return client
    }()
    
    init() {}
    
    func connect(connectionRequest: ConnectionRequest, connection: ConnectionaProtocol) {
        SBDMain.connect(withUserId: connectionRequest.userId) { (user, error) in
            guard error == nil else {
                connection.onMessageCenterConnectionError(code: error!.code, message: error!.localizedFailureReason!)
                return;
            }
            
            if let pushToken: Data = SBDMain.getPendingPushToken() {
                SBDMain.registerDevicePushToken(pushToken, unique: true, completionHandler: { (status, error) in
                    guard error == nil else {
                        print("APNS registration failed.")
                        connection.onMessageCenterConnectionError(code: error!.code, message: error!.localizedFailureReason!)
                        return
                    }
                    
                    if status == .pending {
                        print("Push registration is pending.")
                    }
                    else {
                        print("APNS Token is registered.")
                        connection.onMessageCenterConnected()
                    }
                })
            }
        }
    }
    
    func join(chatId: String) {
        
    }
    
    func disconnect(disconnectInterface: DisconnectionProtocol) {
        SBDMain.disconnect {
            disconnectInterface.onMessageCenterDisconnected()
        }
    }
    
    func handleNotification(next: AnyClass, icon: Int, title: String, remoteMessage: AnyClass, messages: NSArray) {
        messages.adding(remoteMessage)
        // push notification handler here
    }
    
    class func shared() -> SendBirdClient {
        return sendbirdClient
    }
    
    
}
