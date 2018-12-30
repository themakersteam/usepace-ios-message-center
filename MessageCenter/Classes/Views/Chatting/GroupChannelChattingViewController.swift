//
//  GroupChannelChattingViewController.swift
//  SendBird-iOS
//
//  Created by Jed Kyung on 10/10/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import AVKit
import AVFoundation
import MobileCoreServices
import Photos
import NYTPhotoViewer
import HTMLKit
import FLAnimatedImage
import Toast

class GroupChannelChattingViewController: UIViewController, SBDConnectionDelegate, SBDChannelDelegate, ChattingViewDelegate, MessageDelegate, UINavigationControllerDelegate {
    
    static var instance: GroupChannelChattingViewController?
    // MARK: - Variables
    //MARK: -
    var groupChannel: SBDGroupChannel!
    var themeObject: ThemeObject?
    var welcomeMessage : String = ""
    
    private var podBundle: Bundle!
    private var messageQuery: SBDPreviousMessageListQuery!
    private var delegateIdentifier: String!
    private var hasNext: Bool = true
    private var isLoading: Bool = false
    private var keyboardShown: Bool = false
    private var photosViewController: NYTPhotosViewController!
    private var minMessageTimestamp: Int64 = Int64.max
    private var dumpedMessages: [SBDBaseMessage] = []
    private var cachedMessage: Bool = true
    private var mediaInfo : [String: Any]?
    private var imageCaption: String = ""
    
    // MARK: - IBOutlets
    //MARK: -
    @IBOutlet weak var vwActionSheet: UIView!
    @IBOutlet weak var chattingView: ChattingView!
    
    @IBOutlet weak var bottomMargin: NSLayoutConstraint!
    @IBOutlet weak var imageViewerLoadingView: UIView!
    @IBOutlet weak var imageViewerLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageViewerLoadingViewNavItem: UINavigationItem!
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSubTitle: UILabel!
    @IBOutlet weak var btnBack: UIButton!
    
    @IBOutlet weak var patternView: UIView!
    
    //MARK: - viewLifeCycle
    //MARK: -
    override func viewDidLoad() {
    
        super.viewDidLoad()
        GroupChannelChattingViewController.instance = self
        self.podBundle = Bundle.bundleForXib(GroupChannelChattingViewController.self)
        setNavigationItems()

        if themeObject != nil {
            self.patternView.backgroundColor = self.themeObject?.primaryBackgroundColor
        }
        
//        self.patternView.backgroundColor = UIColor(patternImage: UIImage(named: "mainpattern.png", in: podBundle, compatibleWith: nil)!)
//        
        let negativeLeftSpacerForImageViewerLoading = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        negativeLeftSpacerForImageViewerLoading.width = -2
        
        let leftCloseItemForImageViewerLoading = UIBarButtonItem(image: UIImage(named: "btn_close.png", in: podBundle, compatibleWith: nil), style: UIBarButtonItemStyle.done, target: self, action: #selector(close))
        
        self.imageViewerLoadingViewNavItem.leftBarButtonItems = [negativeLeftSpacerForImageViewerLoading, leftCloseItemForImageViewerLoading]
        
        self.delegateIdentifier = self.description
        SBDMain.add(self as SBDChannelDelegate, identifier: self.delegateIdentifier)
        
        self.hasNext = true
        self.isLoading = false
        if self.themeObject != nil {
            self.chattingView.updateTheme(themeObject: themeObject!)
        }
        self.chattingView.fileAttachButton.addTarget(self, action: #selector(openAttachmentActionSheet), for: UIControlEvents.touchUpInside)
        self.chattingView.btnCamera.addTarget(self, action: #selector(launchCamera), for: .touchUpInside)
        
        self.chattingView.sendButton.addTarget(self, action: #selector(sendMessage), for: UIControlEvents.touchUpInside)
        self.chattingView.configureChattingView(channel: self.groupChannel)
        self.chattingView.delegate = self
        self.minMessageTimestamp = LLONG_MAX
        self.cachedMessage = false
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:))))
        if SBDMain.getConnectState() == .closed {
            SBDMain.connect(withUserId: (lastConnectionRequest?.userId)!, accessToken: lastConnectionRequest?.accessToken) { (user, error) in
                if error == nil {
                    self.loadMessages()
                }
            }
        }
        else {
            self.loadMessages()
        }
        
        // Delete all the pre-saved images in directory as we really don't need those
        self.deleteDirectory()
    }
    
