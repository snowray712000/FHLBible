//
//  ViewDisplayCell.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/27.
//

import Foundation
import UIKit

protocol IFindIndexOfCharInTextView {
    func findIndexOfChar(_ tv: UITextView,_ tapGesture: UITapGestureRecognizer) -> Int
}
protocol IFindWhichDTextFromIndexOfChar {
    func findWhichDText(_ dtexts: [DText],_ idxChar: Int) -> DText?
}

/// 使用 + set
/// 使用 onClicked$
@IBDesignable
class ViewDisplayCell : ViewFromXibBase {
    override var nibName: String { "ViewDisplayCell" }
    // override var bundleForInit: Bundle { Bundle(for: ViewDisplayCell.self) }
    @IBOutlet var viewText: UITextView!
    // Text View 本身無法水平 scroll ， 所以暫時無專案需用 。
    // @IBInspectable var isScroll: Bool { get { return viewText.isScrollEnabled } set {viewText.isScrollEnabled = newValue }}
    
    var dtexts: [DText] = []
    var onClicked$: IjnEvent<ViewDisplayCell,DText> = IjnEvent()
    
    /// isVisibleSn 是後來加的，為要繪圖隱藏或顯示 SN
    /// isFontNameOpenHanBibleTC 是後來加的，為要處理「台語」的字型
    /// RightToLeft 馬索拉原文(舊約時)
    func set(_ dtexts:[DText],_ isVisibleSn: Bool,_ isFontNameOpenHanBibleTC:Bool? = nil, _ tpTextAlignment: NSTextAlignment = .justified ){
        self.dtexts = dtexts
        self._isVisibleSn = isVisibleSn
        self._isFontNameOpenHanBibleTC = isFontNameOpenHanBibleTC
        
        viewText.textAlignment = tpTextAlignment
        viewText.attributedText = cvtForTextView(self.dtexts)
    }
    private var _isVisibleSn: Bool = false
    private var _isFontNameOpenHanBibleTC: Bool?
    private func cvtForTextView(_ dtexts: [DText]) -> NSAttributedString {
        let r2 = DTextDrawToAttributeString(_isVisibleSn,_isFontNameOpenHanBibleTC).mainConvert(self.dtexts)
        
        let re2 = NSMutableAttributedString()
        r2.forEach({re2.append($0)})
        return re2
    }
    lazy var iFindWhichDText: IFindWhichDTextFromIndexOfChar? = FindWhichDTextFromIndexOfChar(self._isVisibleSn)
    lazy var iFindIdxOfChar: IFindIndexOfCharInTextView? = FindIndexOfCharInTextView()
    var iConvertDTexts2AttributedString: IDTextToAttributeString? { DTextDrawToAttributeString (_isVisibleSn,_isFontNameOpenHanBibleTC) }
    
    override func initedFromXib() {
        addTapForDetectWord()
    }
    private func addTapForDetectWord(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapResponse))
        viewText!.addGestureRecognizer(tap)
    }
    @objc func tapResponse(recognizer: UITapGestureRecognizer) {
        let idxChar = iFindIdxOfChar!.findIndexOfChar(viewText, recognizer)
        let dtext = iFindWhichDText!.findWhichDText(self.dtexts, idxChar)
        
        onClicked$.trigger(self, dtext)
    }
}

