//
//  ConnectionRequest.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation

public class ConnectionRequest {
    var appId: String = ""
    var userId: String = ""
    var accessToken: String = ""
    var client: ClientType = .sendBird
    
    public init(appId: String, userId: String, accessToken: String, client: ClientType) {
        self.appId = appId
        self.userId = userId
        self.accessToken = accessToken
        self.client = client
    }
 
}
