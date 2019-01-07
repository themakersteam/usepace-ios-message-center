//
//  IncomingImageFileMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Kyung on 10/6/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit
import AlamofireImage
import SendBirdSDK
import FLAnimatedImage

class IncomingImageFileMessageTableViewCell: UITableViewCell {
    weak var delegate: MessageDelegate?
    
    
    @IBOutlet weak var fileImageView: FLAnimatedImageView!
    @IBOutlet weak var messageDateLabel: UILabel!
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var messageContainer: UIView!
    

    private var message: SBDFileMessage!
    private var prevMessage: SBDBaseMessage!
    private var cachedMessage: Bool = true
    
    private var podBundle: Bundle!
    public var containerBackgroundColour: UIColor = UIColor(red: 237.0/255.0, green: 237.0/255.0, blue: 237.0/255.0, alpha: 1.0)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.podBundle =  Bundle.bundleForXib(IncomingImageFileMessageTableViewCell.self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        messageContainer.layer.cornerRadius = 8.0
        fileImageView.layer.cornerRadius = 8.0
    }
    
    static func nib() -> UINib {
        let podBundle =  Bundle.bundleForXib(IncomingImageFileMessageTableViewCell.self)
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
    
    func setModel(aMessage: SBDFileMessage) {
        self.message = aMessage
        
        let messageContainerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickFileMessage))
        self.fileImageView.isUserInteractionEnabled = true
        self.fileImageView.addGestureRecognizer(messageContainerTapRecognizer)
        
        self.imageLoadingIndicator.isHidden = true
//        self.fileImageView.animatedImage = nil;
//        self.fileImageView.image = nil;
//
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
        self.messageContainer.addShadow()
        self.layoutIfNeeded()
    }
    
    func setPreviousMessage(aPrevMessage: SBDBaseMessage?) {
        self.prevMessage = aPrevMessage
    }
    
//    func updateBackgroundColour () {
//        self.messageContainerView.backgroundColor = self.containerBackgroundColour
//    }
    
    func getHeightOfViewCell() -> CGFloat {
        return 210.0
    }
}
