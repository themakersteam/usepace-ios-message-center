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
                self.imgMessageStatus.image = UIImage(named: "icMsgsent")
            }
            else {
                if let channelOfMessage = channel as? SBDGroupChannel? {
                    let unreadMessageCount = channelOfMessage?.getReadReceipt(of: self.message)
                    if unreadMessageCount == 0 {
                        // 0 means everybody has read the message
                        self.imgMessageStatus.image = UIImage(named: "icMsgread")
                    }
                    else {
                        self.imgMessageStatus.image = UIImage(named: "icMsgdelivered")
                        
                    }
                }
            }
        }
        else {
            self.hideUnreadCount()
        }
        
        
        let messageCreatedAtSeconds = message.createdAt
        let messageDate = Date(timeIntervalSince1970: TimeInterval(messageCreatedAtSeconds))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let strTime = formatter.string(from: messageDate)
        self.messageDateLabel.text = strTime

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
//        print(fullMessage)
//        var fullMessageSize: CGSize
//
//        let messageLabelMaxWidth = UIScreen.main.bounds.size.width - (self.messageContainerRightMargin.constant + self.messageContainerRightPadding.constant + self.messageContainerLeftPadding.constant + self.messageContainerLeftMargin.constant + self.messageDateLabelLeftMargin.constant + self.messageDateLabelWidth.constant)
//
////        fullMessageRect = fullMessage.boundingRect(with: CGSize.init(width: messageLabelMaxWidth, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
//
//        //UIScreen.main.bounds.size.width - 160.0
//
//        let framesetter = CTFramesetterCreateWithAttributedString(fullMessage)
//        fullMessageSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0,length: 0), nil, CGSize(width: messageLabelMaxWidth/1, height: CGFloat(LONG_LONG_MAX)), nil)
//        print(fullMessageSize)
//
//        if fullMessageSize.width >= messageLabelMaxWidth {
//            messageContainerWidth.constant = messageLabelMaxWidth
//        }
//        else {
//            messageContainerWidth.constant = fullMessageSize.width
//        }
//        self.messageContainerView.selectedCornerRadius()
//        self.layoutSubviews()
//        let cellHeight = self.dateContainerTopMargin.constant + self.dateContainerHeight.constant + self.dateContainerBottomMargin.constant + self.messageContainerTopPadding.constant + fullMessageSize.height
//            //
//
//
//
//        return cellHeight + 25.0
    }
    
    func hideUnreadCount() {
        //self.unreadCountLabel.isHidden = true
        
    }
    
    func showUnreadCount() {
//        if self.message.channelType == CHANNEL_TYPE_GROUP {
//            self.unreadCountLabel.isHidden = false
//            self.resendMessageButton.isHidden = true
//            self.deleteMessageButton.isHidden = true
//        }
    }
    
    func hideMessageControlButton() {
//        self.resendMessageButton.isHidden = true
//        self.deleteMessageButton.isHidden = true
    }
    
    func showMessageControlButton() {
//        self.sendingStatusLabel.isHidden = true
//        self.messageDateLabel.isHidden = true
//        self.unreadCountLabel.isHidden = true
//
//        self.resendMessageButton.isHidden = false
//        self.deleteMessageButton.isHidden = false
    }
    
    func showSendingStatus() {
//        self.messageDateLabel.isHidden = true
//        self.unreadCountLabel.isHidden = true
//        self.resendMessageButton.isHidden = true
//        self.deleteMessageButton.isHidden = true
//
//        self.sendingStatusLabel.isHidden = false
//        self.sendingStatusLabel.text = "Sending"
    }
    
    func showFailedStatus() {
//        self.messageDateLabel.isHidden = true
//        self.unreadCountLabel.isHidden = true
//        self.resendMessageButton.isHidden = true
//        self.deleteMessageButton.isHidden = true
//
//        self.sendingStatusLabel.isHidden = false
//        self.sendingStatusLabel.text = "Failed"
    }
    
    func showMessageDate() {
//        self.unreadCountLabel.isHidden = true
//        self.resendMessageButton.isHidden = true
//        self.sendingStatusLabel.isHidden = true
//        
//        self.messageDateLabel.isHidden = false
    }
}
