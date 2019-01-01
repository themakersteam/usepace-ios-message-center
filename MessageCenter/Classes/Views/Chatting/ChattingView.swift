//
//  ChattingView.swift
//  SendBird-iOS
//
//  Created by Jed Kyung on 10/7/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import Alamofire
import AlamofireImage
import FLAnimatedImage

protocol ChattingViewDelegate: class {
    func loadMoreMessage(view: UIView)
    func startTyping(view: UIView)
    func endTyping(view: UIView)
    func hideKeyboardWhenFastScrolling(view: UIView)
}

class ChattingView: ReusableViewFromXib, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    // MARK : - IBOutlets
    @IBOutlet weak var messageTextView: SBMessageInputView!
    @IBOutlet weak var chattingTableView: UITableView!
    @IBOutlet weak var inputContainerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var cnTextViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var typingIndicatorImageHeight: NSLayoutConstraint!
    @IBOutlet weak var typingIndicatorContainerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var typingIndicatorImageView: UIImageView!
    @IBOutlet weak var typingIndicatorLabel: UILabel!
    @IBOutlet weak var typingIndicatorContainerView: UIView!    
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var inputContainerViewBackground: UIView!
    @IBOutlet weak var fileAttachButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var btnCamera: UIButton!
    
    @IBOutlet weak var chattingTableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var chattingTableViewBottomToSafeAreConstraint: NSLayoutConstraint!
    
    // MARK: - Vars
    var stopMeasuringVelocity: Bool = true
    var initialLoading: Bool = true
    var resendableFileData: [String:[String:AnyObject]] = [:]
    var preSendFileData: [String:[String:AnyObject]] = [:]
    var messages: [SBDBaseMessage] = []
    //var hasLoadedAllMessages: Bool = false
    var channel: SBDBaseChannel?
    var themeObject: ThemeObject?
    private var podBundle: Bundle!
    
    var welcomeMessage: String = ""
    
    var resendableMessages: [String:SBDBaseMessage] = [:]
    var preSendMessages: [String:SBDBaseMessage] = [:]
    
    var delegate: (ChattingViewDelegate & MessageDelegate)?

    // MARK: - Cells
    
    var neutralMessageSizingTableViewCell: NeutralMessageTableViewCell?
    
    var incomingUserMessageSizingTableViewCell: IncomingUserMessageTableViewCell?
    var outgoingUserMessageSizingTableViewCell: OutgoingUserMessageTableViewCell?
    
    var outgoingImageFileMessageSizingTableViewCell: OutgoingImageFileMessageTableViewCell?
    var incomingImageFileMessageSizingTableViewCell: IncomingImageFileMessageTableViewCell?
    
    var incomingGeneralUrlPreviewMessageTableViewCell: IncomingGeneralUrlPreviewMessageTableViewCell?
    var outgoingGeneralUrlPreviewMessageTableViewCell: OutgoingGeneralUrlPreviewMessageTableViewCell?
    // when sending URL
    var outgoingGeneralUrlPreviewTempMessageTableViewCell: OutgoingGeneralUrlPreviewTempMessageTableViewCell?
    
    var incomingUserLocationTableViewCell : IncomingLocationMessageTableViewCell?
    var outgoingUserLocationTableViewCell : OutgoingLocationMessageTableViewCell?
    //Cell to be shown at top with a welcome message
    var welcomeMessageTableViewCell : WelcomeMessageTableViewCell?
    
    
    var lastMessageHeight: CGFloat = 0
    var scrollLock: Bool = false
    
    var lastOffset: CGPoint = CGPoint(x: 0, y: 0)
    var lastOffsetCapture: TimeInterval = 0
    var isScrollingFast: Bool = false
    
    private var previousLine : Int = 0
    // MARK: - viewLifeCycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        self.podBundle = Bundle.bundleForXib(ChattingView.self)
        self.setup()
    }
    
    // MARK: - Helpers
    func setup() {
        self.chattingTableView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0)
        self.placeholderLabel.text = "type_message_hint".localized
    }
    
    func updateTheme(themeObject: ThemeObject) {
        self.themeObject = themeObject
        fileAttachButton.tintColor = themeObject.primaryActionIconsColor
        btnCamera.tintColor = themeObject.primaryActionIconsColor
        sendButton.backgroundColor = themeObject.primaryAccentColor
//        self.sendButton.imageView?.tintColor = self.themeObject?.primaryColor!
        sendButton.imageView?.tintColor = themeObject.primaryActionIconsColor
        sendButton.layer.cornerRadius = 22.0
        self.sendButton.imageView?.tintColor = self.themeObject?.primaryColor!
    }
    
    // MARK: - configureChatView
    
    func configureChattingView(channel: SBDBaseChannel?) {
        self.channel = channel;
        
        // Check if channel is frozen to hide the Text Sending view
        
        if self.channel != nil {
            if (self.channel?.isFrozen)! {
                self.inputContainerView.isHidden = true
                self.inputContainerViewBackground.isHidden = true
                self.chattingTableViewBottomConstraint.priority = UILayoutPriority(900)
                self.chattingTableViewBottomToSafeAreConstraint.priority = UILayoutPriority(990)
                
            }
            else {
                self.inputContainerView.isHidden = false
                self.inputContainerViewBackground.isHidden = false
                self.chattingTableViewBottomConstraint.priority = UILayoutPriority(990)
                self.chattingTableViewBottomToSafeAreConstraint.priority = UILayoutPriority(900)

            }
        }
        
        // Workaround: Attach button in Arabic Layout is shifting to the right
        if UIView.userInterfaceLayoutDirection(for: UIView.appearance().semanticContentAttribute) == .rightToLeft {
            fileAttachButton.imageEdgeInsets.left = -fileAttachButton.frame.width
        }
        
        
        self.initialLoading = true
        self.lastMessageHeight = 0
        self.scrollLock = false
        self.stopMeasuringVelocity = false
        
        self.typingIndicatorContainerView.isHidden = true
        self.typingIndicatorContainerViewHeight.constant = 0
        self.typingIndicatorImageHeight.constant = 0
        
//        self.typingIndicatorContainerView.layoutIfNeeded()
        
//        messageTextView.textContainerInset = UIEdgeInsetsMake(15, 1, 0, 0);
        messageTextView.layer.borderColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.12).cgColor
        self.messageTextView.layer.cornerRadius = 8.0
        self.messageTextView.layer.masksToBounds = true
        self.messageTextView.layer.borderWidth = 1.0
        self.messageTextView.delegate = self
        
        self.chattingTableView.register(IncomingUserMessageTableViewCell.nib(), forCellReuseIdentifier: IncomingUserMessageTableViewCell.cellReuseIdentifier())
        self.chattingTableView.register(OutgoingUserMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingUserMessageTableViewCell.cellReuseIdentifier())
        self.chattingTableView.register(NeutralMessageTableViewCell.nib(), forCellReuseIdentifier: NeutralMessageTableViewCell.cellReuseIdentifier())

        self.chattingTableView.register(OutgoingImageFileMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingImageFileMessageTableViewCell.cellReuseIdentifier())
        
        self.chattingTableView.register(IncomingImageFileMessageTableViewCell.nib(), forCellReuseIdentifier: IncomingImageFileMessageTableViewCell.cellReuseIdentifier())
        
        self.chattingTableView.register(IncomingGeneralUrlPreviewMessageTableViewCell.nib(), forCellReuseIdentifier: IncomingGeneralUrlPreviewMessageTableViewCell.cellReuseIdentifier())
        self.chattingTableView.register(OutgoingGeneralUrlPreviewMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingGeneralUrlPreviewMessageTableViewCell.cellReuseIdentifier())
        self.chattingTableView.register(OutgoingGeneralUrlPreviewTempMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingGeneralUrlPreviewTempMessageTableViewCell.cellReuseIdentifier())
        
        self.chattingTableView.register(WelcomeMessageTableViewCell.nib(), forCellReuseIdentifier: WelcomeMessageTableViewCell.cellReuseIdentifier())
        
        self.chattingTableView.register(IncomingLocationMessageTableViewCell.nib(), forCellReuseIdentifier: IncomingLocationMessageTableViewCell.cellReuseIdentifier())
        
        self.chattingTableView.register(OutgoingLocationMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingLocationMessageTableViewCell.cellReuseIdentifier())
        
        self.chattingTableView.delegate = self
        self.chattingTableView.dataSource = self
        
        self.initSizingCell()
    }
    
    func initSizingCell() {
        // Welcome Cell
        self.welcomeMessageTableViewCell = (WelcomeMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? WelcomeMessageTableViewCell)!
        self.welcomeMessageTableViewCell!.isHidden = true
        self.addSubview(self.welcomeMessageTableViewCell!)
        
        self.incomingUserMessageSizingTableViewCell = IncomingUserMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? IncomingUserMessageTableViewCell
        self.incomingUserMessageSizingTableViewCell?.isHidden = true
        self.addSubview(self.incomingUserMessageSizingTableViewCell!)
        
        self.outgoingUserMessageSizingTableViewCell = OutgoingUserMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? OutgoingUserMessageTableViewCell
        self.outgoingUserMessageSizingTableViewCell?.isHidden = true
        self.addSubview(self.outgoingUserMessageSizingTableViewCell!)
        
        self.neutralMessageSizingTableViewCell = NeutralMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? NeutralMessageTableViewCell
        self.neutralMessageSizingTableViewCell?.isHidden = true
        self.addSubview(self.neutralMessageSizingTableViewCell!)
        
        self.outgoingImageFileMessageSizingTableViewCell = OutgoingImageFileMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? OutgoingImageFileMessageTableViewCell
        self.outgoingImageFileMessageSizingTableViewCell?.isHidden = true
        self.addSubview(self.outgoingImageFileMessageSizingTableViewCell!)
        
        self.incomingImageFileMessageSizingTableViewCell = IncomingImageFileMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? IncomingImageFileMessageTableViewCell
        self.incomingImageFileMessageSizingTableViewCell?.isHidden = true
        self.addSubview(self.incomingImageFileMessageSizingTableViewCell!)
        
        self.incomingGeneralUrlPreviewMessageTableViewCell = IncomingGeneralUrlPreviewMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? IncomingGeneralUrlPreviewMessageTableViewCell
        self.incomingGeneralUrlPreviewMessageTableViewCell?.isHidden = true
        self.addSubview(self.incomingGeneralUrlPreviewMessageTableViewCell!)

        self.outgoingGeneralUrlPreviewMessageTableViewCell = OutgoingGeneralUrlPreviewMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? OutgoingGeneralUrlPreviewMessageTableViewCell
        self.outgoingGeneralUrlPreviewMessageTableViewCell?.isHidden = true
        self.addSubview(self.outgoingGeneralUrlPreviewMessageTableViewCell!)

        self.outgoingGeneralUrlPreviewTempMessageTableViewCell = OutgoingGeneralUrlPreviewTempMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? OutgoingGeneralUrlPreviewTempMessageTableViewCell
        
        self.outgoingGeneralUrlPreviewTempMessageTableViewCell?.isHidden = true
        self.addSubview(self.outgoingGeneralUrlPreviewTempMessageTableViewCell!)
        
        self.incomingUserLocationTableViewCell =
            IncomingLocationMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? IncomingLocationMessageTableViewCell
        self.incomingUserLocationTableViewCell?.isHidden = true
        self.addSubview(self.incomingUserLocationTableViewCell!)
        
        self.outgoingUserLocationTableViewCell =
            OutgoingLocationMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? OutgoingLocationMessageTableViewCell
        self.outgoingUserLocationTableViewCell?.isHidden = true
        self.addSubview(self.outgoingUserLocationTableViewCell!)
        
        
        
    }
    
    // MARK: - scrollHandler
    
    func scrollToBottom(force: Bool) {
        if self.messages.count == 0 {
            return
        }
        
        if self.scrollLock == true && force == false {
            return
        }
        if self.messages.count > 0 {
            self.chattingTableView.scrollToRow(at: IndexPath.init(row: self.messages.count - 1, section: 0), at: UITableViewScrollPosition.bottom, animated: false)
        }
        else {
            self.chattingTableView.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: UITableViewScrollPosition.bottom, animated: false)
        }
