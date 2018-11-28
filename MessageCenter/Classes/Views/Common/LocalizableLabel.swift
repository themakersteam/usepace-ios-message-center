//
//  LocalizableLabel.swift
//  MessageCenter
//
//  Created by Muhamed ALGHZAWI on 28/11/2018.
//

import Foundation

class LocalizableLabel : UILabel {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        text = text?.localized
    }
}
