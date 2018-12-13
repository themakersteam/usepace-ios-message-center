//
//  IncomingUserMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Kyung on 10/6/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import AlamofireImage
import TTTAttributedLabel

class IncomingUserMessageTableViewCell: UITableViewCell, TTTAttributedLabelDelegate {
    weak var delegate: MessageDelegate?
    
    
    
    @IBOutlet weak var messageLabel: TTTAttributedLabel!
    @IBOutlet weak var messageDateLabel: UILabel!
    @IBOutlet weak var messageContainerView: UIView!
    
    private var message: SBDUserMessage!
    private var prevMessage: SBDBaseMessage?
    private var displayNickname: Bool = true
    private var podBundle: Bundle!
    public var containerBackgroundColour: UIColor = UIColor(red: 237.0/255.0, green: 237.0/255.0, blue: 237.0/255.0, alpha: 1.0)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.podBundle = Bundle(for: MessageCenter.self)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        messageContainerView.layer.cornerRadius = 8.0
    }
    
    static func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }
    
    static func cellReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    @objc private func clickProfileImage() {
        if self.delegate != nil {
            self.delegate?.clickProfileImage(viewCell: self, user: self.message!.sender!)
        }
    }
    
    @objc private func clickUserMessage() {
        if self.delegate != nil {
//            self.delegate?.clickMessage(view: self, message: self.message!)
        }
    }
    
    func setModel(aMessage: SBDUserMessage) {
        self.message = aMessage
        
        // Message Date
        let messageDateAttribute = [
            NSAttributedStringKey.font: Constants.messageDateFont(),
            NSAttributedStringKey.foregroundColor: Constants.messageDateColor()
        ]
        
        let messageTimestamp = Double(self.message.createdAt) / 1000.0
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short
        let messageCreatedDate = NSDate(timeIntervalSince1970: messageTimestamp)
        let messageDateString = dateFormatter.string(from: messageCreatedDate as Date)
        let messageDateAttributedString = NSMutableAttributedString(string: messageDateString, attributes: messageDateAttribute)
        self.messageDateLabel.attributedText = messageDateAttributedString
        
        let fullMessage = self.buildMessage()
        self.messageLabel.attributedText = fullMessage
        self.messageLabel.isUserInteractionEnabled = true
        self.messageLabel.linkAttributes = [
            NSAttributedStringKey.font: Constants.messageFont(),
            NSAttributedStringKey.foregroundColor: Constants.incomingMessageColor(),
            NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue
        ]
        
        let detector: NSDataDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: self.message.message!, options: [], range: NSMakeRange(0, (self.message.message?.count)!))
        if matches.count > 0 {
            self.messageLabel.delegate = self
            self.messageLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
            for item in matches {
                let match = item
                let rangeOfOriginalMessage = match.range
                var range: NSRange
                if self.displayNickname {
                    range = NSMakeRange((self.message.sender?.nickname?.count)! + 1 + rangeOfOriginalMessage.location, rangeOfOriginalMessage.length)
                }
                else {
                    range = rangeOfOriginalMessage
                }
                
                self.messageLabel.addLink(to: match.url, with: range)
            }
        }
        
        self.layoutIfNeeded()
    }
    
    func setPreviousMessage(aPrevMessage: SBDBaseMessage?) {
        self.prevMessage = aPrevMessage
    }
    
    func buildMessage() -> NSAttributedString {
//        var nicknameAttribute: [NSAttributedStringKey:AnyObject]?
//        switch (self.message.sender?.nickname?.utf8.count)! % 5 {
//        case 0:
//            nicknameAttribute = [
//                NSAttributedStringKey.font: Constants.nicknameFontInMessage(),
//                NSAttributedStringKey.foregroundColor: Constants.nicknameColorInMessageNo0()
//            ]
//            break;
//        case 1:
//            nicknameAttribute = [
//                NSAttributedStringKey.font: Constants.nicknameFontInMessage(),
//                NSAttributedStringKey.foregroundColor: Constants.nicknameColorInMessageNo1()
//            ]
//            break;
//        case 2:
//            nicknameAttribute = [
//                NSAttributedStringKey.font: Constants.nicknameFontInMessage(),
//                NSAttributedStringKey.foregroundColor: Constants.nicknameColorInMessageNo2()
//            ]
//            break;
//        case 3:
//            nicknameAttribute = [
//                NSAttributedStringKey.font: Constants.nicknameFontInMessage(),
//                NSAttributedStringKey.foregroundColor: Constants.nicknameColorInMessageNo3()
//            ]
//            break;
//        case 4:
//            nicknameAttribute = [
//                NSAttributedStringKey.font: Constants.nicknameFontInMessage(),
//                NSAttributedStringKey.foregroundColor: Constants.nicknameColorInMessageNo4()
//            ]
//            break;
//        default:
//            nicknameAttribute = [
//                NSAttributedStringKey.font: Constants.nicknameFontInMessage(),
//                NSAttributedStringKey.foregroundColor: Constants.nicknameColorInMessageNo0()
//            ]
//            break;
//        }
//
        let messageAttribute = [
            NSAttributedStringKey.font: Constants.messageFont()
        ]

//        let nickname = self.message.sender?.nickname
        let message = self.message.message
        
        var fullMessage: NSMutableAttributedString? = nil
//        if self.displayNickname == true {
//            fullMessage = NSMutableAttributedString.init(string: NSString(format: "%@\n%@", nickname!, message!) as String)
//
//            fullMessage?.addAttributes(nicknameAttribute!, range: NSMakeRange(0, (nickname?.utf16.count)!))
//            fullMessage?.addAttributes(messageAttribute, range: NSMakeRange((nickname?.utf16.count)! + 1, (message?.utf16.count)!))
//        }
//        else {
//
//        }
        fullMessage = NSMutableAttributedString.init(string: message!)
        fullMessage?.addAttributes(messageAttribute, range: NSMakeRange(0, (message?.utf16.count)!))
        return fullMessage!
    }
    
    func updateBackgroundColour () {
        self.messageContainerView.backgroundColor = self.containerBackgroundColour
    }
    
    func getHeightOfViewCell() -> CGFloat {
        let fullMessage = self.buildMessage()
        let heightOfString = fullMessage.height(withConstrainedWidth: UIScreen.main.bounds.size.width - 120.0)
        return heightOfString + 45.0
    }
    
    // MARK: TTTAttributedLabelDelegate
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.openURL(url)
    }
}