//        self.chattingTableView.setContentOffset(CGPoint(x: 0.0, y: CGFloat.greatestFiniteMagnitude), animated: true)
    }
    
    func scrollToPosition(position: Int) {
        if self.messages.count == 0 {
            return
        }
        
        self.chattingTableView.scrollToRow(at: IndexPath.init(row: position, section: 0), at: UITableViewScrollPosition.top, animated: false)
    }
    
    // MARK: - typingIndicatorHandlers
    
    func startTypingIndicator(text: String) {
        // Typing indicator
        self.typingIndicatorContainerView.isHidden = false
        self.typingIndicatorLabel.text = text
        
        self.typingIndicatorContainerViewHeight.constant = 26.0
        self.typingIndicatorImageHeight.constant = 26.0
        self.typingIndicatorContainerView.layoutIfNeeded()

        if self.typingIndicatorImageView.isAnimating == false {
            var typingImages: [UIImage] = []
            for i in 1...50 {
                let typingImageFrameName = String.init(format: "%02d.png", i)
                typingImages.append(UIImage(named: typingImageFrameName, in: podBundle, compatibleWith: nil)!)
            }
            self.typingIndicatorImageView.animationImages = typingImages
            self.typingIndicatorImageView.animationDuration = 1.5
            
            DispatchQueue.main.async {
                self.typingIndicatorImageView.startAnimating()
            }
        }
    }
    
    func endTypingIndicator() {
        DispatchQueue.main.async {
            self.typingIndicatorImageView.stopAnimating()
        }

        self.typingIndicatorContainerView.isHidden = true
        self.typingIndicatorContainerViewHeight.constant = 0
        self.typingIndicatorImageHeight.constant = 0
        
        self.typingIndicatorContainerView.layoutIfNeeded()
    }
    
    // MARK: - UITextViewDelegate
    
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == self.messageTextView {
            if textView.text.count > 0  {
                self.placeholderLabel.isHidden = true
                if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    self.btnCamera.isHidden = true
                    if self.cnTextViewTrailing.constant != 65.0 {
                        self.cnTextViewTrailing.constant = 65.0
                        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear, animations: {
                            self.layoutIfNeeded()
                        }) { (status) in
                            
                        }
                    }
                }
                if self.delegate != nil {
                    self.delegate?.startTyping(view: self)
                }
            }
            else {
                self.placeholderLabel.isHidden = false
                if self.cnTextViewTrailing.constant != 12.0 {
                    self.cnTextViewTrailing.constant = 12.0
                    UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear, animations: {
                        self.layoutIfNeeded()
                    }) { (status) in
                        
                    }
                }
                self.btnCamera.isHidden = false
                if self.delegate != nil {
                    self.delegate?.endTyping(view: self)
                }
            }
            let cursorPosition = textView.caretRect(for: textView.selectedTextRange!.start).origin
            if cursorPosition.x.isInfinite == true || cursorPosition.y.isInfinite == true {
                return
            }
            //textView.font!.lineHeight
            var currentLine = Int(cursorPosition.y / 16.0 )

            print(cursorPosition)
            print(textView.frame.size)
            print(currentLine)
            if cursorPosition.x >= (textView.frame.size.width - 15.0) {
                currentLine = currentLine + 1
            }
            
            if previousLine > currentLine {
                UIView.animate(withDuration: 0.3) {
                    if currentLine == 0 {
                        self.inputContainerViewHeight.constant = 44.0
                        textView.isScrollEnabled = false
                    }
                    else if currentLine <= 5 {
                        textView.isScrollEnabled = false
                        self.inputContainerViewHeight.constant = self.inputContainerViewHeight.constant - 17.0 // Padding
                    }
                    else {
                        textView.isScrollEnabled = true
                    }
                }
            }
            else if previousLine < currentLine {
                UIView.animate(withDuration: 0.3) {
                    if currentLine == 0 {
                        self.inputContainerViewHeight.constant = 44.0
                        textView.isScrollEnabled = false
                    }
                    else if currentLine >= 5 {
                        textView.isScrollEnabled = true
                    }
                    else {
                        textView.isScrollEnabled = false
                        self.inputContainerViewHeight.constant = self.inputContainerViewHeight.constant + 17.0 // Padding
                    }
                }
            }
            
            textView.layoutIfNeeded()
            
            self.updateConstraints()
            previousLine = currentLine
        }
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool{
        return true
    }
    
    
    // MARK: - scrollViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.stopMeasuringVelocity = false
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.stopMeasuringVelocity = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.chattingTableView {
            if self.stopMeasuringVelocity == false {
                let currentOffset = scrollView.contentOffset
                let currentTime = NSDate.timeIntervalSinceReferenceDate
                
                let timeDiff = currentTime - self.lastOffsetCapture
                if timeDiff > 0.1 {
                    let distance = currentOffset.y - self.lastOffset.y
                    let scrollSpeedNotAbs = distance * 10 / 1000
                    let scrollSpeed = fabs(scrollSpeedNotAbs)
                    if scrollSpeed > 0.5 {
                        self.isScrollingFast = true
                    }
                    else {
                        self.isScrollingFast = false
                    }
                    
                    self.lastOffset = currentOffset
                    self.lastOffsetCapture = currentTime
                }
                
                if self.isScrollingFast {
                    if self.delegate != nil {
                        self.delegate?.hideKeyboardWhenFastScrolling(view: self)
                    }
                }
            }
            
            if scrollView.contentOffset.y + scrollView.frame.size.height + self.lastMessageHeight < scrollView.contentSize.height {
                self.scrollLock = true
            }
            else {
                self.scrollLock = false
            }
            
            if scrollView.contentOffset.y == 0 {
                if self.messages.count > 0 && self.initialLoading == false {
                    if self.delegate != nil {
                        self.delegate?.loadMoreMessage(view: self)
                    }
                }
            }
        }
    }
    // MARK: - TableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row == 0 { //&& self.hasLoadedAllMessages == true {
            return 50.0
        }
        
        var height: CGFloat = 0
        
        let msg = self.messages[indexPath.row - 1] // (self.hasLoadedAllMessages == true ? 1 : 0)]
        
        if msg is SBDUserMessage {
            let userMessage = msg as! SBDUserMessage
            let sender = userMessage.sender
            
            if sender?.userId == SBDMain.getCurrentUser()?.userId {
                // Outgoing
                if userMessage.customType == "url_preview" {
                    if indexPath.row > 0 {
                        self.outgoingGeneralUrlPreviewMessageTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        self.outgoingGeneralUrlPreviewMessageTableViewCell?.setPreviousMessage(aPrevMessage: nil)
                    }
                    self.outgoingGeneralUrlPreviewMessageTableViewCell?.setModel(aMessage: userMessage, channel: self.channel)
                    height = (self.outgoingGeneralUrlPreviewMessageTableViewCell?.getHeightOfViewCell())!
                }
                    // Location Message
                else if (userMessage.message?.contains("location://"))! {
                    if indexPath.row > 0 {
                        self.outgoingUserLocationTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        self.outgoingUserLocationTableViewCell?.setPreviousMessage(aPrevMessage: nil)
                    }
                    self.outgoingUserLocationTableViewCell?.setModel(aMessage: userMessage, channel: self.channel)
                    self.outgoingUserLocationTableViewCell?.layoutSubviews()
                    height = (self.outgoingUserLocationTableViewCell?.getHeightOfViewCell())!
                }
                else {
                    if indexPath.row > 0 {
                        self.outgoingUserMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        self.outgoingUserMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
                    }
                    self.outgoingUserMessageSizingTableViewCell?.setModel(aMessage: userMessage, channel: self.channel)
                    self.outgoingUserMessageSizingTableViewCell?.layoutSubviews()
                    height = (self.outgoingUserMessageSizingTableViewCell?.getHeightOfViewCell())!
                }
            }
            else {
                // Incoming
                if userMessage.customType == "url_preview" {
                    if indexPath.row > 0 {
                        self.incomingGeneralUrlPreviewMessageTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        self.incomingGeneralUrlPreviewMessageTableViewCell?.setPreviousMessage(aPrevMessage: nil)
                    }
                    self.incomingGeneralUrlPreviewMessageTableViewCell?.setModel(aMessage: userMessage)
                    height = CGFloat((self.incomingGeneralUrlPreviewMessageTableViewCell?.getHeightOfViewCell())!)
                }
                else if (userMessage.message?.contains("location://"))! {
                    if indexPath.row > 0 {
                        self.incomingUserLocationTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        self.incomingUserLocationTableViewCell?.setPreviousMessage(aPrevMessage: nil)
                    }
                    self.incomingUserLocationTableViewCell?.setModel(aMessage: userMessage)
                    self.incomingUserLocationTableViewCell?.layoutSubviews()
                    height = (self.incomingUserLocationTableViewCell?.getHeightOfViewCell())!
                }
                else {
                    if indexPath.row > 0 {
                        self.incomingUserMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        self.incomingUserMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
                    }
                    self.incomingUserMessageSizingTableViewCell?.setModel(aMessage: userMessage)
                    height = (self.incomingUserMessageSizingTableViewCell?.getHeightOfViewCell())!
                }
                
            }
        }
        else if msg is SBDFileMessage {
            let fileMessage = msg as! SBDFileMessage
            let sender = fileMessage.sender
            
            if sender?.userId == SBDMain.getCurrentUser()?.userId {
                // Outgoing
                if fileMessage.type.hasPrefix("image") {
                    if indexPath.row > 0 {
                        self.outgoingImageFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        self.outgoingImageFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
                    }
                    self.outgoingImageFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage, channel: self.channel)
                    height = (self.outgoingImageFileMessageSizingTableViewCell?.getHeightOfViewCell())!
                }
            }
            else {
                // Incoming
                if fileMessage.type.hasPrefix("image") {
                    if indexPath.row > 0 {
                        self.incomingImageFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        self.incomingImageFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
                    }
                    self.incomingImageFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
                    height = (self.incomingImageFileMessageSizingTableViewCell?.getHeightOfViewCell())!
                }
            }
        }
        else if msg is SBDAdminMessage {
            let adminMessage = msg as! SBDAdminMessage
            if indexPath.row > 0 {
                self.neutralMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
            }
            else {
                self.neutralMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
            }
            
            self.neutralMessageSizingTableViewCell?.setModel(aMessage: adminMessage)
            height = (self.neutralMessageSizingTableViewCell?.getHeightOfViewCell())!
        }
        else if msg is OutgoingGeneralUrlPreviewTempModel {
            let tempModel: OutgoingGeneralUrlPreviewTempModel = msg as! OutgoingGeneralUrlPreviewTempModel
            if indexPath.row > 0 {
                self.outgoingGeneralUrlPreviewTempMessageTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
            }
            else {
                self.outgoingGeneralUrlPreviewTempMessageTableViewCell?.setPreviousMessage(aPrevMessage: nil)
            }
            self.outgoingGeneralUrlPreviewTempMessageTableViewCell?.setModel(aMessage: tempModel)
            height = (self.outgoingGeneralUrlPreviewTempMessageTableViewCell?.getHeightOfViewCell())!
        }
        
        if self.messages.count > 0 && self.messages.count - 1 == indexPath.row {
            self.lastMessageHeight = height
        }
        
        return height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    // MARK: -  UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if self.messages.count == 0 {
