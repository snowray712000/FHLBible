//
//  ViewParsing.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/3.
//

import UIKit

class ViewParsing : ViewFromXibBase {
    override var nibName: String {"ViewParsing"}
    @IBOutlet var stack: UIStackView!
    @IBOutlet var viewEnd: UIView!
    typealias OneSet = (w:[DText],cht:[DText],dict:[ViewParsingDict.OneData])
    override func initedFromXib() {
    }

    var _isRightToLeft: Bool = false
    var _datas: [OneSet] = [] {
        didSet {
            stack.arrangedSubviews.forEach({$0.removeFromSuperview()})
            
            for a1 in _datas {
                let r1 = ViewParsingWord()
                r1.setTextsFirstCellTitle(a1.w, self._isRightToLeft)
                r1.setTextsSecondCellTitle(a1.cht, self._isRightToLeft)
                stack.addArrangedSubview(r1)
                
                let r2 = ViewParsingDict()
                r2.set(a1.dict, true)
                stack.addArrangedSubview(r2)
                
                r2.heightAnchor.constraint(equalTo: r1.heightAnchor, multiplier: 2.5).isActive = true
            }
            
            // add last red view (知道到底了, 一個 stop 線的概念)
            stack.addArrangedSubview(viewEnd)
        }
    }
}