    deinit {
        //        ConnectionManager.remove(connectionObserver: self as ConnectionManagerDelegate)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addObservers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.chattingView.chattingTableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc private func close() {
        
        if self.chattingView.preSendMessages.count > 0 {
            let alertController = UIAlertController(title: "", message: "image_uploading_in_progress_message".localized, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "yes".localized, style: .cancel) { (action) in
                self.closeTheChannelAndDimiss()
            }
            let cancelAction = UIAlertAction(title: "no".localized, style: .default) { (action) in
                if self.chattingView.preSendMessages.count > 0 {
                    print(self.chattingView.preSendMessages)
//                    self.deleteMesage(self.chattingView.preSendMessages)
                }
            }
            
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
        else {
            self.closeTheChannelAndDimiss()
        }
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Utils.dumpMessages(
            messages: self.chattingView.messages,
            resendableMessages: self.chattingView.resendableMessages,
            resendableFileData: self.chattingView.resendableFileData,
            preSendMessages: self.chattingView.preSendMessages,
            channelUrl: self.groupChannel.channelUrl
        )
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    
    //MARK: - DeleteMessages
    //MARK: -
    
    private func closeTheChannelAndDimiss() {
        
        SBDMain.removeChannelDelegate(forIdentifier: self.description)
        SBDMain.removeConnectionDelegate(forIdentifier: self.description)
        if MessageCenter.completionHandler != nil {
            MessageCenter.completionHandler!(true)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    private func deleteMesages() {
        if let message = self.chattingView.preSendMessages.first {
            self.groupChannel.delete(message.value) { (error) in
                _ = self.chattingView.preSendMessages.popFirst()
                self.deleteMesages()
            }
        }
        else {
            self.closeTheChannelAndDimiss()
        }
    }
    
    //MARK: - LoadMessages
    //MARK: -
    private func loadMessages () {
        self.dumpedMessages = Utils.loadMessagesInChannel(channelUrl: self.groupChannel.channelUrl)
        if self.dumpedMessages.count > 0 {
            self.chattingView.messages.append(contentsOf: self.dumpedMessages)
            
            self.chattingView.chattingTableView.reloadData()
            self.chattingView.chattingTableView.layoutIfNeeded()
            
            let viewHeight = UIScreen.main.bounds.size.height - 95.0 - self.chattingView.inputContainerViewHeight.constant - 10
            let contentSize = self.chattingView.chattingTableView.contentSize
            self.chattingView.scrollToBottom(force: true)
            if contentSize.height > viewHeight {
                let newContentOffset = CGPoint(x: 0, y: contentSize.height - viewHeight)
                // self.chattingView.chattingTableView.setContentOffset(newContentOffset, animated: false)
            }
            
            self.cachedMessage = true
        }
        
        self.loadPreviousMessage(initial: true)
        self.chattingView.scrollToBottom(force: true)
    }

    private func loadPreviousMessage(initial: Bool) {
        var timestamp: Int64 = 0
        if initial {
            self.hasNext = true
            timestamp = Int64.max
        }
        else {
            timestamp = self.minMessageTimestamp
        }
        
        if self.hasNext == false {
            return
        }
        
        if self.isLoading {
            return
        }
        
        self.isLoading = true
        
        self.groupChannel.getPreviousMessages(byTimestamp: timestamp, limit: 30, reverse: !initial, messageType: SBDMessageTypeFilter.all, customType: "") { (messages, error) in
            if error != nil {
                self.isLoading = false
                
                return
            }
            
            self.cachedMessage = false
            
            if messages?.count == 0 {
                self.hasNext = false
                self.chattingView.hasLoadedAllMessages = true
                self.chattingView.welcomeMessage = self.welcomeMessage
                self.chattingView.chattingTableView.reloadData()
                self.chattingView.scrollToBottom(force: true)
            }
            
            if initial {
                self.chattingView.messages.removeAll()
                
                for item in messages! {
                    let message: SBDBaseMessage = item as SBDBaseMessage
                    self.chattingView.messages.append(message)
                    if self.minMessageTimestamp > message.createdAt {
                        self.minMessageTimestamp = message.createdAt
                    }
                }
                
                let resendableMessagesKeys = self.chattingView.resendableMessages.keys
                for item in resendableMessagesKeys {
                    let key = item as String
                    self.chattingView.messages.append(self.chattingView.resendableMessages[key]!)
                }
                
                let preSendMessagesKeys = self.chattingView.preSendMessages.keys
                for item in preSendMessagesKeys {
                    let key = item as String
                    self.chattingView.messages.append(self.chattingView.preSendMessages[key]!)
                }
                
                self.groupChannel.markAsRead()
                
                self.chattingView.initialLoading = true
                
                if (messages?.count)! > 0 {
                    DispatchQueue.main.async {
                        self.chattingView.chattingTableView.reloadData()
                        self.chattingView.chattingTableView.layoutIfNeeded()
                        
                        var viewHeight: CGFloat
                        if self.keyboardShown {
                            viewHeight = self.chattingView.chattingTableView.frame.size.height - 10
                        }
                        else {
                            viewHeight = UIScreen.main.bounds.size.height - 95.0 - self.chattingView.inputContainerViewHeight.constant - 10
                        }
                        
//                        let contentSize = self.chattingView.chattingTableView.contentSize
                        self.chattingView.scrollToBottom(force: true)
  //                      if contentSize.height > viewHeight {
//                            let newContentOffset = CGPoint(x: 0, y: contentSize.height - viewHeight)
                            // self.chattingView.chattingTableView.setContentOffset(newContentOffset, animated: false)
                        //}
                    }
                }
                
                self.chattingView.initialLoading = false
                self.isLoading = false
            }
            else {
                if (messages?.count)! > 0 {
                    for item in messages! {
                        let message: SBDBaseMessage = item as SBDBaseMessage
                        self.chattingView.messages.insert(message, at: 0)
                        
                        if self.minMessageTimestamp > message.createdAt {
                            self.minMessageTimestamp = message.createdAt
                        }
                    }
                    
                    DispatchQueue.main.async {
//                        let contentSizeBefore = self.chattingView.chattingTableView.contentSize
                        
                        self.chattingView.chattingTableView.reloadData()
  //                      self.chattingView.chattingTableView.layoutIfNeeded()
                        if initial == true {
                            self.chattingView.scrollToBottom(force: true)
                        }
                        
                        //let contentSizeAfter = self.chattingView.chattingTableView.contentSize
                        
                       // let newContentOffset = CGPoint(x: 0, y: contentSizeAfter.height - contentSizeBefore.height)
                        // self.chattingView.chattingTableView.setContentOffset(newContentOffset, animated: false)
                    }
                }
                
                self.isLoading = false
            }
        }
//        self.chattingView.scrollToBottom(force: true)
    }
    
    //MARK: - Send Messages
    //MARK: -
    func sendUrlPreview(url: URL, message: String, aTempModel: OutgoingGeneralUrlPreviewTempModel) {
        let tempModel = aTempModel
        let previewUrl = url;
        let request = URLRequest(url: url)
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            if error != nil || data?.count == 0 || data == nil {
                self.sendMessageWithReplacement(replacement: aTempModel)
                session.invalidateAndCancel()
                
                return
            }
            
            let httpResponse: HTTPURLResponse = response as! HTTPURLResponse
            let contentType: String = httpResponse.allHeaderFields["Content-Type"] as! String
            if contentType.contains("text/html") {
                
                let htmlBody = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                let parser: HTMLParser = HTMLParser(string: htmlBody! as String)
                let document = parser.parseDocument()
                let head = document.head
                
                var title: String?
                var desc: String?
                
                var ogUrl: String?
                var ogSiteName: String?
                var ogTitle: String?
                var ogDesc: String?
                var ogImage: String?
                
                var twtSiteName: String?
                var twtTitle: String?
                var twtDesc: String?
                var twtImage: String?
                
                var finalUrl: String?
                var finalTitle: String?
                var finalSiteName: String?
                var finalDesc: String?
                var finalImage: String?
                
                for node in (head?.childNodes)! {
                    if node is HTMLElement {
                        let element: HTMLElement = node as! HTMLElement
                        if element.attributes["property"] != nil {
                            if ogUrl == nil && element.attributes["property"] as! String == "og:url" {
                                ogUrl = element.attributes["property"] as? String
                            }
                            else if ogSiteName == nil && element.attributes["property"] as! String == "og:site_name" {
                                ogSiteName = element.attributes["content"] as? String
                            }
                            else if ogTitle == nil && element.attributes["property"] as! String == "og:title" {
                                ogTitle = element.attributes["content"] as? String
                            }
                            else if ogDesc == nil && element.attributes["property"] as! String == "og:description" {
                                ogDesc = element.attributes["content"] as? String
                            }
                            else if ogImage == nil && element.attributes["property"] as! String == "og:image" {
                                ogImage = element.attributes["content"] as? String
                            }
                        }
                        else if element.attributes["name"] != nil {
                            if twtSiteName == nil && element.attributes["name"] as! String == "twitter:site" {
                                twtSiteName = element.attributes["content"] as? String
                            }
                            else if twtTitle == nil && element.attributes["name"] as! String == "twitter:title" {
                                twtTitle = element.attributes["content"] as? String
                            }
                            else if twtDesc == nil && element.attributes["name"] as! String == "twitter:description" {
                                twtDesc = element.attributes["content"] as? String
                            }
                            else if twtImage == nil && element.attributes["name"] as! String == "twitter:image" {
                                twtImage = element.attributes["content"] as? String
                            }
                            else if desc == nil && element.attributes["name"] as! String == "description" {
                                desc = element.attributes["content"] as? String
                            }
                        }
                        else if element.tagName == "title" {
                            if element.childNodes.count > 0 {
                                if element.childNodes[0] is HTMLText {
                                    title = (element.childNodes[0] as! HTMLText).data
                                }
                            }
                        }
                    }
                }
                
                if ogUrl != nil {
                    finalUrl = ogUrl
                }
                else {
                    finalUrl = previewUrl.absoluteString
                }
                
                if ogSiteName != nil {
                    finalSiteName = ogSiteName
                }
                else if twtSiteName != nil {
                    finalSiteName = twtSiteName
                }
                
                if ogTitle != nil {
                    finalTitle = ogTitle
                }
                else if twtTitle != nil {
                    finalTitle = twtTitle
                }
                else if title != nil {
                    finalTitle = title
                }
                
                if ogDesc != nil {
                    finalDesc = ogDesc
                }
                else if twtDesc != nil {
                    finalDesc = twtDesc
                }
                
                if ogImage != nil {
                    finalImage = ogImage
                }
                else if twtImage != nil {
                    finalImage = twtImage
                }
                
                if !(finalSiteName == nil || finalTitle == nil || finalDesc == nil) {
                    var data:[String:String] = [:]
                    data["site_name"] = finalSiteName
                    data["title"] = finalTitle
                    data["description"] = finalDesc
                    if finalImage != nil {
                        data["image"] = finalImage
                    }
                    
                    if finalUrl != nil {
                        data["url"] = finalUrl
                    }
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions.init(rawValue: 0))
                        let dataString = String(data: jsonData, encoding: String.Encoding.utf8)
                        
                        self.groupChannel.sendUserMessage(message, data: dataString, customType: "url_preview", completionHandler: { (userMessage, error) in
                            if error != nil {
                                self.sendMessageWithReplacement(replacement: aTempModel)
                                
                                return
                            }
                            
                            self.chattingView.messages[self.chattingView.messages.index(of: tempModel)!] = userMessage!
                            DispatchQueue.main.async {
                                self.chattingView.chattingTableView.reloadData()
                                DispatchQueue.main.async {
                                    self.chattingView.scrollToBottom(force: true)
                                }
                            }
                        })
                    }
                    catch {
                        
                    }
                }
                else {
                    self.sendMessageWithReplacement(replacement: aTempModel)
                }
            }
            
            // end - if
            session.invalidateAndCancel()
        }
        
        task.resume()
    }
    
    private func sendMessageWithReplacement(replacement: OutgoingGeneralUrlPreviewTempModel) {
        let preSendMessage: SBDUserMessage = self.groupChannel.sendUserMessage(replacement.message, data: "", customType:"", targetLanguages: ["ar", "de", "fr", "nl", "ja", "ko", "pt", "es", "zh-CHS"]) { (userMessage, error) in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(150), execute: {
                if let preSendMessage : SBDUserMessage = self.chattingView.preSendMessages[(userMessage?.requestId)!] as? SBDUserMessage {
                    guard error == nil else {
                        self.chattingView.resendableMessages[(userMessage?.requestId)!] = userMessage
                        self.chattingView.chattingTableView.reloadData()
                        DispatchQueue.main.async {
                            self.chattingView.scrollToBottom(force: true)
                        }
                        
                        return
                    }
                    
                    self.chattingView.preSendMessages.removeValue(forKey: (userMessage?.requestId)!)
                    
                    self.chattingView.messages[self.chattingView.messages.index(of: preSendMessage)!] = userMessage!
                    
                    self.chattingView.chattingTableView.reloadData()
                    DispatchQueue.main.async {
                        self.chattingView.scrollToBottom(force: true)
                    }
                }
            })
        }
        
        if let index = self.chattingView.messages.index(of: replacement) {
            self.chattingView.messages[index] = preSendMessage
            self.chattingView.preSendMessages[preSendMessage.requestId!] = preSendMessage
            DispatchQueue.main.async {
                self.chattingView.chattingTableView.reloadData()
                DispatchQueue.main.async {
                    self.chattingView.scrollToBottom(force: true)
                }
            }
        }
    }
    
