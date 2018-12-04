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
    public func registerDevicePushToken(_ deviceToken: Data, completion: @escaping RegisterDevicePushTokenCompletion) {
        SBDMain.registerDevicePushToken(deviceToken, unique: true) { (status, error) in
            completion(Int(status.rawValue), error)
        }
    }
    
    private static var sendbirdClient: SendBirdClient = {
        let client = SendBirdClient()
        return client
    }()
    private var connected = false
    
    init() { }
    
    public func connect(with connectionRequest: ConnectionRequest, success: @escaping ConnectionSucceeded, failure:  @escaping MessageCenterFailureCompletion) {
        SBDMain.initWithApplicationId(connectionRequest.appId)
        SBDMain.connect(withUserId: connectionRequest.userId, accessToken: connectionRequest.accessToken, completionHandler: { (user, error) in
            self.connected = false
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
    
    public func openChatView(forChannel channelId: String, withTheme theme: ChatViewTheme?, completion: @escaping (Any?) -> Void) {
        //TODO: Make use of ChatViewTheme
        print("joining to chat room...")
        SBDGroupChannel.getWithUrl(channelId) { (channel, error) in
            guard error == nil else {
                print("Error occured while connecting to chat room: %@", error?.description)
                completion(nil)
                return
            }
            
            print("Joined chat room")
            completion(channel)
        }
    }
    
    public func closeChatView(completion: @escaping () -> Void) {
        // TODO: Implement
    }
    
    public func getUnReadMessagesCount(forChannel channel: String?, success: @escaping UnReadMessagesSuccessCompletion, failure: @escaping MessageCenterFailureCompletion) {
        if let channel = channel {
            SBDGroupChannel.getWithUrl(channel) { (chanelObj, error) in
                guard error == nil, let chanelObj = chanelObj else {
                    failure(error!.code, error!.localizedDescription)
                    return
                }
                
                success(Int(chanelObj.unreadMessageCount))
            }
        }
        else {
            SBDMain.getTotalUnreadChannelCount() { (count, error) in
                guard error == nil else {
                    failure(error!.code, error!.localizedDescription)
                    return
                }
                
                success(Int(count))
            }
        }
    }
    
    public func handleNotification(userInfo: [AnyHashable : Any], completion: @escaping HandleNotificationCompletion) {
        //messages.adding(remoteMessage)
        // push notification handler here
        
        if userInfo["sendbird"] != nil {
            let sendBirdPayload = userInfo["sendbird"] as! Dictionary<String, Any>
//            let channel = (sendBirdPayload["channel"]  as! Dictionary<String, Any>)["channel_url"] as! String
            let channelType = sendBirdPayload["channel_type"] as! String
            if channelType == "group_messaging" {
                completion(true, userInfo)
            }
            completion(false, userInfo)
        }
    }
    
    public var isConnected: Bool {
        get {
            return connected
        }
    }
  
    public func disconnect(completion: @escaping () -> Void) {
        SBDMain.disconnect {
            completion()
        }
    }
    
    class func shared() -> SendBirdClient {
        return sendbirdClient
    }
    
}
