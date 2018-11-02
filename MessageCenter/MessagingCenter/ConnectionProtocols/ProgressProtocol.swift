//
//  ProgressInterface.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation

protocol ProgressProtocol {
    func onProgress(bytesSent: Int, totalBytesSent: Int, totalBytesToSend: Int)
}
