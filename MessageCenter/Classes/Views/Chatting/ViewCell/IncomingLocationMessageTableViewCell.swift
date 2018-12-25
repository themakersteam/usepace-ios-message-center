//
//  IncomingLocationMessageTableViewCell.swift
//  MessageCenter
//
//  Created by Ikarma Khan on 24/12/2018.
//

import UIKit
import TTTAttributedLabel
import SendBirdSDK
import CoreLocation

class IncomingLocationMessageTableViewCell: UITableViewCell {

    weak var delegate: MessageDelegate?
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgLocationPreview: UIImageView!
    @IBOutlet weak var messageDateLabel: UILabel!
    @IBOutlet weak var messageContainerView: UIView!
    
    private var message: SBDUserMessage!
    private var prevMessage: SBDBaseMessage?
    private var displayNickname: Bool = true
    private var podBundle: Bundle!
    public var containerBackgroundColour: UIColor = UIColor(red: 237.0/255.0, green: 237.0/255.0, blue: 237.0/255.0, alpha: 1.0)
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.podBundle =  Bundle.bundleForXib(IncomingLocationMessageTableViewCell.self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        messageContainerView.layer.cornerRadius = 8.0
    }
    
    static func nib() -> UINib {
        let podBundle =  Bundle.bundleForXib(IncomingLocationMessageTableViewCell.self)
        return UINib(nibName: String(describing: self), bundle: podBundle)
    }
    
    static func cellReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    @objc private func clickUserMessage() {
        if self.delegate != nil {
            let url = String.locationURL(strLocation: self.message.message!)!
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
 
    func setModel(aMessage: SBDUserMessage) {
        self.message = aMessage
        
        // location://?lat=24.816260999461292&long=46.640610342375126
        
        self.lblTitle.text = String.locationURL(strLocation: self.message.message!)?.absoluteString
        
        let messageContainerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickUserMessage))
        self.messageContainerView.isUserInteractionEnabled = true
        self.messageContainerView.addGestureRecognizer(messageContainerTapRecognizer)
        
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
    
    //    func updateBackgroundColour () {
    //        self.messageContainerView.backgroundColor = self.containerBackgroundColour
    //    }
    
    func getHeightOfViewCell() -> CGFloat {
        return 240.0
    }

}