    @objc private func sendMessage() {
        
        if (self.chattingView.messageTextView.textView.text.count > 0 || imageCaption.count > 0) {
            self.groupChannel.endTyping()
            var message = ""
            if self.chattingView.messageTextView.textView.text.count > 0 &&
                self.chattingView.messageTextView.textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                
                message = self.chattingView.messageTextView.textView.text
            }
                
            else if imageCaption.count > 0 &&
                imageCaption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                
                message = self.imageCaption
            }
            else  {
                return
            }
            
            self.chattingView.messageTextView.textView.text = ""
            self.imageCaption = ""
            self.chattingView.inputViewDidChange(textView: self.chattingView.messageTextView.textView)
            
            do {
                let detector: NSDataDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                let matches: [NSTextCheckingResult] = detector.matches(in: message, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, (message.count)))
                var url: URL?
                for item in matches {
                    let match = item as NSTextCheckingResult
                    url = match.url
                    break
                }
                
                if url != nil {
                    let tempModel: OutgoingGeneralUrlPreviewTempModel = OutgoingGeneralUrlPreviewTempModel()
                    tempModel.createdAt = Int64(NSDate().timeIntervalSince1970 * 1000)
                    tempModel.message = message
                    
                    self.chattingView.messages.append(tempModel)
                    DispatchQueue.main.async {
                        self.chattingView.chattingTableView.reloadData()
                        DispatchQueue.main.async {
                            self.chattingView.scrollToBottom(force: true)
                        }
                    }
                    
                    // Send preview
                    self.sendUrlPreview(url: url!, message: message, aTempModel: tempModel)
                    
                    return
                }
            }
            catch {
                
            }
            
            self.chattingView.sendButton.isEnabled = false
            let preSendMessage = self.groupChannel.sendUserMessage(message, data: "", customType: "", targetLanguages: ["ar", "de", "fr", "nl", "ja", "ko", "pt", "es", "zh-CHS"], completionHandler: { (userMessage, error) in
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(150), execute: {
                    if let preSendMessage = self.chattingView.preSendMessages[(userMessage?.requestId)!] as? SBDUserMessage {
                        self.chattingView.preSendMessages.removeValue(forKey: (userMessage?.requestId)!)
                        
                        if error != nil {
                            self.chattingView.resendableMessages[(userMessage?.requestId)!] = userMessage
                            self.chattingView.chattingTableView.reloadData()
                            DispatchQueue.main.async {
                                self.chattingView.scrollToBottom(force: true)
                            }
                            
                            return
                        }
                        
                        let index = IndexPath(row: self.chattingView.messages.index(of: preSendMessage)!, section: 0)
                        self.chattingView.chattingTableView.beginUpdates()
                        self.chattingView.messages[self.chattingView.messages.index(of: preSendMessage)!] = userMessage!
                        
                        UIView.setAnimationsEnabled(false)
                        self.chattingView.chattingTableView.reloadRows(at: [index] , with: UITableViewRowAnimation.none)
                        UIView.setAnimationsEnabled(true)
                        self.chattingView.chattingTableView.endUpdates()
                        
                        DispatchQueue.main.async {
                            self.chattingView.scrollToBottom(force: true)
                        }
                    }
                })
            })
            
            self.chattingView.preSendMessages[preSendMessage.requestId!] = preSendMessage
            DispatchQueue.main.async {
                if self.chattingView.preSendMessages[preSendMessage.requestId!] == nil {
                    return
                }
                
                self.chattingView.chattingTableView.beginUpdates()
                self.chattingView.messages.append(preSendMessage)
                
                UIView.setAnimationsEnabled(false)

                self.chattingView.chattingTableView.insertRows(at: [IndexPath(row: self.chattingView.messages.index(of: preSendMessage)!, section: 0)], with: UITableViewRowAnimation.none)
                UIView.setAnimationsEnabled(true)
                self.chattingView.chattingTableView.endUpdates()

                self.chattingView.chattingTableView.reloadData()
                
                DispatchQueue.main.async {
                    self.chattingView.scrollToBottom(force: true)
                    self.chattingView.sendButton.isEnabled = true
                }
            }
        }
    }
    
    // MARK: - UserActions
    //MARK: -
    
    func previewMessage(_ photo: ChatImage) {
        self.photosViewController = NYTPhotosViewController(photos: [photo])
        DispatchQueue.main.async {
            self.photosViewController.rightBarButtonItems = nil
            self.photosViewController.rightBarButtonItem = nil
            
            let negativeLeftSpacerForImageViewerLoading = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
            negativeLeftSpacerForImageViewerLoading.width = -2
            let leftCloseItemForImageViewerLoading = UIBarButtonItem(image: UIImage(named: "btn_close.png",in: self.podBundle, compatibleWith: nil),
                                                                     style: UIBarButtonItemStyle.done,
                                                                     target: self,
                                                                     action: #selector(self.closeImageViewer))
            
            self.imageViewerLoadingViewNavItem.leftBarButtonItems = [negativeLeftSpacerForImageViewerLoading, leftCloseItemForImageViewerLoading]
            self.present(self.photosViewController, animated: true, completion: {
                self.hideImageViewerLoading()
            })
        }
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            view.endEditing(true)
        }
        //sender.cancelsTouchesInView = false
    }
    func openPicker() {
        let mediaUI = UIImagePickerController()
        mediaUI.sourceType = UIImagePickerControllerSourceType.photoLibrary
        let mediaTypes = [String(kUTTypeImage)]
        mediaUI.mediaTypes = mediaTypes
        mediaUI.delegate = self
        self.present(mediaUI, animated: true, completion: nil)
    }
    
    @objc private func openAttachmentActionSheet() {
        // Dismiss Keyboard if present first
        self.chattingView.endEditing(true)
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(cameraAction())
        alertController.addAction(photosAction())
        alertController.addAction(locationAction())
        alertController.addAction(cancelAction())
        
        if self.themeObject != nil {
            alertController.view.tintColor = self.themeObject?.primaryActionIconsColor
        }
        else {
            alertController.view.tintColor = UIColor(red: 82.0/255.0, green: 67.0/255.0, blue: 62.0/255.0, alpha: 1.0)
        }
        present(alertController, animated: true) {
            if self.themeObject != nil {
                alertController.view.tintColor = self.themeObject?.primaryActionIconsColor
            }
            else {
                alertController.view.tintColor = UIColor(red: 82.0/255.0, green: 67.0/255.0, blue: 62.0/255.0, alpha: 1.0)
            }
        }
        //self.vwActionSheet.isHidden = false
        setVwActionSheet(hidden: false)
    }
    
    private func cameraAction() -> UIAlertAction {
        let action = UIAlertAction(
            title: "ms_camera".localized,
            style: .default,
            handler: { action in
                //self.vwActionSheet.isHidden = true
                self.setVwActionSheet(hidden: true)
                self.launchCamera()
        })
        action.setValue(UIImage(named: "camera-icon.png", in: Bundle.bundleForXib(GroupChannelChattingViewController.self), compatibleWith: nil), forKey: "image")
        return action
    }
    
    @objc private func launchCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            UIImagePickerController.checkPermissionStatus(sourceType: UIImagePickerControllerSourceType.camera, completionBlockSuccess: { (status) in
                let imagePicker = UIImagePickerController()
                
                imagePicker.sourceType = .camera
                imagePicker.mediaTypes = [String(kUTTypeImage)]
                imagePicker.delegate = self
                self.present(imagePicker, animated: true, completion: nil)
            }, andFailureBlock: { (status) in
                assert(false, "camera_permission_disable".localized)
            })
        }
    }
    
    private func photosAction() -> UIAlertAction {
        let action = UIAlertAction(
            title: "ms_photos".localized,
            style: .default,
            handler: { action in
                //self.vwActionSheet.isHidden = true
                self.setVwActionSheet(hidden: true)
                UIImagePickerController.checkPermissionStatus(sourceType: UIImagePickerControllerSourceType.photoLibrary, completionBlockSuccess: { (status) in
                    let imagePicker = UIImagePickerController()                    
                    imagePicker.sourceType = .photoLibrary
                    imagePicker.mediaTypes = [String(kUTTypeImage)]
                    imagePicker.delegate = self
                    self.present(imagePicker, animated: true, completion: nil)
                }, andFailureBlock: { (status) in
                    assert(false, "photos_permission_disable".localized)
                })
                
                
        })
        action.setValue(UIImage(named: "photos-icon.png", in: Bundle.bundleForXib(GroupChannelChattingViewController.self), compatibleWith: nil), forKey: "image")
        return action
    }
    
    private func locationAction() -> UIAlertAction {
        let action = UIAlertAction(
            title: "ms_location".localized,
            style: .default,
            handler: { action in
                //self.vwActionSheet.isHidden = true
                self.setVwActionSheet(hidden: true)
                let podBundle = Bundle.bundleForXib(GroupChannelChattingViewController.self)
                let locationPickerVC = SelectLocationViewController(nibName: "SelectLocationView", bundle: podBundle)
                locationPickerVC.delegate = self as SelectLocationDelegate
                self.present(locationPickerVC, animated: true, completion: nil)
        })
        action.setValue(UIImage(named: "location-icon.png", in: Bundle.bundleForXib(GroupChannelChattingViewController.self), compatibleWith: nil), forKey: "image")
        return action
    }
    
    private func cancelAction() -> UIAlertAction {
        return UIAlertAction(
            title: "cancel".localized,
            style: .cancel,
            handler : {action in
                //self.vwActionSheet.isHidden = true
                self.setVwActionSheet(hidden: true)
        })
    }
    
    @objc private func sendFileMessage() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            openPicker()
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    DispatchQueue.main.async {
                        self.openPicker()
                    }
                    break
                case .denied, .restricted:
                    DispatchQueue.main.async {
                        let vc = UIAlertController(title: "error".localized, message: "Authorization to assets is denied.", preferredStyle: UIAlertControllerStyle.alert)
                        let closeAction = UIAlertAction(title: "close".localized, style: UIAlertActionStyle.cancel, handler: nil)
                        vc.addAction(closeAction)
                        self.present(vc, animated: true, completion: nil)
                    }
                    break
                case .notDetermined: break
                }
            }
        }
    }
    
    @objc func clickReconnect() {
        if SBDMain.getConnectState() != SBDWebSocketConnectionState.open && SBDMain.getConnectState() != SBDWebSocketConnectionState.connecting {
            SBDMain.reconnect()
        }
    }
    
    // MARK: - Connection manager delegate
    //MARK: -
    func didConnect(isReconnection: Bool) {
        self.loadPreviousMessage(initial: true)
        
        self.groupChannel.refresh { (error) in
            if error == nil {
                //                    if self.navItem.titleView is UILabel, let label: UILabel = self.navItem.titleView as? UILabel {
                //                        let title: String = (NSString.init(format: "Group Channel (%ld)", self.groupChannel.memberCount)) as String
                //                        let subtitle: String? = "reconnect".localized as String?
                //                        DispatchQueue.main.async {
                //                            label.attributedText = Utils.generateNavigationTitle(mainTitle: title, subTitle: subtitle, titleColor: self.themeObject?.primaryAccentColor, subTitleColor: self.themeObject?.primaryActionIconsColor)
                //
                //                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
                //                                label.attributedText = Utils.generateNavigationTitle(mainTitle: title, subTitle: subtitle, titleColor: self.themeObject?.primaryAccentColor, subTitleColor: self.themeObject?.primaryActionIconsColor)
                //                            }
                //                        }
                //                    }
            }
        }
    }
    
    func didDisconnect() {
        print("disconnected")
        //            if self.navItem.titleView is UILabel, let label: UILabel = self.navItem.titleView as? UILabel {
        //                let title: String = NSString.init(format: "Group Channel (%ld)" as NSString, self.groupChannel.memberCount) as String
        //                var subtitle: String? = "reconnection_failed".localized as String?
        //
        //                DispatchQueue.main.async {
        //                    label.attributedText = Utils.generateNavigationTitle(mainTitle: title, subTitle: subtitle, titleColor: self.themeObject?.primaryAccentColor, subTitleColor: self.themeObject?.primaryActionIconsColor)
        //                }
        //
        //                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
        //                    subtitle = "reconnect".localized
        //                    label.attributedText = Utils.generateNavigationTitle(mainTitle: title, subTitle: subtitle, titleColor: self.themeObject?.primaryAccentColor, subTitleColor: self.themeObject?.primaryActionIconsColor)
        //                }
        //            }
    }
    
    // MARK: - SBDChannelDelegate
    //MARK: -
    func channel(_ sender: SBDBaseChannel, didReceive message: SBDBaseMessage) {
        if sender == self.groupChannel {
            self.groupChannel.markAsRead()
            DispatchQueue.main.async {
                UIView.setAnimationsEnabled(false)
                self.chattingView.messages.append(message)
                self.chattingView.chattingTableView.reloadData()
                UIView.setAnimationsEnabled(true)
                DispatchQueue.main.async {
                    self.chattingView.scrollToBottom(force: true)
                }
            }
        }
        else {
            if message is SBDUserMessage {
                _ = (message as! SBDUserMessage).message
                let senderName = (message as! SBDUserMessage).sender?.nickname
                let strMessageLoc = "message_center_new_message_from".localized
                self.view.makeToast(strMessageLoc + senderName!)
            }
            else if message is SBDFileMessage {
                let senderName = (message as! SBDFileMessage).sender?.nickname
                self.view.makeToast("message_center_new_message_from".localized + senderName!)
            }
            else if message is SBDAdminMessage {
                self.view.makeToast("message_center_new_message_from".localized + "Admin")
            }
            else {
                self.view.makeToast("message_center_new_message_from".localized + "")
            }
        }
    }
    
    func channelDidUpdateReadReceipt(_ sender: SBDGroupChannel) {
        if sender == self.groupChannel {
            DispatchQueue.main.async {
                self.chattingView.chattingTableView.reloadData()
            }
        }
    }
    
    func channelDidUpdateTypingStatus(_ sender: SBDGroupChannel) {
        if sender == self.groupChannel {
            if sender.getTypingMembers()?.count == 0 {
                self.chattingView.endTypingIndicator()
            }
            else {
                if sender.getTypingMembers()?.count == 1 {
                    self.chattingView.startTypingIndicator(text: String(format: "%@ %@", (sender.getTypingMembers()?[0].nickname)!, "is_typing".localized))
                }
                else {
                    self.chattingView.startTypingIndicator(text: "multiple_users_are_typing".localized)
                }
            }
        }
    }
    
    func channel(_ sender: SBDGroupChannel, userDidJoin user: SBDUser) {
        //            if self.navItem.titleView != nil && self.navItem.titleView is UILabel {
        //                DispatchQueue.main.async {
        //                    (self.navItem.titleView as! UILabel).attributedText = Utils.generateNavigationTitle(mainTitle: (self.themeObject?.title)!, subTitle: (self.themeObject?.subtitle)!, titleColor: self.themeObject?.primaryAccentColor, subTitleColor: self.themeObject?.primaryActionIconsColor)
        //                }
        //            }
    }
    
    func channel(_ sender: SBDGroupChannel, userDidLeave user: SBDUser) {
        //            if self.navItem.titleView != nil && self.navItem.titleView is UILabel {
        //                DispatchQueue.main.async {
        //                    (self.navItem.titleView as! UILabel).attributedText = Utils.generateNavigationTitle(mainTitle: (self.themeObject?.title)!, subTitle: (self.themeObject?.subtitle)!, titleColor: self.themeObject?.primaryAccentColor, subTitleColor: self.themeObject?.primaryActionIconsColor)
        //                }
        //            }
    }
    
    func channel(_ sender: SBDOpenChannel, userDidEnter user: SBDUser) {
        
    }
    
    func channel(_ sender: SBDOpenChannel, userDidExit user: SBDUser) {
        
    }
    
    func channel(_ sender: SBDBaseChannel, userWasMuted user: SBDUser) {
        
    }
    
    func channel(_ sender: SBDBaseChannel, userWasUnmuted user: SBDUser) {
        
    }
    
    func channel(_ sender: SBDBaseChannel, userWasBanned user: SBDUser) {
        
    }
    
    func channel(_ sender: SBDBaseChannel, userWasUnbanned user: SBDUser) {
        
    }
    
    func channelWasFrozen(_ sender: SBDBaseChannel) {
        
    }
    
    func channelWasUnfrozen(_ sender: SBDBaseChannel) {
        
    }
    
    func channelWasChanged(_ sender: SBDBaseChannel) {
        //            if sender == self.groupChannel {
        //                DispatchQueue.main.async {
        //                    self.navItem.title = String(format: "Group Channel (%ld)", self.groupChannel.memberCount)
        //                }
        //            }
    }
    
    func channelWasDeleted(_ channelUrl: String, channelType: SBDChannelType) {
        let vc = UIAlertController(title: "Channel has been deleted.", message: "This channel has been deleted. It will be closed.", preferredStyle: UIAlertControllerStyle.alert)
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel) { (action) in
            self.close()
        }
        vc.addAction(closeAction)
        DispatchQueue.main.async {
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func channel(_ sender: SBDBaseChannel, messageWasDeleted messageId: Int64) {
        if sender == self.groupChannel {
            for message in self.chattingView.messages {
                if message.messageId == messageId {
                    self.chattingView.messages.remove(at: self.chattingView.messages.index(of: message)!)
                    DispatchQueue.main.async {
                        self.chattingView.chattingTableView.reloadData()
                    }
                    break
                }
            }
        }
    }
    
    // MARK: - ChattingViewDelegate
    //MARK: -
    func loadMoreMessage(view: UIView) {
        if self.cachedMessage {
            return
        }
        
        self.loadPreviousMessage(initial: false)
    }
    
    func startTyping(view: UIView) {
        self.groupChannel.startTyping()
        self.chattingView.scrollToBottom(force: true)
    }
    
    func endTyping(view: UIView) {
        self.groupChannel.endTyping()
        self.chattingView.scrollToBottom(force: true)
    }
    
    func hideKeyboardWhenFastScrolling(view: UIView) {
        if self.keyboardShown == false {
            return
        }
        
        DispatchQueue.main.async {
            self.bottomMargin.constant = 0
            self.view.layoutIfNeeded()
            self.chattingView.scrollToBottom(force: true)
        }
        self.view.endEditing(true)
    }
    
    // MARK: - MessageDelegate
    //MARK: -
    func clickProfileImage(viewCell: UITableViewCell, user: SBDUser) {
        let vc = UIAlertController(title: user.nickname, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        let seeBlockUserAction = UIAlertAction(title: "Block the user", style: UIAlertActionStyle.default) { (action) in
            SBDMain.blockUser(user, completionHandler: { (blockedUser, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        let vc = UIAlertController(title: "Error", message: error?.domain, preferredStyle: UIAlertControllerStyle.alert)
                        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil)
                        vc.addAction(closeAction)
                        DispatchQueue.main.async {
                            self.present(vc, animated: true, completion: nil)
                        }
                    }
                    
                    return
                }
                
                DispatchQueue.main.async {
                    let vc = UIAlertController(title: "User blocked", message: String(format: "%@ is blocked.", user.nickname!), preferredStyle: UIAlertControllerStyle.alert)
                    let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil)
                    vc.addAction(closeAction)
                    DispatchQueue.main.async {
                        self.present(vc, animated: true, completion: nil)
                    }
                }
            })
        }
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil)
        vc.addAction(seeBlockUserAction)
        vc.addAction(closeAction)
        
        DispatchQueue.main.async {
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func clickMessage(view: UIView, message: SBDBaseMessage) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil)
        var deleteMessageAction: UIAlertAction?
        var openURLsAction: [UIAlertAction] = []
        
        if message is SBDUserMessage {
            let userMessage = message as! SBDUserMessage
            if userMessage.customType != nil && userMessage.customType == "url_preview" {
                let data: Data = (userMessage.data?.data(using: String.Encoding.utf8)!)!
                do {
                    let previewData = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.init(rawValue: 0))
                    let url = URL(string: ((previewData as! Dictionary<String, Any>)["url"] as! String))
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(url!)
                    }
                }
                catch {
                    
                }
                
            }
            else {
                let sender = (message as! SBDUserMessage).sender
                if sender?.userId == SBDMain.getCurrentUser()?.userId {
                    deleteMessageAction = UIAlertAction(title: "Delete the message", style: UIAlertActionStyle.destructive, handler: { (action) in
                        self.groupChannel.delete(message, completionHandler: { (error) in
                            if error != nil {
                                let alert = UIAlertController(title: "Error", message: error?.domain, preferredStyle: UIAlertControllerStyle.alert)
                                let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil)
                                alert.addAction(closeAction)
                                DispatchQueue.main.async {
                                    self.present(alert, animated: true, completion: nil)
                                }
                            }
                        })
                    })
                }
                
                do {
                    let detector: NSDataDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                    let matches = detector.matches(in: (message as! SBDUserMessage).message!, options: [], range: NSMakeRange(0, ((message as! SBDUserMessage).message?.count)!))
                    for match in matches as [NSTextCheckingResult] {
                        let url: URL = match.url!
                        let openURLAction = UIAlertAction(title: url.relativeString, style: UIAlertActionStyle.default, handler: { (action) in
                            if #available(iOS 10.0, *) {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            } else {
                                UIApplication.shared.openURL(url)
                            }
                        })
                        openURLsAction.append(openURLAction)
                    }
                }
                catch {
                    
                }
            }
            
        }
        else if message is SBDFileMessage {
            let fileMessage: SBDFileMessage = message as! SBDFileMessage
            let sender = fileMessage.sender
            let type = fileMessage.type
            let url = fileMessage.url
            
            if sender?.userId == SBDMain.getCurrentUser()?.userId {
                deleteMessageAction = UIAlertAction(title: "delete_message".localized, style: UIAlertActionStyle.destructive, handler: { (action) in
                    self.groupChannel.delete(fileMessage, completionHandler: { (error) in
                        if error != nil {
                            let alert = UIAlertController(title: "error".localized, message: error?.domain, preferredStyle: UIAlertControllerStyle.alert)
                            let closeAction = UIAlertAction(title: "close".localized, style: UIAlertActionStyle.cancel, handler: nil)
                            alert.addAction(closeAction)
                            DispatchQueue.main.async {
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    })
                })
            }
            
            if type.hasPrefix("video") {
                let videoUrl = NSURL(string: url)
                let player = AVPlayer(url: videoUrl! as URL)
                let vc = AVPlayerViewController()
                vc.player = player
                self.present(vc, animated: true, completion: {
                    player.play()
                })
                
                return
            }
            else if type.hasPrefix("audio") {
                let audioUrl = NSURL(string: url)
                let player = AVPlayer(url: audioUrl! as URL)
                let vc = AVPlayerViewController()
                vc.player = player
                self.present(vc, animated: true, completion: {
                    player.play()
                })
                
                return
            }
            else if type.hasPrefix("image") {
                let photo = ChatImage()
                if url.count > 0 {
                    self.showImageViewerLoading()
                    if  let cachedData = FLAnimatedImageView.cachedImageForURL(url: URL(string: url)!) {
                        photo.imageData = cachedData
                        self.previewMessage(photo)
                    }
                        
                    else {
                        let session = URLSession.shared
                        let request = URLRequest(url: URL(string: url)!)
                        session.dataTask(with: request, completionHandler: { (data, response, error) in
                            if error != nil {
                                self.hideImageViewerLoading()
                                
                                return;
                            }
                            
                            let resp = response as! HTTPURLResponse
                            if resp.statusCode >= 200 && resp.statusCode < 300 {
                                //                            AppDelegate.imageCache().setObject(data as AnyObject, forKey: url as AnyObject)
                                let photo = ChatImage()
                                photo.imageData = data
                                self.previewMessage(photo)
                            }
                            else {
                                self.hideImageViewerLoading()
                            }
                        }).resume()
                        return
                    }
                }
                else {
                    if let image = self.getImageFromDocumentDirectory(fileMessage.requestId!) {
                        photo.image = image
                        photo.imageData = UIImageJPEGRepresentation(image, 1.0)
                        self.previewMessage(photo)
                    }
                    return
                }
            }
            else {
                // TODO: Download file. Is this possible on iOS?
            }
        }
        else if message is SBDAdminMessage {
            return
        }
        
        alert.addAction(closeAction)
        
        if openURLsAction.count > 0 {
            for action in openURLsAction {
                alert.addAction(action)
            }
        }
        
        if deleteMessageAction != nil {
            alert.addAction(deleteMessageAction!)
        }
        
        if openURLsAction.count > 0 || deleteMessageAction != nil {
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func clickResend(view: UIView, message: SBDBaseMessage) {
        let vc = UIAlertController(title: "resend_message".localized, message: "resend_message_description".localized, preferredStyle: UIAlertControllerStyle.alert)
        let closeAction = UIAlertAction(title: "close".localized, style: UIAlertActionStyle.cancel, handler: nil)
        let resendAction = UIAlertAction(title: "resend_message".localized, style: UIAlertActionStyle.default) { (action) in
            if message is SBDUserMessage {
                let resendableUserMessage = message as! SBDUserMessage
                var targetLanguages:[String] = []
                if resendableUserMessage.translations != nil {
                    targetLanguages = Array(resendableUserMessage.translations!.keys) as! [String]
                }
                
                do {
                    let detector: NSDataDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                    let matches = detector.matches(in: resendableUserMessage.message!, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, (resendableUserMessage.message!.count)))
                    var url: URL? = nil
                    for item in matches {
                        let match = item as NSTextCheckingResult
                        url = match.url
                        break
                    }
                    
                    if url != nil {
                        let tempModel = OutgoingGeneralUrlPreviewTempModel()
                        tempModel.createdAt = Int64(NSDate().timeIntervalSince1970 * 1000)
                        tempModel.message = resendableUserMessage.message!
                        
                        self.chattingView.messages[self.chattingView.messages.index(of: resendableUserMessage)!] = tempModel
                        self.chattingView.resendableMessages.removeValue(forKey: resendableUserMessage.requestId!)
                        
                        DispatchQueue.main.async {
                            self.chattingView.chattingTableView.reloadData()
                            DispatchQueue.main.async {
                                self.chattingView.scrollToBottom(force: true)
                            }
                        }
                        
                        // Send preview
                        self.sendUrlPreview(url: url!, message: resendableUserMessage.message!, aTempModel: tempModel)
                    }
                }
                catch {
                    
                }
                
                let preSendMessage = self.groupChannel.sendUserMessage(resendableUserMessage.message, data: resendableUserMessage.data, customType: resendableUserMessage.customType, targetLanguages: targetLanguages, completionHandler: { (userMessage, error) in
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(150), execute: {
                        DispatchQueue.main.async {
                            let preSendMessage = self.chattingView.preSendMessages[(userMessage?.requestId)!]
                            self.chattingView.preSendMessages.removeValue(forKey: (userMessage?.requestId)!)
                            
                            if error != nil {
                                self.chattingView.resendableMessages[(userMessage?.requestId)!] = userMessage
                                self.chattingView.chattingTableView.reloadData()
                                DispatchQueue.main.async {
                                    self.chattingView.scrollToBottom(force: true)
                                }
                                
                                let alert = UIAlertController(title: "error".localized, message: error?.domain, preferredStyle: UIAlertControllerStyle.alert)
                                let closeAction = UIAlertAction(title: "close".localized, style: UIAlertActionStyle.cancel, handler: nil)
                                alert.addAction(closeAction)
                                DispatchQueue.main.async {
                                    self.present(alert, animated: true, completion: nil)
                                }
                                
                                return
                            }
                            
                            if preSendMessage != nil {
                                self.chattingView.messages.remove(at: self.chattingView.messages.index(of: (preSendMessage! as SBDBaseMessage))!)
                                self.chattingView.messages.append(userMessage!)
                            }
                            
                            self.chattingView.chattingTableView.reloadData()
                            DispatchQueue.main.async {
                                self.chattingView.scrollToBottom(force: true)
                            }
                        }
                    })
                })
                self.chattingView.messages[self.chattingView.messages.index(of: resendableUserMessage)!] = preSendMessage
                self.chattingView.preSendMessages[preSendMessage.requestId!] = preSendMessage
                self.chattingView.resendableMessages.removeValue(forKey: resendableUserMessage.requestId!)
                self.chattingView.chattingTableView.reloadData()
                DispatchQueue.main.async {
                    self.chattingView.scrollToBottom(force: true)
                }
            }
            else if message is SBDFileMessage {
                let resendableFileMessage = message as! SBDFileMessage
                
                var thumbnailSizes: [SBDThumbnailSize] = []
                for thumbnail in resendableFileMessage.thumbnails! as [SBDThumbnail] {
                    thumbnailSizes.append(SBDThumbnailSize.make(withMaxCGSize: thumbnail.maxSize)!)
                }
                let preSendMessage = self.groupChannel.sendFileMessage(withBinaryData: self.chattingView.preSendFileData[resendableFileMessage.requestId!]?["data"] as! Data, filename: resendableFileMessage.name, type: resendableFileMessage.type, size: resendableFileMessage.size, thumbnailSizes: thumbnailSizes, data: resendableFileMessage.data, customType: resendableFileMessage.customType, progressHandler: nil, completionHandler: { (fileMessage, error) in
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(150), execute: {
                        let preSendMessage = self.chattingView.preSendMessages[(fileMessage?.requestId)!]
                        self.chattingView.preSendMessages.removeValue(forKey: (fileMessage?.requestId)!)
                        
                        if error != nil {
                            self.chattingView.resendableMessages[(fileMessage?.requestId)!] = fileMessage
                            self.chattingView.resendableFileData[(fileMessage?.requestId)!] = self.chattingView.resendableFileData[resendableFileMessage.requestId!]
                            self.chattingView.resendableFileData.removeValue(forKey: resendableFileMessage.requestId!)
                            self.chattingView.chattingTableView.reloadData()
                            DispatchQueue.main.async {
                                self.chattingView.scrollToBottom(force: true)
                            }
                            
                            let alert = UIAlertController(title: "error".localized, message: error?.domain, preferredStyle: UIAlertControllerStyle.alert)
                            let closeAction = UIAlertAction(title: "close".localized, style: UIAlertActionStyle.cancel, handler: nil)
                            alert.addAction(closeAction)
                            DispatchQueue.main.async {
                                self.present(alert, animated: true, completion: nil)
                            }
                            
                            return
                        }
                        
                        if preSendMessage != nil {
                            self.chattingView.messages.remove(at: self.chattingView.messages.index(of: (preSendMessage! as SBDBaseMessage))!)
                            self.chattingView.messages.append(fileMessage!)
                        }
                        
                        self.chattingView.chattingTableView.reloadData()
                        DispatchQueue.main.async {
                            self.chattingView.scrollToBottom(force: true)
                        }
                    })
                })
                
                self.chattingView.messages[self.chattingView.messages.index(of: resendableFileMessage)!] = preSendMessage
                self.chattingView.preSendMessages[preSendMessage.requestId!] = preSendMessage
                self.chattingView.preSendFileData[preSendMessage.requestId!] = self.chattingView.resendableFileData[resendableFileMessage.requestId!]
                self.chattingView.resendableMessages.removeValue(forKey: resendableFileMessage.requestId!)
                self.chattingView.resendableFileData.removeValue(forKey: resendableFileMessage.requestId!)
                self.chattingView.chattingTableView.reloadData()
                DispatchQueue.main.async {
                    self.chattingView.scrollToBottom(force: true)
                }
            }
        }
        
        vc.addAction(closeAction)
        vc.addAction(resendAction)
        DispatchQueue.main.async {
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func clickDelete(view: UIView, message: SBDBaseMessage) {
        let vc = UIAlertController(title: "delete_message".localized, message: "Do you want to delete the message?", preferredStyle: UIAlertControllerStyle.alert)
        let closeAction = UIAlertAction(title: "close".localized, style: UIAlertActionStyle.cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "delete_message".localized, style: UIAlertActionStyle.destructive) { (action) in
            var requestId: String?
            if message is SBDUserMessage {
                requestId = (message as! SBDUserMessage).requestId
            }
            else if message is SBDFileMessage {
                requestId = (message as! SBDFileMessage).requestId
            }
            self.chattingView.resendableFileData.removeValue(forKey: requestId!)
            self.chattingView.resendableMessages.removeValue(forKey: requestId!)
            self.chattingView.messages.remove(at: self.chattingView.messages.index(of: message)!)
            DispatchQueue.main.async {
                self.chattingView.chattingTableView.reloadData()
            }
        }
        
        vc.addAction(closeAction)
        vc.addAction(deleteAction)
        DispatchQueue.main.async {
            self.present(vc, animated: true, completion: nil)
        }
    }
       
    func showImageViewerLoading() {
        DispatchQueue.main.async {
            self.imageViewerLoadingView.isHidden = false
            self.imageViewerLoadingIndicator.isHidden = false
            self.imageViewerLoadingIndicator.startAnimating()
        }
    }
    
    func hideImageViewerLoading() {
        DispatchQueue.main.async {
            self.imageViewerLoadingView.isHidden = true
            self.imageViewerLoadingIndicator.isHidden = true
            self.imageViewerLoadingIndicator.stopAnimating()
        }
    }
    
    @objc func closeImageViewer() {
        if self.photosViewController != nil {
            self.photosViewController.dismiss(animated: true, completion: nil)
        }
    }

    // Disclaimer: I have no idea what vw stands for, but for the sake of convention, I'm naming my method accordingly.
    private func setVwActionSheet(hidden: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                self.vwActionSheet.alpha = hidden ? 0.0 : 0.75
            })
        }
    }
}

