//
//  IncomingGeneralUrlPreviewMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 6/6/17.
//  Copyright © 2017 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import TTTAttributedLabel
import Alamofire
import AlamofireImage
import FLAnimatedImage

class IncomingGeneralUrlPreviewMessageTableViewCell: UITableViewCell, TTTAttributedLabelDelegate {
    
    
    @IBOutlet weak var previewThumbnailImageView: FLAnimatedImageView!
    @IBOutlet weak var previewSiteNameLabel: UILabel!
    @IBOutlet weak var previewTitleLabel: UILabel!
    @IBOutlet weak var previewDescriptionLabel: UILabel!
    @IBOutlet weak var previewThumbnailLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var messageDateLabel: UILabel!
    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var messageLabel: TTTAttributedLabel!
    
    
    @IBOutlet weak var cnImageHeight: NSLayoutConstraint!
    weak var delegate: MessageDelegate!
    private var message: SBDUserMessage!
    private var prevMessage: SBDBaseMessage!
    var previewData: Dictionary<String, Any>!
    private var displayNickname: Bool!
    private var podBundle: Bundle!
    public var containerBackgroundColour: UIColor = UIColor(red: 237.0/255.0, green: 237.0/255.0, blue: 237.0/255.0, alpha: 1.0)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)    
        self.podBundle = Bundle.bundleForXib(IncomingGeneralUrlPreviewMessageTableViewCell.self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.messageContainerView.layer.cornerRadius = 8.0        
    }
    
    static func nib() -> UINib {
        let podBundle = Bundle.bundleForXib(IncomingGeneralUrlPreviewMessageTableViewCell.self)
        return UINib(nibName: String(describing: self), bundle: podBundle)
    }
    
    static func cellReuseIdentifier() -> String {
        return String(describing: self)
    }

    @objc private func clickProfileImage() {
        if self.delegate != nil {
            self.delegate?.clickProfileImage(viewCell: self, user: self.message!.sender!)
        }
    }
    
    @objc private func clickFileMessage() {
        if self.delegate != nil {
            self.delegate?.clickMessage(view: self, message: self.message!)
        }
    }
    
    @objc private func clickPreview() {
        if self.delegate != nil {
            self.delegate?.clickMessage(view: self, message: self.message)
        }
    }
    
    func setModel(aMessage: SBDUserMessage) {
        self.message = aMessage
        
        let data = self.message.data?.data(using: String.Encoding.utf8)
        do {
            self.previewData = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? Dictionary
        }
        catch let error as NSError {
            print("Details of JSON parsing error:\n \(error)")
        }

        let siteName = self.previewData?["site_name"] as? String
        let title = self.previewData?["title"] as? String
        let description = self.previewData?["description"] as? String
        
        let previewThumbnailImageViewTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickPreview))
        self.previewThumbnailImageView.isUserInteractionEnabled = true
        self.previewThumbnailImageView.addGestureRecognizer(previewThumbnailImageViewTapRecognizer)
        
        let previewSiteNameLabelTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickPreview))
        self.previewSiteNameLabel.isUserInteractionEnabled = true
        self.previewSiteNameLabel.addGestureRecognizer(previewSiteNameLabelTapRecognizer)
        
        let previewTitleLabelTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickPreview))
        self.previewTitleLabel.isUserInteractionEnabled = true
        self.previewTitleLabel.addGestureRecognizer(previewTitleLabelTapRecognizer)
        
        let previewDescriptionLabelTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickPreview))
        self.previewDescriptionLabel.isUserInteractionEnabled = true
        self.previewDescriptionLabel.addGestureRecognizer(previewDescriptionLabelTapRecognizer)

        
        
        // Message Date
        let messageDateAttribute = [
            NSAttributedStringKey.font: Constants.messageDateFont(),
            NSAttributedStringKey.foregroundColor: Constants.messageDateColor()
        ]
        let messageTimestamp: TimeInterval = Double(self.message.createdAt) / 1000.0
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short
        let messageCreateDate: Date = NSDate.init(timeIntervalSince1970: messageTimestamp) as Date
        let messageDateString = dateFormatter.string(from: messageCreateDate)
        let messageDateAttributedString: NSMutableAttributedString = NSMutableAttributedString(string: messageDateString, attributes: messageDateAttribute)
        self.messageDateLabel.attributedText = messageDateAttributedString
                
        
        self.previewSiteNameLabel.text = siteName
        self.previewTitleLabel.text = title
        self.previewDescriptionLabel.text = description
        
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
        self.messageContainerView.addShadow()
        self.layoutIfNeeded()
    }
    
    func setPreviousMessage(aPrevMessage: SBDBaseMessage?) {
        self.prevMessage = aPrevMessage
    }
    
    private func buildMessage() -> NSMutableAttributedString {
//        var nicknameAttribute: [NSAttributedStringKey:NSObject]
//        switch (self.message.sender?.nickname?.count)! % 5 {
//        case 0:
//            nicknameAttribute = [
//                NSAttributedStringKey.font: Constants.nicknameFontInMessage(),
//                NSAttributedStringKey.foregroundColor: Constants.nicknameColorInMessageNo0()
//            ]
//        case 1:
//            nicknameAttribute = [
//                NSAttributedStringKey.font: Constants.nicknameFontInMessage(),
//                NSAttributedStringKey.foregroundColor: Constants.nicknameColorInMessageNo1()
//            ]
//        case 2:
//            nicknameAttribute = [
//                NSAttributedStringKey.font: Constants.nicknameFontInMessage(),
//                NSAttributedStringKey.foregroundColor: Constants.nicknameColorInMessageNo2()
//            ]
//        case 3:
//            nicknameAttribute = [
//                NSAttributedStringKey.font: Constants.nicknameFontInMessage(),
//                NSAttributedStringKey.foregroundColor: Constants.nicknameColorInMessageNo3()
//            ]
//        case 4:
//            nicknameAttribute = [
//                NSAttributedStringKey.font: Constants.nicknameFontInMessage(),
//                NSAttributedStringKey.foregroundColor: Constants.nicknameColorInMessageNo4()
//            ]
//        default:
//            nicknameAttribute = [
//                NSAttributedStringKey.font: Constants.nicknameFontInMessage(),
//                NSAttributedStringKey.foregroundColor: Constants.nicknameColorInMessageNo0()
//            ]
//        }
        
        let messageAttribute = [
            NSAttributedStringKey.font: Constants.messageFont()
        ]
//        let nickname = self.message.sender?.nickname
        let message = self.message.message
//        self.displayNickname = false
        var fullMessage: NSMutableAttributedString?
//        if self.displayNickname {
//            fullMessage = NSMutableAttributedString(string: String(format: "%@\n%@", nickname!, message!))
//            fullMessage?.addAttributes(nicknameAttribute, range: NSMakeRange(0, (nickname?.count)!))
//            fullMessage?.addAttributes(messageAttribute, range: NSMakeRange((nickname?.count)! + 1, (message?.count)!))
//        }
//        else {
//
//        }
        fullMessage = NSMutableAttributedString(string: String(format: "%@", message!))
        fullMessage?.addAttributes(messageAttribute, range: NSMakeRange(0, (message?.count)!))
        return fullMessage!
    }
    
    func updateBackgroundColour () {
        self.messageContainerView.backgroundColor = self.containerBackgroundColour
    }
    
    func getHeightOfViewCell() -> Float {
        self.cnImageHeight.constant = previewData["image"] == nil ? 0.0 : 85.0
        self.layoutIfNeeded()
        return Float(225.0 + cnImageHeight.constant)
    }
    
    // MARK: TTTAttributedLabelDelegate
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}
