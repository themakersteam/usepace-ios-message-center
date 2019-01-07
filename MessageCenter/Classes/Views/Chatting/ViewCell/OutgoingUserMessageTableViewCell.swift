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
        let podBundle = Bundle.bundleForXib(OutgoingUserMessageTableViewCell.self)
        return UINib(nibName: String(describing: self), bundle: podBundle)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.messageDateLabel.font = UIFont.systemFont(ofSize: 10)
        self.messageContainerView.layer.cornerRadius = 8.0
        self.resendMessageButton.setTitle("ms_chat_failed_to_send".localized, for: .normal)
        if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
            self.resendMessageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)
        }
        else {
            self.resendMessageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        }
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
        self.resendMessageButton.addTarget(self, action: #selector(clickResendUserMessage), for: UIControlEvents.touchUpInside)

        // Message Status
        if self.message.channelType == CHANNEL_TYPE_GROUP {
            if self.message.messageId == 0 {
                self.imgMessageStatus.image = UIImage(named: "icMsgsent.png",
                                                      in: Bundle.bundleForXib(OutgoingUserMessageTableViewCell.self), compatibleWith: nil)
            }
            else {
                if let channelOfMessage = channel as? SBDGroupChannel? {
                    let unreadMessageCount = channelOfMessage?.getReadReceipt(of: self.message)
                    if unreadMessageCount == 0 {
                        // 0 means everybody has read the message
                        self.imgMessageStatus.image = UIImage(named: "icMsgread.png", in: Bundle.bundleForXib(OutgoingUserMessageTableViewCell.self), compatibleWith: nil)
                    }
                    else {
                        self.imgMessageStatus.image = UIImage(named: "icMsgdelivered.png", in: Bundle.bundleForXib(OutgoingUserMessageTableViewCell.self), compatibleWith: nil)
                        
                    }
                }
            }
        }
        else {
            self.hideMessageStatus()
        }
        
        let messageTimestamp = Double(self.message.createdAt) / 1000.0
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short
        let messageCreatedDate = NSDate(timeIntervalSince1970: messageTimestamp)
        let messageDateString = dateFormatter.string(from: messageCreatedDate as Date)
        self.messageDateLabel.text = messageDateString
        self.messageContainerView.addShadow()
        self.imgMessageStatus.contentMode = .scaleAspectFit
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
        
    
    func hideMessageResendButton() {
        self.resendMessageButton.isHidden = true
    }
    
    func showMessageResendButton() {
        self.messageDateLabel.isHidden = true
        self.imgMessageStatus.isHidden = true
        self.resendMessageButton.isHidden = false
    }
    
    func showSendingStatus() {
        self.messageDateLabel.isHidden = false
        self.imgMessageStatus.isHidden = false
        self.resendMessageButton.isHidden = true
    }
    
    func showFailedStatus() {
        self.messageDateLabel.isHidden = true
        self.imgMessageStatus.isHidden = true
        self.resendMessageButton.isHidden = false
    }
    
    func hideMessageStatus () {
        self.imgMessageStatus.isHidden = true
        self.messageDateLabel.isHidden = true
    }
    
    func showMessageStatus() {
        self.imgMessageStatus.isHidden = false
        self.messageDateLabel.isHidden = false
        self.resendMessageButton.isHidden = true
    }
}