// MARK: - UIImagePickerController Methods
//MARK: -
extension GroupChannelChattingViewController: UIImagePickerControllerDelegate {
   @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print(error)
        } else {
            fetchLastImage()
        }
    }
    
    func fetchLastImage()
    {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        if (fetchResult.firstObject != nil){
            let lastImageAsset: PHAsset = fetchResult.firstObject as! PHAsset
            sendImageProcess(assest: lastImageAsset)
        }
    }
    func sendImageProcess (assest: PHAsset){
        let asset = assest
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = false
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        if asset != nil {
            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.default, options: nil, resultHandler: { (result, info) in
                if (result != nil) {
                    // Call the Caption ViewController
                    let imageCaptionVC = ImagePreviewViewController(nibName: "ImagePreviewViewController", bundle: self.podBundle)
                    imageCaptionVC.imageToUpload = result
                    // If user has typed any text, use it as caption
                    if self.chattingView.messageTextView.textView.text != nil {
                        imageCaptionVC.strCaption = self.chattingView.messageTextView.textView.text
                    }
                    imageCaptionVC.delegate = self
                    self.navigationController?.pushViewController(imageCaptionVC, animated: true)                                                            }
            })
        }
    }
  
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        
        picker.dismiss(animated: true) {
            if CFStringCompare(mediaType as CFString, kUTTypeImage, []) == CFComparisonResult.compareEqualTo {
                self.mediaInfo = [String : Any] ()
                self.mediaInfo = info
                
                // Delegate didFinishPickingMediaWithInfo gets called after a pic is taken using the camera.
                // UIImagePickerControllerReferenceURL object will be nil as the image has not been saved to the camera roll yet.
                guard let path =  self.mediaInfo![UIImagePickerControllerReferenceURL]  else {
                    // image from camera
                    if (picker.sourceType == UIImagePickerControllerSourceType.camera) {
                        var selectedImage: UIImage!
                        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
                            selectedImage = image
                        } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                            selectedImage = image
                        }
                        // save image
                        UIImageWriteToSavedPhotosAlbum(selectedImage, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                    }
                    return
                }
                
                // image from photo library
                if  let imagePath: URL = self.mediaInfo![UIImagePickerControllerReferenceURL] as! URL {
                    let imageName: NSString = (imagePath.lastPathComponent as NSString?)!
                    let ext = imageName.pathExtension
                    let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)?.takeRetainedValue()
                    let mimeType = UTTypeCopyPreferredTagWithClass(UTI!, kUTTagClassMIMEType)?.takeRetainedValue();
                    let asset = PHAsset.fetchAssets(withALAssetURLs: [imagePath], options: nil).lastObject
                    let options = PHImageRequestOptions()
                    options.isSynchronous = true
                    options.isNetworkAccessAllowed = false
                    options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
                    if asset != nil {
                        PHImageManager.default().requestImage(for: asset!, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.default, options: nil, resultHandler: { (result, info) in
                            if (result != nil) {
                                
                                // Call the Caption ViewController
                                let imageCaptionVC = ImagePreviewViewController(nibName: "ImagePreviewViewController", bundle: self.podBundle)
                                imageCaptionVC.imageToUpload = result
                                // If user has typed any text, use it as caption
                                if self.chattingView.messageTextView.textView.text != nil {
                                    imageCaptionVC.strCaption = self.chattingView.messageTextView.textView.text
                                }
                                
                                imageCaptionVC.delegate = self
                                self.navigationController?.pushViewController(imageCaptionVC, animated: true)                                                            }
                        })
                    }
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Observer Methods
//MARK: -
fileprivate extension GroupChannelChattingViewController {
    
    @objc private func keyboardWillShow(notification: Notification) {
        self.keyboardShown = true
        
        let keyboardInfo = notification.userInfo
        let keyboardFrameBegin = keyboardInfo?[UIKeyboardFrameEndUserInfoKey]
        let keyboardFrameBeginRect = (keyboardFrameBegin as! NSValue).cgRectValue
        let duration = keyboardInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
        let curve = keyboardInfo?[UIKeyboardAnimationCurveUserInfoKey] as! UInt
        DispatchQueue.main.async {
            self.bottomMargin.constant = keyboardFrameBeginRect.size.height
            UIView.animate(withDuration: duration.doubleValue, delay: 0.0, options: [UIViewAnimationOptions(rawValue: UInt(curve))]
                , animations: {
                    self.view.layoutIfNeeded()
            }, completion: { (status) in
                self.chattingView.stopMeasuringVelocity = true
                self.chattingView.scrollToBottom(force: true)
            })
        }
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        self.keyboardShown = false
        let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
        let curve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! UInt
        DispatchQueue.main.async {
            self.bottomMargin.constant = 0
            UIView.animate(withDuration: duration.doubleValue, delay: 0.0, options: [UIViewAnimationOptions(rawValue: UInt(curve))]
                , animations: {
                    self.view.layoutIfNeeded()
            }, completion: { (status) in
                self.chattingView.scrollToBottom(force: true)
//                self.chattingView.chattingTableView.contentInset = UIEdgeInsetsMake(0, 0, 0.0, 0)
            })
            
        }
    }
    
    @objc private func applicationWillTerminate(notification: Notification) {
        Utils.dumpMessages(
            messages: self.chattingView.messages,
            resendableMessages: self.chattingView.resendableMessages,
            resendableFileData: self.chattingView.resendableFileData,
            preSendMessages: self.chattingView.preSendMessages,
            channelUrl: self.groupChannel.channelUrl
        )
    }
    
}


// MARK: - Private Utility Methods

fileprivate extension GroupChannelChattingViewController {
    
    func createTitle(title: String, subTitle: String) {
    }
    
    func setNavigationItems() {
        
        self.lblTitle.text = self.themeObject != nil ? self.themeObject?.title : ""
        self.lblSubTitle.text = self.themeObject != nil ? self.themeObject?.subtitle : ""
        
        if self.themeObject != nil {
            self.lblTitle.textColor = self.themeObject?.primaryAccentColor
            self.lblSubTitle.textColor = self.themeObject?.primaryActionIconsColor
            let backImg = UIImage(named: "back.png", in: self.podBundle, compatibleWith: nil)
            self.btnBack.setImage(backImg?.withRenderingMode(UIImageRenderingMode.alwaysTemplate), for: .normal)
            self.btnBack.tintColor = self.themeObject?.primaryNavigationButtonColor
            
        }
        
        if UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute) == .rightToLeft {
            btnBack.transform = btnBack.transform.rotated(by: CGFloat(Double.pi))
            if let sendBtnImage = self.chattingView.sendButton.imageView {
                sendBtnImage.transform = sendBtnImage.transform.rotated(by: CGFloat(Double.pi))
            }
            
        }
        self.btnBack.addTarget(self, action: #selector(close), for: .touchUpInside)
        
    }
    
    func addObservers() {
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(notification:)), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
    }
}


