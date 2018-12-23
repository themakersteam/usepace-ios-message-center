//
//  OutgoingImageFileMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Kyung on 10/7/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit
import AlamofireImage
import SendBirdSDK
import FLAnimatedImage

class OutgoingImageFileMessageTableViewCell: UITableViewCell {
    weak var delegate: MessageDelegate?
    @IBOutlet weak var messageContainerView: UIView!
    
    @IBOutlet weak var fileImageView: FLAnimatedImageView!
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var messageDateLabel: UILabel!
    @IBOutlet weak var imgMessageStatus: UIImageView!
    @IBOutlet weak var resendMessageButton: UIButton!
    

    @IBOutlet weak var cnMessageContainerLeftPadding: NSLayoutConstraint!
    private var message: SBDFileMessage!
    private var prevMessage: SBDBaseMessage!
    
    public var hasImageCacheData: Bool?
    public var containerBackgroundColour: UIColor = UIColor(red: 122.0/255.0, green: 188.0/255.0, blue: 65.0/255.0, alpha: 1.0)
    
    static func nib() -> UINib {        
        let podBundle = Bundle.bundleForXib(OutgoingFileMessageTableViewCell.self)
        return UINib(nibName: String(describing: self), bundle: podBundle)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        contentView.frame = UIEdgeInsetsInsetRect(contentView.frame, UIEdgeInsetsMake(10, 0, 0, 0))
    }
    
    override func awakeFromNib() {
//        self.messageContainerView.round(corners: [ .topLeft, .topRight, .bottomLeft ], radius: 15.0)
        self.messageContainerView.layer.cornerRadius = 8.0
        self.fileImageView.layer.cornerRadius = 8.0
        
    }
    