//            self.hasLoadedAllMessages = true
//        }
        return self.messages.count + 1 //self.hasLoadedAllMessages == true ? self.messages.count + 1 : self.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        if indexPath.row == 0 { //&& self.hasLoadedAllMessages == true {
            cell = tableView.dequeueReusableCell(withIdentifier: WelcomeMessageTableViewCell.cellReuseIdentifier())
            if self.themeObject != nil {
                (cell as! WelcomeMessageTableViewCell).lblMessage.text = self.themeObject?.welcomeMessage
            }
            else {
                (cell as! WelcomeMessageTableViewCell).lblMessage.text = "We are here to serve you!"
            }
            
            cell?.backgroundColor = .clear
            
            (cell as! WelcomeMessageTableViewCell).vwBackground.backgroundColor = self.themeObject?.primaryAccentColor
            (cell as! WelcomeMessageTableViewCell).vwBackground.alpha = 0.4
            (cell as! WelcomeMessageTableViewCell).vwBackground.layer.cornerRadius = 8.0
            (cell as! WelcomeMessageTableViewCell).vwBackground.layer.masksToBounds = true
            
            return cell!
        }
        
        let msg = self.messages[indexPath.row - 1] //(self.hasLoadedAllMessages == true ? 1 : 0)]
        
        if msg is SBDUserMessage {
            let userMessage = msg as! SBDUserMessage
            let sender = userMessage.sender
            
            if sender?.userId == SBDMain.getCurrentUser()?.userId {
                // Outgoing
                if userMessage.customType == "url_preview" {
                    cell = tableView.dequeueReusableCell(withIdentifier: OutgoingGeneralUrlPreviewMessageTableViewCell.cellReuseIdentifier())
                    
                    if themeObject != nil {
                        if themeObject?.primaryColor != nil {
                            (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).containerBackgroundColour = (themeObject?.primaryColor)!
                        }
                    }
                    (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).updateBackgroundColour()
                    
                    cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
                    if indexPath.row > 0 {
                        (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
                    }
                    (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).setModel(aMessage: userMessage, channel: self.channel)
                    (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).delegate = self.delegate
                    
                    if let imageUrl = (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewData["image"] as? String {
                        let ext = (imageUrl as NSString).pathExtension
                        
                        (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.image = nil
                        (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.animatedImage = nil
                        (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = false
                        (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.startAnimating()
                        
                        if !imageUrl.isEmpty {
                            if ext.lowercased().hasPrefix("gif") {
                                (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.setAnimatedImageWithURL(url: URL(string: imageUrl)! , success: { (image) in
                                    DispatchQueue.main.async {
                                        (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.animatedImage = image
                                        (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = true
                                        (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.stopAnimating()
                                    }
                                }, failure: { (error) in
                                    DispatchQueue.main.async {
                                        (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = true
                                        (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.stopAnimating()
                                    }
                                })
                            }
                            else {
                                Alamofire.request(imageUrl, method: .get).responseImage { response in
                                    guard let image = response.result.value else {
                                        DispatchQueue.main.async {
                                            (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = true
                                            (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.stopAnimating()
                                        }
                                        
                                        return
                                    }
                                    
                                    DispatchQueue.main.async {
                                        (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.image = image
                                        (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = true
                                        (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.stopAnimating()
                                    }
                                }
                            }
                        }
                        if self.preSendMessages[userMessage.requestId!] != nil {
                            (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).showSendingStatus()
                        }
                        else {
                            if self.resendableMessages[userMessage.requestId!] != nil {
                                (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).showMessageResendButton()
                                //                            (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).showFailedStatus()
                            }
                            else {
                                (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).showMessageStatus()
                            }
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = true
                            (cell as! OutgoingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.stopAnimating()
                        }
                    }
                }
                else if (userMessage.message?.contains("location://"))! {
                    cell = tableView.dequeueReusableCell(withIdentifier: OutgoingLocationMessageTableViewCell.cellReuseIdentifier())
                    
                    cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
                    if indexPath.row > 0 {
                        (cell as! OutgoingLocationMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        (cell as! OutgoingLocationMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
                    }
                    (cell as! OutgoingLocationMessageTableViewCell).setModel(aMessage: userMessage, channel: self.channel)
                    (cell as! OutgoingLocationMessageTableViewCell).delegate = self.delegate
                    
                    if themeObject != nil {
                        if themeObject?.primaryColor != nil {
                            (cell as! OutgoingLocationMessageTableViewCell).containerBackgroundColour = (themeObject?.primaryColor)!
                        }
                    }
                    (cell as! OutgoingLocationMessageTableViewCell).updateBackgroundColour()
                    
                    if self.preSendMessages[userMessage.requestId!] != nil {
                        (cell as! OutgoingLocationMessageTableViewCell).showSendingStatus()
                    }
                    else {
                        if self.resendableMessages[userMessage.requestId!] != nil {
                            (cell as! OutgoingLocationMessageTableViewCell).showMessageResendButton()
                            (cell as! OutgoingLocationMessageTableViewCell).showFailedStatus()
                        }
                        else {
                            (cell as! OutgoingLocationMessageTableViewCell).showMessageStatus()
                        }
                    }
                }
                else {
                    cell = tableView.dequeueReusableCell(withIdentifier: OutgoingUserMessageTableViewCell.cellReuseIdentifier())
                    
                    cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
                    if indexPath.row > 0 {
                        (cell as! OutgoingUserMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        (cell as! OutgoingUserMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
                    }
                    (cell as! OutgoingUserMessageTableViewCell).setModel(aMessage: userMessage, channel: self.channel)
                    (cell as! OutgoingUserMessageTableViewCell).delegate = self.delegate
                    
                    if themeObject != nil {
                        if themeObject?.primaryColor != nil {
                            (cell as! OutgoingUserMessageTableViewCell).containerBackgroundColour = (themeObject?.primaryColor)!
                        }
                    }
                    (cell as! OutgoingUserMessageTableViewCell).updateBackgroundColour()
                    
                    if self.preSendMessages[userMessage.requestId!] != nil {
                        (cell as! OutgoingUserMessageTableViewCell).showSendingStatus()
                    }
                    else {
                        if self.resendableMessages[userMessage.requestId!] != nil {
                            (cell as! OutgoingUserMessageTableViewCell).showMessageResendButton()
                            (cell as! OutgoingUserMessageTableViewCell).showFailedStatus()
                        }
                        else {
                            (cell as! OutgoingUserMessageTableViewCell).showMessageStatus()
                        }
                    }
                }
            }
            else {
                // Incoming
                if userMessage.customType == "url_preview" {
                    cell = tableView.dequeueReusableCell(withIdentifier: IncomingGeneralUrlPreviewMessageTableViewCell.cellReuseIdentifier())
                    cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
                    if indexPath.row > 0 {
                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
                    }
                    (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).setModel(aMessage: userMessage)
                    (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).delegate = self.delegate
                    
                    var ext: String?
                    if let imageUrl = (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewData["image"] as? String {
                        ext = (imageUrl as NSString).pathExtension
                        
                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.image = nil
                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.animatedImage = nil
                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = false
                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.startAnimating()
                        
                        if !imageUrl.isEmpty {
                            if ext!.lowercased().hasPrefix("gif") {
                                (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.setAnimatedImageWithURL(url: URL(string: imageUrl)! , success: { (image) in
                                    DispatchQueue.main.async {
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.image = nil
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.animatedImage = nil
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.animatedImage = image
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = true
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.stopAnimating()
                                    }
                                }, failure: { (error) in
                                    DispatchQueue.main.async {
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = true
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.stopAnimating()
                                    }
                                })
                            }
                            else {
                                Alamofire.request(imageUrl, method: .get).responseImage { response in
                                    guard let image = response.result.value else {
                                        DispatchQueue.main.async {
                                            (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = true
                                            (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.stopAnimating()
                                        }
                                        
                                        return
                                    }
                                    
                                    DispatchQueue.main.async {
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.image = image
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = true
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.stopAnimating()
                                    }
                                }
                            }
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = true
                            (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.stopAnimating()
                        }
                    }
                }
                else if (userMessage.message?.contains("location://"))! {
                    cell = tableView.dequeueReusableCell(withIdentifier: IncomingLocationMessageTableViewCell.cellReuseIdentifier())
                    
                    cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
                    if indexPath.row > 0 {
                        (cell as! IncomingLocationMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        (cell as! IncomingLocationMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
                    }
                    (cell as! IncomingLocationMessageTableViewCell).setModel(aMessage: userMessage)
                    (cell as! IncomingLocationMessageTableViewCell).delegate = self.delegate
                }
                else {
                    cell = tableView.dequeueReusableCell(withIdentifier: IncomingUserMessageTableViewCell.cellReuseIdentifier())
                    
                    cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
                    if indexPath.row > 0 {
                        (cell as! IncomingUserMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        (cell as! IncomingUserMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
                    }
                    (cell as! IncomingUserMessageTableViewCell).setModel(aMessage: userMessage)
                    (cell as! IncomingUserMessageTableViewCell).delegate = self.delegate
                }
            }
        }
        else if msg is SBDFileMessage {
            let fileMessage = msg as! SBDFileMessage
            let sender = fileMessage.sender
            
            if sender?.userId == SBDMain.getCurrentUser()?.userId {
                // Outgoing
                // MARK: - Outgoing - File Image
                if fileMessage.type.hasPrefix("image") {
                    cell = tableView.dequeueReusableCell(withIdentifier: OutgoingImageFileMessageTableViewCell.cellReuseIdentifier())
                    
                    if themeObject != nil {
                        if themeObject?.primaryColor != nil {
                            (cell as! OutgoingImageFileMessageTableViewCell).containerBackgroundColour = (themeObject?.primaryColor)!
                        }
                    }

                    (cell as! OutgoingImageFileMessageTableViewCell).updateBackgroundColour()
                    
                    cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
                    if indexPath.row > 0 {
                        (cell as! OutgoingImageFileMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        (cell as! OutgoingImageFileMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
                    }
                    (cell as! OutgoingImageFileMessageTableViewCell).setModel(aMessage: fileMessage, channel: self.channel)
                    (cell as! OutgoingImageFileMessageTableViewCell).delegate = self.delegate
                    
                    if self.preSendMessages[fileMessage.requestId!] != nil {
                        (cell as! OutgoingImageFileMessageTableViewCell).showSendingStatus()
                        (cell as! OutgoingImageFileMessageTableViewCell).hasImageCacheData = true
                        (cell as! OutgoingImageFileMessageTableViewCell).setImageData(data: self.preSendFileData[fileMessage.requestId!]!["data"] as! Data, type: self.preSendFileData[fileMessage.requestId!]!["type"] as! String)
                    }
                    else {
                        if self.resendableMessages[fileMessage.requestId!] != nil {
                            (cell as! OutgoingImageFileMessageTableViewCell).showMessageResendButton()
//                            (cell as! OutgoingImageFileMessageTableViewCell).showFailedStatus()
                            (cell as! OutgoingImageFileMessageTableViewCell).setImageData(data: self.resendableFileData[fileMessage.requestId!]?["data"] as! Data, type: self.resendableFileData[fileMessage.requestId!]?["type"] as! String)
                            (cell as! OutgoingImageFileMessageTableViewCell).hasImageCacheData = true
                        }
                        else {
                            if !fileMessage.url.isEmpty && self.preSendFileData[fileMessage.requestId!] != nil {
                                (cell as! OutgoingImageFileMessageTableViewCell).setImageData(data: self.preSendFileData[fileMessage.requestId!]?["data"] as! Data, type: self.preSendFileData[fileMessage.requestId!]?["type"] as! String)
                                (cell as! OutgoingImageFileMessageTableViewCell).hasImageCacheData = true
                                self.preSendFileData.removeValue(forKey: fileMessage.requestId!);
                            }
                            else {
                                (cell as! OutgoingImageFileMessageTableViewCell).hasImageCacheData = false
                                
                                var fileImageUrl = ""
                                if let thumbnails = fileMessage.thumbnails {
                                    let thumbnailsCount = thumbnails.count
                                    if thumbnailsCount > 0 && fileMessage.type != "image/gif" {
                                        fileImageUrl = thumbnails[0].url
                                    }
                                    else {
                                        fileImageUrl = fileMessage.url
                                    }
                                }
                                
                                (cell as! OutgoingImageFileMessageTableViewCell).fileImageView.image = nil
                                (cell as! OutgoingImageFileMessageTableViewCell).fileImageView.animatedImage = nil
                                
                                if fileMessage.type == "image/gif" {
                                    (cell as! OutgoingImageFileMessageTableViewCell).fileImageView.setAnimatedImageWithURL(url: URL(string: fileImageUrl)!, success: { (image) in
                                        DispatchQueue.main.async {
                                            let updateCell = tableView.cellForRow(at: indexPath) as? OutgoingImageFileMessageTableViewCell
                                            if updateCell != nil {
                                                (cell as! OutgoingImageFileMessageTableViewCell).fileImageView.animatedImage = image
                                                (cell as! OutgoingImageFileMessageTableViewCell).imageLoadingIndicator.stopAnimating()
                                                (cell as! OutgoingImageFileMessageTableViewCell).imageLoadingIndicator.isHidden = true
                                            }
                                        }
                                    }, failure: { (error) in
                                        DispatchQueue.main.async {
                                            let updateCell = tableView.cellForRow(at: indexPath) as? OutgoingImageFileMessageTableViewCell
                                            if updateCell != nil {
                                                (cell as! OutgoingImageFileMessageTableViewCell).fileImageView.af_setImage(withURL: URL(string: fileImageUrl)!)
                                                (cell as! OutgoingImageFileMessageTableViewCell).imageLoadingIndicator.stopAnimating()
                                                (cell as! OutgoingImageFileMessageTableViewCell).imageLoadingIndicator.isHidden = true
                                            }
                                        }
                                    })
                                }
                                else {
                                    let request = URLRequest(url: URL(string: fileImageUrl)!)
                                    (cell as! OutgoingImageFileMessageTableViewCell).fileImageView.af_setImage(withURLRequest: request, placeholderImage: nil, filter: nil, progress: nil, progressQueue: DispatchQueue.main, imageTransition: UIImageView.ImageTransition.noTransition, runImageTransitionIfCached: false, completion: { (response) in
                                        if response.result.error != nil {
                                            DispatchQueue.main.async {
                                                let updateCell = tableView.cellForRow(at: indexPath) as? OutgoingImageFileMessageTableViewCell
                                                if updateCell != nil {
                                                    (cell as! OutgoingImageFileMessageTableViewCell).fileImageView.image = nil
                                                    (cell as! OutgoingImageFileMessageTableViewCell).imageLoadingIndicator.isHidden = true
                                                    (cell as! OutgoingImageFileMessageTableViewCell).imageLoadingIndicator.stopAnimating()
                                                }
                                            }
                                        }
                                        else {
                                            DispatchQueue.main.async {
                                                let updateCell = tableView.cellForRow(at: indexPath) as? OutgoingImageFileMessageTableViewCell
                                                if updateCell != nil {
                                                    (cell as! OutgoingImageFileMessageTableViewCell).fileImageView.image = response.result.value
                                                    (cell as! OutgoingImageFileMessageTableViewCell).imageLoadingIndicator.isHidden = true
                                                    (cell as! OutgoingImageFileMessageTableViewCell).imageLoadingIndicator.stopAnimating()
                                                }
                                            }
                                        }
                                    })
                                }
                            }
                            (cell as! OutgoingImageFileMessageTableViewCell).showMessageStatus()
                        }
                    }
                }
            }
            else {
                // Incoming
                if fileMessage.type.hasPrefix("image") {
                    cell = tableView.dequeueReusableCell(withIdentifier: IncomingImageFileMessageTableViewCell.cellReuseIdentifier())
                    cell?.backgroundColor = (cell as! IncomingImageFileMessageTableViewCell).containerBackgroundColour
                    
                    cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
                    if indexPath.row > 0 {
                        (cell as! IncomingImageFileMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
                    }
                    else {
                        (cell as! IncomingImageFileMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
                    }
                    (cell as! IncomingImageFileMessageTableViewCell).setModel(aMessage: fileMessage)
                    (cell as! IncomingImageFileMessageTableViewCell).delegate = self.delegate
                    
                    var fileImageUrl = ""
                    if let thumbnails = fileMessage.thumbnails {
                        let thumbnailsCount = thumbnails.count
                        if thumbnailsCount > 0 && fileMessage.type != "image/gif" {
                            fileImageUrl = thumbnails[0].url
                        }
                        else {
                            fileImageUrl = fileMessage.url
                        }
                    }
                    
                    (cell as! IncomingImageFileMessageTableViewCell).fileImageView.image = nil
                    (cell as! IncomingImageFileMessageTableViewCell).fileImageView.animatedImage = nil
                    
                    (cell as! IncomingImageFileMessageTableViewCell).imageLoadingIndicator.isHidden = false
                    (cell as! IncomingImageFileMessageTableViewCell).imageLoadingIndicator.startAnimating()
                    
                    if fileMessage.type == "image/gif" {
                        (cell as! IncomingImageFileMessageTableViewCell).fileImageView.setAnimatedImageWithURL(url: URL(string: fileImageUrl)!, success: { (image) in
                            DispatchQueue.main.async {
                                let updateCell = tableView.cellForRow(at: indexPath) as? IncomingImageFileMessageTableViewCell
                                if updateCell != nil {
                                    (cell as! IncomingImageFileMessageTableViewCell).fileImageView.animatedImage = image
                                    (cell as! IncomingImageFileMessageTableViewCell).imageLoadingIndicator.stopAnimating()
                                    (cell as! IncomingImageFileMessageTableViewCell).imageLoadingIndicator.isHidden = true
                                }
                            }
                        }, failure: { (error) in
                            DispatchQueue.main.async {
                                let updateCell = tableView.cellForRow(at: indexPath) as? IncomingImageFileMessageTableViewCell
                                if updateCell != nil {
                                    (cell as! IncomingImageFileMessageTableViewCell).fileImageView.af_setImage(withURL: URL(string: fileImageUrl)!)
                                    (cell as! IncomingImageFileMessageTableViewCell).imageLoadingIndicator.stopAnimating()
                                    (cell as! IncomingImageFileMessageTableViewCell).imageLoadingIndicator.isHidden = true
                                }
                            }
                        })
                    }
                    else {
                        let request = URLRequest(url: URL(string: fileImageUrl)!)
                        (cell as! IncomingImageFileMessageTableViewCell).fileImageView.af_setImage(withURLRequest: request, placeholderImage: nil, filter: nil, progress: nil, progressQueue: DispatchQueue.main, imageTransition: UIImageView.ImageTransition.noTransition, runImageTransitionIfCached: false, completion: { (response) in
                            if response.result.error != nil {
                                DispatchQueue.main.async {
                                    let updateCell = tableView.cellForRow(at: indexPath) as? IncomingImageFileMessageTableViewCell
                                    if updateCell != nil {
                                        (cell as! IncomingImageFileMessageTableViewCell).fileImageView.image = nil
                                        (cell as! IncomingImageFileMessageTableViewCell).imageLoadingIndicator.isHidden = true
                                        (cell as! IncomingImageFileMessageTableViewCell).imageLoadingIndicator.stopAnimating()
                                    }
                                }
                            }
                            else {
                                DispatchQueue.main.async {
                                    let updateCell = tableView.cellForRow(at: indexPath) as? IncomingImageFileMessageTableViewCell
                                    if updateCell != nil {
                                        (cell as! IncomingImageFileMessageTableViewCell).fileImageView.image = response.result.value
                                        (cell as! IncomingImageFileMessageTableViewCell).imageLoadingIndicator.isHidden = true
                                        (cell as! IncomingImageFileMessageTableViewCell).imageLoadingIndicator.stopAnimating()
                                    }
                                }
                            }
                        })
                    }
                }
            }
        }
        else if msg is SBDAdminMessage {
            let adminMessage = msg as! SBDAdminMessage
            
            cell = tableView.dequeueReusableCell(withIdentifier: NeutralMessageTableViewCell.cellReuseIdentifier())
            cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
            if indexPath.row > 0 {
                (cell as! NeutralMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
            }
            else {
                (cell as! NeutralMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
            }
            
            (cell as! NeutralMessageTableViewCell).setModel(aMessage: adminMessage)
        }
        else if msg is OutgoingGeneralUrlPreviewTempModel {
            let model = msg as! OutgoingGeneralUrlPreviewTempModel
            
            cell = tableView.dequeueReusableCell(withIdentifier: OutgoingGeneralUrlPreviewTempMessageTableViewCell.cellReuseIdentifier())
            cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
            if indexPath.row > 0 {
                (cell as! OutgoingGeneralUrlPreviewTempMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
            }
            else {
                (cell as! OutgoingGeneralUrlPreviewTempMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
            }
            
            (cell as! OutgoingGeneralUrlPreviewTempMessageTableViewCell).setModel(aMessage: model)
        }
        
        cell?.backgroundColor = .clear
        return cell!
    }
}

extension ChattingView: SBMessageInputViewDelegate {
    func inputViewDidTapButton(button: UIButton) {
        
    }
    func inputViewDidBeginEditing(textView: UITextView) {
        
    }
    func inputViewShouldBeginEditing(textView: UITextView) -> Bool {
        return true
    }
    func inputView(textView: UITextView, shouldChangeTextInRange: NSRange, replacementText: String) -> Bool {
        
        return true
    }
    
    func inputViewDidChange(textView: UITextView) {
        if textView.text.count > 0  {
            self.placeholderLabel.isHidden = true
            if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                self.btnCamera.isHidden = true
                if self.cnTextViewTrailing.constant != 65.0 {
                    self.cnTextViewTrailing.constant = 65.0
                    UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveLinear, animations: {
                        self.layoutIfNeeded()
                    }) { (status) in
                        
                    }
                }
                textView.contentInset = UIEdgeInsets(top: textView.contentInset.top, left: 0.0, bottom: 0.0, right: 0.0)
            }
            else {
                self.messageTextView.backgroundColor = .white
            }
            if self.delegate != nil {
                self.delegate?.startTyping(view: self)
            }
        }
        else {
            if #available(iOS 9.0, *) {
                if UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft {
                    textView.contentInset = UIEdgeInsets(top: textView.contentInset.top, left: 12.0, bottom: 0.0, right: 0.0)
                }
            } else {
                if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                    textView.contentInset = UIEdgeInsets(top: textView.contentInset.top, left: 12.0, bottom: 0.0, right: 0.0)
                }
            }
            self.placeholderLabel.isHidden = false
            self.messageTextView.backgroundColor = .clear
            if self.cnTextViewTrailing.constant != 12.0 {
                self.cnTextViewTrailing.constant = 12.0
                UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveLinear, animations: {
                    self.layoutIfNeeded()
                    self.inputContainerViewHeight.constant = 44.0
                }) { (status) in
                    
                }
            }
            self.btnCamera.isHidden = false
            if self.delegate != nil {
                self.delegate?.endTyping(view: self)
            }
        }
    }
}
