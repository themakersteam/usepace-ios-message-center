//
//  SendBirdClient.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation
import SendBirdSDK

#if targetEnvironment(simulator)
    let isSimulator = true
#endif

let ErrorDomainConnection = "com.sendbird.sample.connection"
let ErrorDomainUser = "com.sendbird.sample.user"

public class SendBirdClient: ClientProtocol {
    private static var sendbirdClient: SendBirdClient = {
        let client = SendBirdClient()
        return client
    }()
    private var connected = false
    
    init() { }
    
    public func connect(connectionRequest: ConnectionRequest, connection: ConnectionProtocol) {
        SBDMain.initWithApplicationId(connectionRequest.appId)
        SBDMain.connect(withUserId: connectionRequest.userId, accessToken: connectionRequest.accessToken, completionHandler: { (user, error) in
            self.connected = false
            guard error == nil else {
                connection.onMessageCenterConnectionError(code: error!.code, message: error!.localizedDescription)
                return;
            }
            
            connection.onMessageCenterConnected(userId: (user?.userId)!)
            
            if let pushToken: Data = SBDMain.getPendingPushToken() {
                SBDMain.registerDevicePushToken(pushToken, unique: true, completionHandler: { (status, error) in
                    guard error == nil else {
                        print("APNS registration failed.")
                        connection.onMessageCenterConnectionError(code: error!.code, message: error!.localizedFailureReason!)
                        return
                    }
                    
                    self.connected = true
                    if status == .pending {
                        print("Push registration is pending.")
                    }
                    else {
                        print("APNS Token is registered.")
                    }
                })
            }
        })
    }
    
    public func join(chatId: String, completionHandler: @escaping (Any?) -> Void) {
        print("joining to chat room...")
        SBDGroupChannel.getWithUrl(chatId) { (channel, error) in
            guard error == nil else {
                print("Error occured while connecting to chat room: %@", error?.description)
                return
            }
            
            print("Joined chat room")
            completionHandler(channel)
            channel?.sendUserMessage("testMessage", completionHandler: { (message, error) in
                print("Message sent")
            })
        }
    }
    public func join(chatId: String) {
        
    }
    
    public func disconnect(disconnectInterface: DisconnectionProtocol) {
        SBDMain.disconnect {
            disconnectInterface.onMessageCenterDisconnected()
        }
    }
    
    public func handleNotification(next: AnyClass, icon: Int, title: String, remoteMessage: AnyClass, messages: NSArray) {
        messages.adding(remoteMessage)
        // push notification handler here
    }
    
    public func isConnected() -> Bool {
        return connected
    }
    
    class func shared() -> SendBirdClient {
        return sendbirdClient
    }
    
    
}
