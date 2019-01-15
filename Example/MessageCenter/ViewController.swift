//
//  ViewController.swift
//  MessageCenter
//
//  Created by jfredsoft on 11/07/2018.
//  Copyright (c) 2018 jfredsoft. All rights reserved.
//

import UIKit
import MessageCenter

class ViewController: UIViewController {
    @IBOutlet weak var labelUserId: UILabel!
    @IBOutlet weak var labelConnected: UILabel!
    @IBOutlet weak var buttonJoin: UIButton!
    
    var connectRequest: ConnectionRequest!
    
    @IBAction func onTouchJoinButton(_ sender: UIButton) {
        
        
        // Title for navigation bar
        let title = "Rider name"
        // Subtitle to be displayed below title on navigation bar
        let subtitle = "#12345678 • Restaurant"
        // Welcome Message
        let welcomeMessage = "Hungerstation rider is here to serve you!"
        // Sender bubble color
        let primaryColor = UIColor(red: 255.0/255.0, green: 247.0/255.0, blue: 214.0/255.0, alpha: 1.0)
        
        //UIColor(red: 255.0/255.0, green: 247.0/255.0, blue: 214.0/255.0, alpha: 1.0)
        // Color for Title, welcome message background (with alpha 0.4) and Send button background
        let primaryAccentColor = UIColor(red: 245.0/255.0, green: 206.0/255.0, blue: 9.0/255.0, alpha: 1.0)
        // Back button color
        let primaryNavigationIconColor = UIColor(red: 255.0/255.0, green: 200.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        // Chat background color
        let primaryBackgroundColor = UIColor(red: 244.0/255.0, green: 242.0/255.0, blue: 230.0/255.0, alpha: 1.0)
        // Action sheet icons, subtitles, and send button color
        let primaryActionIconsColor = UIColor(red: 82.0/255.0, green: 67.0/255.0, blue: 62.0/255.0, alpha: 1.0)
        
        //        let secondaryColor = UIColor(red: 237.0/255.0, green: 237.0/255.0, blue: 237.0/255.0, alpha: 1.0)
        
        
        let theme = MessageCenter.createThemeObject(title: title,
                                                    subtitle: subtitle,
                                                    welcomeMessage: welcomeMessage,
                                                    primaryColor: primaryColor,
                                                    primaryAccentColor: primaryAccentColor,
                                                    primaryNavigationButtonColor: primaryNavigationIconColor,
                                                    primaryBackgroundColor: primaryBackgroundColor,
                                                    primaryActionIconsColor: primaryActionIconsColor)
        
        //        sendbird_group_channel_2456028_1ef918c0149a1f8b0993ae21cb26fa9c16540a91
        //        sendbird_group_channel_2456028_72db325775728aa550b52e11990d891167ed5f1f
        //sendbird_group_channel_2456030_277d4489f790e546da458d5e175967670e65cc23
        MessageCenter.openChatView("sendbird_group_channel_2456030_c635beec1f988bca3e2bca1c64282b99045f1a12", theme: theme) { (success) in
            //
            if success == true {
                
            }
            else {
                
            }
        }
    }
    
    @IBAction func onTouchConnect(_ sender: Any) {
        
        MessageCenter.connect(connectRequest, pushToken:"sdq342134234dsc342".data(using: .utf8), success: { (userId) in
            print("Connected user: %@", userId);
            self.labelUserId.text = userId
            self.buttonJoin.isEnabled = true
            self.labelConnected.text = "Connected"
        }) { (errorCode, message) in
            print("Error occured: %d %@", errorCode, message)
            self.labelConnected.text = "Can't connect to server..."
        }
        self.labelConnected.text = "Connecting..."
    }
    
    
    //    app_id = "FE3AD311-7F0F-4E7E-9E22-25FF141A37C0", user_id = "customer_swyft_11", access_token = "99d61c5f0eac5c58c1ea0cc97bf4a99d2a653551
    //    sendbird_group_channel_2456030_277d4489f790e546da458d5e175967670e65cc23
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        buttonJoin.isEnabled = false
        MessageCenter.parentVC = self
        if TARGET_OS_SIMULATOR != 0 {
            //            connectRequest = ConnectionRequest(appId: "FE3AD311-7F0F-4E7E-9E22-25FF141A37C0", userId: "rider_sony", accessToken: "4a8f3c197450b4762cd2dcf02a130816a503f4f2", client: ClientType.sendBird)
            
            connectRequest = ConnectionRequest(appId: "FE3AD311-7F0F-4E7E-9E22-25FF141A37C0", userId: "customer_swyft_11", accessToken: "99d61c5f0eac5c58c1ea0cc97bf4a99d2a653551", client: .sendBird)
        }
        else {
            connectRequest = ConnectionRequest(appId: "FE3AD311-7F0F-4E7E-9E22-25FF141A37C0", userId: "customer_hs_184890", accessToken: "8b21b79c6a07d74e95cf6c91837ec2a64e9cbc54", client: ClientType.sendBird)
        }
        
        MessageCenter.connect(connectRequest, pushToken: "2121212324rdfdcef".data(using: .utf8), success: { (userId) in
            print("Connected user: %@", userId);
            self.labelUserId.text = userId
            self.buttonJoin.isEnabled = true
            self.labelConnected.text = "Connected"
        }) { (errorCode, message) in
            print("Error occured: %d %@", errorCode, message)
            self.labelConnected.text = "Can't connect to server..."
        }
        self.labelConnected.text = "Connecting..."
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


