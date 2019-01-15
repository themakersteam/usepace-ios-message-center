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
var lastConnectionRequest : ConnectionRequest?

public class SendBirdClient: ClientProtocol {
    
    
    public func registerDevicePushToken(_ deviceToken: Data, completion: @escaping RegisterDevicePushTokenCompletion) {
        SBDMain.registerDevicePushToken(deviceToken, unique: true) { (status, error) in
            completion(Int(status.rawValue), error)
        }
    }
    
    private static var sendbirdClient: SendBirdClient = {
        let client = SendBirdClient()
        return client
    }()

    init() { }
    
    public func connect(with connectionRequest: ConnectionRequest, success: @escaping ConnectionSucceeded, failure:  @escaping MessageCenterFailureCompletion) {
        SBDMain.initWithApplicationId(connectionRequest.appId)
        SBDMain.connect(withUserId: connectionRequest.userId, accessToken: connectionRequest.accessToken, completionHandler: { (user, error) in
            lastConnectionRequest = connectionRequest
            guard error == nil else {
                failure(error!.code, error!.localizedDescription)
                //connection.onMessageCenterConnectionError(code: error!.code, message: error!.localizedDescription)
                return;
            }
            
            //connection.onMessageCenterConnected(userId: (user?.userId)!)
            success((user?.userId)!)
            
            if let pushToken: Data = SBDMain.getPendingPushToken() {
                SBDMain.registerDevicePushToken(pushToken, unique: true, completionHandler: { (status, error) in
                    guard error == nil else {
                        print("APNS registration failed.")
                        // TODO: Confirm, should we fire a failure in case of APNs registration failed??
                        //connection.onMessageCenterConnectionError(code: error!.code, message: error!.localizedFailureReason!)
                         SBDMain.disconnect(completionHandler: {})
                        return
                    }
                    
            
                    SBDMain.disconnect(completionHandler: {})
                    print("APNS Token is registered.")
                })
            }
        })
    }
    //
    public func openChatView(_ channelId: String, theme: ThemeObject?,  completion: @escaping (Any?) -> Void) {
        //TODO: Make use of ChatViewTheme
        print("joining to chat room...")
        if (self.isConnected) {
            self.openChat(channelId, theme: theme, completion: completion)
        }
        else {
            SBDMain.initWithApplicationId(lastConnectionRequest?.appId ?? "")
            SBDMain.connect(withUserId: (lastConnectionRequest?.userId)!, accessToken: lastConnectionRequest?.accessToken, completionHandler: { (user, error) in
                guard error == nil else {
                    return;
                }
                self.openChat(channelId, theme: theme, completion: completion)
            }
        )}
    }
    
    public func closeChatView(completion: @escaping () -> Void) {
        // TODO: Implement
    }
    
    public func getUnReadMessagesCount(forChannel channel: String?, success: @escaping UnReadMessagesSuccessCompletion, failure: @escaping MessageCenterFailureCompletion) {
        if (self.isConnected) {
            self.excuteGetUnreadMessageCount(forChannel: channel, success: success, failure: failure)
        }
        else {
            SBDMain.connect(withUserId: (lastConnectionRequest?.userId)!, accessToken: lastConnectionRequest?.accessToken, completionHandler: { (user, error) in
                guard error == nil else {
                    failure(error!.code, error!.localizedDescription)
                    return;
                }
                self.excuteGetUnreadMessageCount(forChannel: channel, success: success, failure: failure)
            }
        )}
    }
    
    public func handleNotification(userInfo: [AnyHashable : Any]) -> Bool {
        if userInfo["sendbird"] != nil {
            let sendBirdPayload = userInfo["sendbird"] as! Dictionary<String, Any>
            let channelType = sendBirdPayload["channel_type"] as! String
            if channelType == "group_messaging" {
                return true
            }
            return false
        }
        return false
    }
    
    public var isConnected: Bool {
        return SBDMain.getConnectState() == .open //Connection Opened
    }
  
    public func disconnect(completion: @escaping () -> Void) {
        lastConnectionRequest = nil
        SBDMain.unregisterAllPushToken { (a, error) in
            guard error == nil else {
                print("Failed to Disconnect")
                return
            }
            if (self.isConnected) {
                SBDMain.disconnect {
                    completion()
                }
            }
            else {
                completion()
            }
        }
    }
    
    private func openChat(_ channelId: String, theme: ThemeObject?,  completion: @escaping (Any?) -> Void) {
        SBDGroupChannel.getWithUrl(channelId) { (channel, error) in
            guard error == nil else {
                print("Error occured while connecting to chat room: %@", error?.description ?? "Error")
                completion(nil)
                return
            }
            print("Joined chat room")
            completion(channel)
        }
    }
    
    private func excuteGetUnreadMessageCount(forChannel channel: String?, success: @escaping UnReadMessagesSuccessCompletion, failure: @escaping MessageCenterFailureCompletion) {
        if let channel = channel {
            SBDGroupChannel.getWithUrl(channel) { (chanelObj, error) in
                guard error == nil else {
                    failure(error!.code, error!.localizedDescription)
                    return
                }
                                                 
                guard let chanelObj = chanelObj else {
                    failure(0, "")
                    return
                }
                                                 
                success(Int(chanelObj.unreadMessageCount))
                SBDMain.disconnect(completionHandler: {})
            }
        }
        else {
            SBDMain.getTotalUnreadChannelCount() { (count, error) in
                guard error == nil else {
                    failure(error!.code, error!.localizedDescription)
                    return
                }
                success(Int(count))
                SBDMain.disconnect(completionHandler: {})
            }
        }
    }
    
    class func shared() -> SendBirdClient {
        return sendbirdClient
    }
    
}
