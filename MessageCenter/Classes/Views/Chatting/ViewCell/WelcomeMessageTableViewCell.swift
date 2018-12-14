//
//  WelcomeMessageTableViewCell.swift
//  Alamofire
//
//  Created by Ikarma Khan on 10/12/2018.
//

import UIKit
import SendBirdSDK

class WelcomeMessageTableViewCell: UITableViewCell {

    private var message: SBDUserMessage!
    private var prevMessage: SBDBaseMessage?
    private var displayNickname: Bool = true
    private var podBundle: Bundle!

    @IBOutlet weak var vwBackground: UIView!
    @IBOutlet weak var lblMessage: UILabel!
    public var containerBackgroundColour: UIColor = UIColor(red: 237.0/255.0, green: 237.0/255.0, blue: 237.0/255.0, alpha: 1.0)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.podBundle = Bundle(for: MessageCenter.self)
    }
    
    static func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }
    
    static func cellReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