    static func cellReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    @objc private func clickFileMessage() {
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
    
    func setModel(aMessage: SBDFileMessage, channel: SBDBaseChannel?) {
        self.message = aMessage
        
        if self.hasImageCacheData == false {
            self.imageLoadingIndicator.isHidden = false
            self.imageLoadingIndicator.startAnimating()
        }
        else {
            self.imageLoadingIndicator.isHidden = true
            self.imageLoadingIndicator.stopAnimating()
        }
        
        self.fileImageView.animatedImage = nil
        self.fileImageView.image = nil

//        if self.message.url.characters.count > 0 {
//            if self.message.type == "image/gif" {
//                self.fileImageView.setAnimatedImageWithURL(url: URL(string: self.message.url)!, success: { (image) in
//                    DispatchQueue.main.async {
//                        self.fileImageView.animatedImage = image
//                        self.imageLoadingIndicator.isHidden = true
//                        self.imageLoadingIndicator.stopAnimating()
//                    }
//                }, failure: { (error) in
//                    /***********************************/
//                    /* Thumbnail is a premium feature. */
//                    /***********************************/
//                    if self.message.thumbnails != nil && (self.message.thumbnails?.count)! > 0 {
//                        if (self.message.thumbnails?[0].url.characters.count)! > 0 {
//                            let request = URLRequest(url: URL(string: (self.message.thumbnails?[0].url)!)!)
//                            self.fileImageView.af_setImage(withURLRequest: request, placeholderImage: nil, filter: nil, progress: nil, progressQueue: DispatchQueue.main, imageTransition: UIImageView.ImageTransition.noTransition, runImageTransitionIfCached: false, completion: { (response) in
//                                if response.result.error != nil {
//                                    DispatchQueue.main.async {
//                                        self.fileImageView.image = nil
//                                        self.imageLoadingIndicator.isHidden = true
//                                        self.imageLoadingIndicator.stopAnimating()
//                                    }
//                                }
//                                else {
//                                    DispatchQueue.main.async {
//                                        self.fileImageView.image = response.result.value
//                                        self.imageLoadingIndicator.isHidden = true
//                                        self.imageLoadingIndicator.stopAnimating()
//                                    }
//                                }
//                            })
//                        }
//                    }
//                    else {
//                        let request = URLRequest(url: URL(string: (self.message.url))!)
//                        self.fileImageView.af_setImage(withURLRequest: request, placeholderImage: nil, filter: nil, progress: nil, progressQueue: DispatchQueue.main, imageTransition: UIImageView.ImageTransition.noTransition, runImageTransitionIfCached: false, completion: { (response) in
//                            if response.result.error != nil {
//                                DispatchQueue.main.async {
//                                    self.fileImageView.image = nil
//                                    self.imageLoadingIndicator.isHidden = true
//                                    self.imageLoadingIndicator.stopAnimating()
//                                }
//                            }
//                            else {
//                                DispatchQueue.main.async {
//                                    self.fileImageView.image = response.result.value
//                                    self.imageLoadingIndicator.isHidden = true
//                                    self.imageLoadingIndicator.stopAnimating()
//                                }
//                            }
//                        })
//                    }
//                })
//            }
//            else {
//                /***********************************/
//                /* Thumbnail is a premium feature. */
//                /***********************************/
//                if self.message.thumbnails != nil && (self.message.thumbnails?.count)! > 0 {
//                    if (self.message.thumbnails?[0].url.characters.count)! > 0 {
//                        let request = URLRequest(url: URL(string: (self.message.thumbnails?[0].url)!)!)
//                        self.fileImageView.af_setImage(withURLRequest: request, placeholderImage: nil, filter: nil, progress: nil, progressQueue: DispatchQueue.main, imageTransition: UIImageView.ImageTransition.noTransition, runImageTransitionIfCached: false, completion: { (response) in
//                            if response.result.error != nil {
//                                DispatchQueue.main.async {
//                                    self.fileImageView.image = nil
//                                    self.imageLoadingIndicator.isHidden = true
//                                    self.imageLoadingIndicator.stopAnimating()
//                                }
//                            }
//                            else {
//                                DispatchQueue.main.async {
//                                    self.fileImageView.image = response.result.value
//                                    self.imageLoadingIndicator.isHidden = true
//                                    self.imageLoadingIndicator.stopAnimating()
//                                }
//                            }
//                        })
//                    }
//                }
//                else {
//                    let request = URLRequest(url: URL(string: (self.message.url))!)
//                    self.fileImageView.af_setImage(withURLRequest: request, placeholderImage: nil, filter: nil, progress: nil, progressQueue: DispatchQueue.main, imageTransition: UIImageView.ImageTransition.noTransition, runImageTransitionIfCached: false, completion: { (response) in
//                        if response.result.error != nil {
//                            DispatchQueue.main.async {
//                                self.fileImageView.image = nil
//                                self.imageLoadingIndicator.isHidden = true
//                                self.imageLoadingIndicator.stopAnimating()
//                            }
//                        }
//                        else {
//                            DispatchQueue.main.async {
//                                self.fileImageView.image = response.result.value
//                                self.imageLoadingIndicator.isHidden = true
//                                self.imageLoadingIndicator.stopAnimating()
//                            }
//                        }
//                    })
//                }
//            }
//        }
    
        let messageContainerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickFileMessage))
        self.fileImageView.isUserInteractionEnabled = true
        self.fileImageView.addGestureRecognizer(messageContainerTapRecognizer)

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
    
    func updateBackgroundColour () {
        self.messageContainerView.backgroundColor = self.containerBackgroundColour
    }
    
    func getHeightOfViewCell() -> CGFloat {

        return 210.0
        
        //        let height = self.dateSeperatorViewTopMargin.constant + self.dateSeperatorViewHeight.constant + self.dateSeperatorViewBottomMargin.constant + self.fileImageViewHeight.constant
//
//        return height
//        self.fileImageViewHeight.constant = 120.0
//        self.layoutSubviews()
//        return 170.0
    }
    
    
    func hideUnreadCount() {
        self.imgMessageStatus.isHidden = true
    }
    
    func showUnreadCount() {
        if self.message.channelType == CHANNEL_TYPE_GROUP {
            self.imgMessageStatus.isHidden = false
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
        self.resendMessageButton.isHidden = true
    }
    
    func showMessageDate() {
        self.imgMessageStatus.isHidden = true
        self.resendMessageButton.isHidden = true
        self.messageDateLabel.isHidden = false
    }
    
    func setImageData(data: Data, type: String) {
        if self.hasImageCacheData == true {
            self.imageLoadingIndicator.isHidden = true
            self.imageLoadingIndicator.stopAnimating()
        }
        
        if type == "image/gif" {
            let imageLoadQueue = DispatchQueue(label: "com.sendbird.imageloadqueue");
            imageLoadQueue.async {
                let animatedImage = FLAnimatedImage(animatedGIFData: data)
                DispatchQueue.main.async {
                    self.fileImageView.animatedImage = animatedImage;
                }
            }
        }
        else {
            self.fileImageView.image = UIImage(data: data)
        }
    }
}
