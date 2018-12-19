//
//  OutgoingUserMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Kyung on 10/7/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import TTTAttributedLabel

class OutgoingUserMessageTableViewCell: UITableViewCell {
    weak var delegate: MessageDelegate?
    
    
    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var messageLabel: TTTAttributedLabel!
    @IBOutlet weak var messageDateLabel: UILabel!
    @IBOutlet weak var resendMessageButton: UIButton!
    @IBOutlet weak var imgMessageStatus: UIImageView!
    @IBOutlet weak var vwTimestampStatus: UIView!
    @IBOutlet weak var cnMessageContainerLeftPadding: NSLayoutConstraint!

    private var message: SBDUserMessage!
    private var prevMessage: SBDBaseMessage!

    public var containerBackgroundColour: UIColor = UIColor(red: 122.0/255.0, green: 188.0/255.0, blue: 65.0/255.0, alpha: 1.0)
    
    static func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.messageContainerView.layer.cornerRadius = 8.0
    }
    
    static func cellReuseIdentifier() -> String {
        return String(describing: self)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    @objc private func clickUserMessage() {
        if self.delegate != nil {
            self.delegate?.clickMessage(view: self, message: self.message!)
        }
    }
    
    @objc private func clickResendUserMessage() {
        if self.delegate != nil {
            self.delegate?.clickResend(view: self, message: self.message!)
        }
    }
    
    @objc private func clickDeleteUserMessage() {
        if self.delegate != nil {
            self.delegate?.clickDelete(view: self, message: self.message!)
        }
    }
    
    func setModel(aMessage: SBDUserMessage, channel: SBDBaseChannel?) {
        self.message = aMessage
        
        let fullMessage = self.buildMessage()
        
        self.messageLabel.attributedText = fullMessage
        
        self.resendMessageButton.isHidden = true
        
        
//        let messageContainerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickUserMessage))
//        self.messageContainerView.isUserInteractionEnabled = true
//        self.messageContainerView.addGestureRecognizer(messageContainerTapRecognizer)

        self.resendMessageButton.addTarget(self, action: #selector(clickResendUserMessage), for: UIControlEvents.touchUpInside)
        //self.deleteMessageButton.addTarget(self, action: #selector(clickDeleteUserMessage), for: UIControlEvents.touchUpInside)
        
        
        
        // Message Status
        if self.message.channelType == CHANNEL_TYPE_GROUP {
            if self.message.requestId == "0" {
                self.imgMessageStatus.image = UIImage(named: "icMsgsent", in: Bundle(for: MessageCenter.self), compatibleWith: nil)
            }
            else {
                if let channelOfMessage = channel as? SBDGroupChannel? {
                    let unreadMessageCount = channelOfMessage?.getReadReceipt(of: self.message)
                    if unreadMessageCount == 0 {
                        // 0 means everybody has read the message
                        self.imgMessageStatus.image = UIImage(named: "icMsgread", in: Bundle(for: MessageCenter.self), compatibleWith: nil)
                    }
                    else {
                        self.imgMessageStatus.image = UIImage(named: "icMsgdelivered", in: Bundle(for: MessageCenter.self), compatibleWith: nil)
                        
                    }
                }
            }
        }
        else {
            self.hideUnreadCount()
        }
        
        
//        let messageCreatedAtSeconds = message.createdAt
//        let messageDate = Date(timeIntervalSince1970: TimeInterval(messageCreatedAtSeconds))
//        let formatter = DateFormatter()
//        formatter.dateFormat = "HH:mm"
//        let strTime = formatter.string(from: messageDate)
//        self.messageDateLabel.text = strTime
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
        
        self.layoutIfNeeded()
    }

    func setPreviousMessage(aPrevMessage: SBDBaseMessage?) {
        self.prevMessage = aPrevMessage
    }
    
    func buildMessage() -> NSAttributedString {
        let messageAttribute = [
            NSAttributedStringKey.font: Constants.messageFont(),
            NSAttributedStringKey.foregroundColor: Constants.outgoingMessageColor(),
        ]
        
        let message = self.message.message
        
        let fullMessage = NSMutableAttributedString.init(string: message!)
        fullMessage.addAttributes(messageAttribute, range: NSMakeRange(0, (message?.utf16.count)!))
        
        return fullMessage
    }
    
    func updateBackgroundColour () {
        self.messageContainerView.backgroundColor = self.containerBackgroundColour
    }
    
    func getHeightOfViewCell() -> CGFloat {
        let fullMessage = self.buildMessage()
        let heightOfString = fullMessage.height(withConstrainedWidth: UIScreen.main.bounds.size.width - 120.0)
        return heightOfString + 45.0
    }
    
    func hideUnreadCount() {
        self.imgMessageStatus.isHidden = false
        
    }
    
    func showUnreadCount() {
        if self.message.channelType == CHANNEL_TYPE_GROUP {
            self.imgMessageStatus.isHidden = false
            self.vwTimestampStatus.isHidden = false
        }
    }
    
    func hideMessageControlButton() {
        self.resendMessageButton.isHidden = true
    }
    
    func showMessageControlButton() {
        self.messageDateLabel.isHidden = true
        self.imgMessageStatus.isHidden = true
        self.resendMessageButton.isHidden = false
    }
    
    func showSendingStatus() {
        self.messageDateLabel.isHidden = true
        self.imgMessageStatus.isHidden = true
        self.resendMessageButton.isHidden = true
    }
    
    func showFailedStatus() {
        self.messageDateLabel.isHidden = true
        self.imgMessageStatus.isHidden = true
        self.resendMessageButton.isHidden = false
    }
    
    func showMessageDate() {
//        self.unreadCountLabel.isHidden = true
//        self.resendMessageButton.isHidden = true
//        self.sendingStatusLabel.isHidden = true
//        
//        self.messageDateLabel.isHidden = false
    }
}