extension GroupChannelChattingViewController : SelectLocationDelegate {
    func userDidSelect(location uri: String?) {
        // Check if we have lat, longs returned. Else dismiss the view and return.
        if uri == nil || uri == "" {
            self.userDidDismiss()
            return
        }
        self.imageCaption = uri!
        self.sendMessage()
        self.dismiss(animated: true, completion: nil)
    }

    func userDidDismiss() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension GroupChannelChattingViewController : ImagePreviewProtocol {

    func imagePreviewDidDismiss(_ image: UIImage?, caption: String) {
        if self.mediaInfo != nil && image != nil {
            self.imageCaption = caption
            // Delegate didFinishPickingMediaWithInfo gets called after a pic is taken using the camera.
            // UIImagePickerControllerReferenceURL object will be nil as the image has not been saved to the camera roll yet.
            var imageName: NSString = ""
            if  self.mediaInfo![UIImagePickerControllerReferenceURL]  == nil {
                imageName = "camera.JPEG"
            }else{
                let imagePath: URL = self.mediaInfo![UIImagePickerControllerReferenceURL] as! URL
                 imageName = (imagePath.lastPathComponent as NSString?)!
            }

            let ext = imageName.pathExtension
            let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)?.takeRetainedValue()
            let mimeType = UTTypeCopyPreferredTagWithClass(UTI!, kUTTagClassMIMEType)?.takeRetainedValue();
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.isNetworkAccessAllowed = false
            options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
            
            if image != nil {
                let imageData = UIImageJPEGRepresentation(image!, 1.0)
                let thumbnailSize = SBDThumbnailSize.make(withMaxWidth: 320.0, maxHeight: 320.0)
                
                let preSendMessage = self.groupChannel.sendFileMessage(withBinaryData: imageData!, filename: imageName as String, type: mimeType! as String, size: UInt((imageData?.count)!), thumbnailSizes: [thumbnailSize!], data: "", customType: "", progressHandler: nil, completionHandler: { (fileMessage, error) in
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(150), execute: {
                        let preSendMessage = self.chattingView.preSendMessages[(fileMessage?.requestId)!] as! SBDFileMessage
                        
                        self.chattingView.preSendMessages.removeValue(forKey: (fileMessage?.requestId)!)
                        self.mediaInfo = nil
                        if error != nil {
                            self.chattingView.resendableMessages[(fileMessage?.requestId)!] = preSendMessage
                            self.chattingView.resendableFileData[preSendMessage.requestId!]?["data"] = imageData as AnyObject?
                            self.chattingView.resendableFileData[preSendMessage.requestId!]?["type"] = mimeType as AnyObject?
                            self.chattingView.chattingTableView.reloadData()
                            DispatchQueue.main.async {
                                self.chattingView.scrollToBottom(force: true)
                            }
                            
                            return
                        }
                        
                        if fileMessage != nil {
                            if self.imageCaption.count > 0 {
                                self.sendMessage()
                            }
                            self.chattingView.resendableMessages.removeValue(forKey: (fileMessage?.requestId)!)
                            self.chattingView.resendableFileData.removeValue(forKey: (fileMessage?.requestId)!)
                            self.chattingView.preSendMessages.removeValue(forKey: (fileMessage?.requestId)!)
                            self.chattingView.messages[self.chattingView.messages.index(of: preSendMessage)!] = fileMessage!
                            
                            DispatchQueue.main.async {
                                self.chattingView.chattingTableView.reloadData()
                                DispatchQueue.main.async {
                                    self.chattingView.scrollToBottom(force: true)
                                }
                            }
                        }
                    })
                })
                
                
                self.saveImageDocumentDirectory(image: image!, imageName: preSendMessage.requestId!)
                
                self.chattingView.preSendFileData[preSendMessage.requestId!] = [
                    "data": imageData as AnyObject,
                    "type": mimeType as AnyObject,
                ]
                self.chattingView.preSendMessages[preSendMessage.requestId!] = preSendMessage
                self.chattingView.messages.append(preSendMessage)
                self.chattingView.chattingTableView.reloadData()
                DispatchQueue.main.async {
                    self.chattingView.scrollToBottom(force: true)
                }
            }
        }
    }
    
}

