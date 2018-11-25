//
//  ConnectionInterface.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation

public protocol ConnectionProtocol {
    func onMessageCenterConnected(userId: String)
    func onMessageCenterConnectionError(code: Int, message: String)
}
