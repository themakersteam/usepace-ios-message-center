//
//  LocalizableButton.swift
//  MessageCenter
//
//  Created by Muhamed ALGHZAWI on 28/11/2018.
//

import Foundation

class LocalizableButton : UIButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let title = self.title(for: .normal)?.localized
        setTitle(title, for: .normal)
    }
    
}