// To preview the image that is uploading, save it to Documents directory. Unless image is uploaded, URL is not generated and we can't download the image

private extension GroupChannelChattingViewController {
    
    func getDirectoryPath() -> NSURL {
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("MessageCenter")
        let url = NSURL(string: path)
        return url!
    }
    
    func saveImageDocumentDirectory(image: UIImage, imageName: String) {
        let fileManager = FileManager.default
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("MessageCenter")
        if !fileManager.fileExists(atPath: path) {
            try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        let url = NSURL(string: path)
        let imagePath = url!.appendingPathComponent(imageName)
        let urlString: String = imagePath!.absoluteString
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        //let imageData = UIImagePNGRepresentation(image)
        fileManager.createFile(atPath: urlString as String, contents: imageData, attributes: nil)
    }
    
    func getImageFromDocumentDirectory(_ name: String) -> UIImage? {
        let fileManager = FileManager.default
        let imagePath = (self.getDirectoryPath() as NSURL).appendingPathComponent(name)
        let urlString: String = imagePath!.absoluteString
        if fileManager.fileExists(atPath: urlString) {
            let image = UIImage(contentsOfFile: urlString)
            return image
        } else {
            return nil
        }
    }

    
    func deleteDirectory() {
        let fileManager = FileManager.default
        let directoryPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("MessageCenter")
        if fileManager.fileExists(atPath: directoryPath) {
            try! fileManager.removeItem(atPath: directoryPath)
        }
    }
}
