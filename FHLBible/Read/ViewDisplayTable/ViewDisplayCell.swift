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
    @IBOutlet weak var viewText: UITextView!
    @IBOutlet weak var switchOn: UISwitch!
    // Text View 本身無法水平 scroll ， 所以暫時無專案需用 。
    // @IBInspectable var isScroll: Bool { get { return viewText.isScrollEnabled } set {viewText.isScrollEnabled = newValue }}
    
    var dtexts: [DText] = []
    var onClicked$: IjnEvent<ViewDisplayCell,DText> = IjnEvent()
    var onLongClicked$: IjnEvent<ViewDisplayCell,[DText]> = IjnEvent()
    var onSwitchChanged$: IjnEvent<ViewDisplayCell,Bool> = IjnEvent()
    
    /**
     tableview 顯示，依 row，cell 層級，此為 cell 層級。
     - isFontNameOpenHanBibleTC 是後來加的，為要處理「台語」的字型
     - RightToLeft 馬索拉原文(舊約時)
     - isVisibleSn 是後來加的，為要繪圖隱藏或顯示 SN
     - parameters:
        - isFontNameOpenHanBibleTC: nil 或 false 都是示表不同台語顯示特殊字
        - tpTextAlignment: 預設左右對齊 .justified
     - note:
        - 因為 tableview 的 reuse 特性，所以常常會反覆呼叫 set ， 而且會共用控制項，真實的資料是存在 viewcontroller ， 不是 cell ，也不是 row，也不是 table
     */
    func set(dtexts:[DText],isVisibleSn: Bool,isFontNameOpenHanBibleTC:Bool? = nil,tpTextAlignment: NSTextAlignment = .justified,isSwitchOn: Bool,isSwitchVisible:Bool){
        self.dtexts = dtexts
        self._isVisibleSn = isVisibleSn
        self._isFontNameOpenHanBibleTC = isFontNameOpenHanBibleTC
        self._isOnSwitch = isSwitchOn
        self.setSwitchVisible(isSwitchVisible)
        
        // update ui
        viewText.textAlignment = tpTextAlignment
        viewText.attributedText = cvtForTextView(self.dtexts)
        switchOn.isOn = self._isOnSwitch
    }
    private var _isOnSwitch: Bool = false
    private var _isVisibleSwitch: Bool = false
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
    
    private var cns1, cns2, cns3, cns5: NSLayoutConstraint!
    
    private func change_constraint_for_switch_changed(_ isInstalled:Bool){
        if cns1 == nil {
            // SwitchOn Visible
            cns1 = switchOn.centerXAnchor.constraint(equalTo: viewBase.safeAreaLayoutGuide.centerXAnchor)
            cns2 = switchOn.topAnchor.constraint(equalTo: viewBase.safeAreaLayoutGuide.topAnchor)
            cns3 = switchOn.bottomAnchor.constraint(equalTo: viewText.topAnchor)
                        
            // SwitchOn Invisible
            cns5 = viewBase.safeAreaLayoutGuide.topAnchor.constraint(equalTo: viewText.topAnchor)
        }
        
        if isInstalled{
            cns5.isActive = false
            NSLayoutConstraint.activate([cns1,cns2,cns3])
        } else {
            NSLayoutConstraint.deactivate([cns1,cns2,cns3])
            cns5.isActive = true
        }
    }
    private func setSwitchVisible(_ isVisible:Bool){
        if isVisible{
            if false == viewBase.subviews.contains(where: { $0 == switchOn}){
                viewBase.addSubview(switchOn)
                change_constraint_for_switch_changed(true)
            }
        } else {
            switchOn.removeFromSuperview()
            change_constraint_for_switch_changed(false)
        }
    }
    override func initedFromXib() {
        addTapForDetectWord()
        self.switchOn.addTarget(self, action: #selector(onSwitchValueChanged(_:)), for: .valueChanged)
        setSwitchVisible(self._isVisibleSwitch)
    }
    

    @objc private func onSwitchValueChanged(_ switch: UISwitch) {
        //do something here
        self.onSwitchChanged$.trigger(self, switchOn.isOn )
    }
    
    private func addTapForDetectWord(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapResponse))
        
        // 創建長按手勢辨識器
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        
        viewText!.addGestureRecognizer(longPressGesture)
        viewText!.addGestureRecognizer(tap)
        
        tap.require(toFail: longPressGesture)
    }
    @objc func tapResponse(recognizer: UITapGestureRecognizer) {
        let idxChar = iFindIdxOfChar!.findIndexOfChar(viewText, recognizer)
        let dtext = iFindWhichDText!.findWhichDText(self.dtexts, idxChar)
        
        onClicked$.trigger(self, dtext)
    }
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            // 長按事件處理
            if gesture.state == .began {
                // 在這里處理長按事件的開始 (0.5秒後)
                onLongClicked$.trigger(self, self.dtexts)
            } else if gesture.state == .ended {
                // 在這里處理長按事件的結束 (放開後)
                // print(self.dtexts.map({ dtext in return dtext.w ?? ""}).joined())
            }
        }

}

