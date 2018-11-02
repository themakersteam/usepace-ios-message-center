//
//  ConnectionInterface.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation

protocol ConnectionaProtocol {
    func onMessageCenterConnected()
    func onMessageCenterConnectionError(code: Int, message: String)
}
