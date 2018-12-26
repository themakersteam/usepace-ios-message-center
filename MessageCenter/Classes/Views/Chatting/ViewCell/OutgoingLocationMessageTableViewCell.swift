//
//  OutgoingLocationMessageTableViewCell.swift
//  MessageCenter
//
//  Created by Ikarma Khan on 24/12/2018.
//

import UIKit
import SendBirdSDK
import TTTAttributedLabel

class OutgoingLocationMessageTableViewCell: UITableViewCell {

    weak var delegate: MessageDelegate?
    
    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var imgLocation: UIImageView!
    @IBOutlet weak var messageDateLabel: UILabel!
    @IBOutlet weak var resendMessageButton: UIButton!
    @IBOutlet weak var imgMessageStatus: UIImageView!
    @IBOutlet weak var vwTimestampStatus: UIView!
    
    private var message: SBDUserMessage!
    private var prevMessage: SBDBaseMessage!
    private var senderName: String = ""

    public var containerBackgroundColour: UIColor = UIColor(red: 122.0/255.0, green: 188.0/255.0, blue: 65.0/255.0, alpha: 1.0)
    
    static func nib() -> UINib {
        let podBundle = Bundle.bundleForXib(OutgoingLocationMessageTableViewCell.self)
        return UINib(nibName: String(describing: self), bundle: podBundle)
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
            guard let coordinates = self.message.message?.asCoordinates() else {
                return
            }
            PreviewLocationViewController.present(on: GroupChannelChattingViewController.instance!, lat: coordinates.lat, long: coordinates.long, title: self.senderName)
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
        self.senderName = aMessage.sender?.nickname ?? ""
        
        self.messageLabel.text = String.locationURL(strLocation: self.message.message!)?.absoluteString
        
        let messageContainerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickUserMessage))
        self.messageContainerView.isUserInteractionEnabled = true
        self.messageContainerView.addGestureRecognizer(messageContainerTapRecognizer)
        
        self.resendMessageButton.isHidden = true
        self.resendMessageButton.addTarget(self, action: #selector(clickResendUserMessage), for: UIControlEvents.touchUpInside)
        
        // Message Status
        if self.message.channelType == CHANNEL_TYPE_GROUP {
            if self.message.requestId == "0" {
                self.imgMessageStatus.image = UIImage(named: "icMsgsent.png", in: Bundle(for: MessageCenter.self), compatibleWith: nil)
            }
            else {
                if let channelOfMessage = channel as? SBDGroupChannel? {
                    let unreadMessageCount = channelOfMessage?.getReadReceipt(of: self.message)
                    if unreadMessageCount == 0 {
                        // 0 means everybody has read the message
                        self.imgMessageStatus.image = UIImage(named: "icMsgread.png", in: Bundle(for: MessageCenter.self), compatibleWith: nil)
                    }
                    else {
                        self.imgMessageStatus.image = UIImage(named: "icMsgdelivered.png", in: Bundle(for: MessageCenter.self), compatibleWith: nil)
                        
                    }
                }
            }
        }
        else {
            self.hideUnreadCount()
        }
        
        
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
    
    func updateBackgroundColour () {
        self.messageContainerView.backgroundColor = self.containerBackgroundColour
    }
    
    func getHeightOfViewCell() -> CGFloat {
        return 240.0
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
