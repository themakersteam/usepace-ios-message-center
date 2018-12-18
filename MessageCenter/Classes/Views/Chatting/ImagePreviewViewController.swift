//
//  ImagePreviewViewController.swift
//  MessageCenter
//
//  Created by Ikarma Khan on 14/12/2018.
//

import UIKit

protocol ImagePreviewProtocol: class {
    func imagePreviewDidDismiss(_ image: UIImage? , caption: String)
}

class ImagePreviewViewController: UIViewController {

    @IBOutlet weak var imgPicture: UIImageView!
    @IBOutlet weak var txtCaption: UITextView!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var btnDismiss: UIButton!
    
    @IBOutlet weak var bottomMargin: NSLayoutConstraint!
    
    private var keyboardShown: Bool = false
    
    var strCaption: String = ""
    var imageToUpload : UIImage?
    
    var delegate: ImagePreviewProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnSend.layer.cornerRadius = 22.0
        self.imgPicture.image = imageToUpload!
        self.txtCaption.delegate = self
        self.txtCaption.text = strCaption
        self.txtCaption.textContainerInset = UIEdgeInsetsMake(15.5, 0, 14, 0)
        self.txtCaption.layer.cornerRadius = 8.0
        self.txtCaption.layer.borderColor = UIColor.black.cgColor
        self.txtCaption.layer.borderWidth = 1.0
        
        self.addObservers()
    }

    func addObservers() {
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
     
    }
    
    @objc private func keyboardDidShow(notification: Notification) {
        self.keyboardShown = true
        
        let keyboardInfo = notification.userInfo
        let keyboardFrameBegin = keyboardInfo?[UIKeyboardFrameEndUserInfoKey]
        let keyboardFrameBeginRect = (keyboardFrameBegin as! NSValue).cgRectValue
        
        DispatchQueue.main.async {
            
            self.bottomMargin.constant = keyboardFrameBeginRect.size.height
            
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear, animations: {
                self.view.layoutIfNeeded()
            }, completion: { (status) in
                
            })
//            self.chattingView.stopMeasuringVelocity = true
//            self.chattingView.scrollToBottom(force: false)
        }
    }
    
    @objc private func keyboardDidHide(notification: Notification) {
        self.keyboardShown = false
        
        DispatchQueue.main.async {
            self.bottomMargin.constant = 0
            
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear, animations: {
                self.view.layoutIfNeeded()
            }, completion: { (status) in
                
            })
            
            
//            self.chattingView.scrollToBottom(force: false)
        }
    }
    
    
    @IBAction func btnDismissTapped(_ sender: Any) {
        txtCaption.resignFirstResponder()
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnSendTapped(_ sender: Any) {
        txtCaption.resignFirstResponder()
        if self.delegate != nil {
            self.delegate?.imagePreviewDidDismiss(self.imageToUpload, caption: strCaption)
        }
        
        self.navigationController?.popViewController(animated: true)
    }
}


extension ImagePreviewViewController : UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        strCaption = textView.text!
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }        
        return true
    }
    
}
