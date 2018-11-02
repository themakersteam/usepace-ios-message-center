//
//  ConnectionRequest.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation

class ConnectionRequest {
    private var _appId: String = ""
    private var _userId: String = ""
    private var _accessToken: String = ""
    private var _client: String = ""
    private var _fcmToken: String = ""
    
    var appId: String {
        set { _appId = newValue}
        get { return _appId }
    }
    
    var userId: String {
        set { _userId = newValue}
        get { return _userId}
    }
    var accessToken: String {
        set { _accessToken = newValue}
        get { return _accessToken}
    }
    var client: String {
        set { _client = newValue}
        get { return _client}
    }
    
    var fcmToken: String {
        set { _fcmToken = newValue}
        get { return _fcmToken}
    }
    
    init() {}
    
    init(appId: String, userId: String, accessToken: String, client: String, fcmToken: String) {
        _appId = appId
        _userId = userId
        _accessToken = accessToken
        _client = client
        _fcmToken = fcmToken
    }
}
