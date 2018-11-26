//
//  ViewController.swift
//  MessageCenter
//
//  Created by jfredsoft on 11/07/2018.
//  Copyright (c) 2018 jfredsoft. All rights reserved.
//

import UIKit
import MessageCenter

class ViewController: UIViewController, ConnectionProtocol {
    @IBOutlet weak var labelUserId: UILabel!
    @IBOutlet weak var labelConnected: UILabel!
    @IBOutlet weak var buttonJoin: UIButton!
    
    @IBAction func onTouchJoinButton(_ sender: UIButton) {
        
//        MessageCenter.join(chatId: "sendbird_group_channel_2456028_f4a5055d72e15074e5832cd3d60d5fa662980e84")
        MessageCenter.join(chatId: "sendbird_group_channel_2456028_1ef918c0149a1f8b0993ae21cb26fa9c16540a91")
        
        
    }
    
    func onMessageCenterConnected(userId: String) {
        print("Connected user: %@", userId);
        labelUserId.text = userId
        buttonJoin.isEnabled = true
    }
    
    func onMessageCenterConnectionError(code: Int, message: String) {
        print("Error occured: %d %@", code, message)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        buttonJoin.isEnabled = false
        MessageCenter.parentVC = self
        let user1 = ConnectionRequest(appId: "FE3AD311-7F0F-4E7E-9E22-25FF141A37C0", userId: "rider_sony", accessToken: "4a8f3c197450b4762cd2dcf02a130816a503f4f2", client: ClientType.CLIENT_SENDBIRD, fcmToken: "")
//        let user2 = ConnectionRequest(appId: "FE3AD311-7F0F-4E7E-9E22-25FF141A37C0", userId: "customer_hs_184890", accessToken: "8b21b79c6a07d74e95cf6c91837ec2a64e9cbc54", client: ClientType.CLIENT_SENDBIRD, fcmToken: "")
        MessageCenter.connect(connectionRequest: user1, connectionInterface: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

