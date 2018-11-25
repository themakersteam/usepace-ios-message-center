//
//  Client.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation

public class Client {
    func getClient(type: ClientType) -> ClientProtocol {
        switch type {
            case ClientType.sendBird:
                return SendBirdClient.shared()
            default:
                return SendBirdClient.shared()
        }
    }
}
