//
//  Client.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation

class Client {
    func getClient(type: String) -> ClientProtocol {
        switch type {
            case ClientType.CLIENT_SENDBIRD:
                return SendBirdClient.shared()
            default:
                return SendBirdClient.shared()
        }
    }
}
