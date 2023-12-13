//
//  ViewSNDictCell.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/3.
//

import Foundation
import UIKit

/// 使用 set
@IBDesignable
class ViewSNDictCell : ViewFromXibBase{
    override var nibName: String {"ViewSNDictCell"}
    func set(_ sn:DText, _ word: DText, _ orig: DText,wform: [DText], exp: [DText],remark: [DText]){
        _sn = sn
        _word = word
        _orig = orig
        _wform = wform
        _exp = exp
        _remark = remark
    }
    @IBOutlet weak var btnSn: UIButton!
    @IBOutlet weak var btnWord: UIButton!
    @IBOutlet weak var btnOrig: UIButton!
    @IBOutlet weak var showerXForm: ViewDisplayCell!
    @IBOutlet weak var showerXRemark: ViewDisplayCell!
    @IBOutlet weak var showerXExp: ViewDisplayCell!
    @IBOutlet weak var stackLast: UIStackView!
    
    //var evBtnSnClicked$: IjnEventAdvancedAny = IjnEventAdvancedAny()
    var evBtnSnClicked$: IjnEventAdvanced<Any,DText> = IjnEventAdvanced()
    override func initedFromXib() {
        _sn = DText("G1321", sn: "1321", tp: "G", tp2: "WG")
        // _wform = [DText("G1242"), DText("ajgoaw")]
        _wform = testRemarkH1
        _remark = []
        
        // 使用闭包为按钮的 Primary Action 添加事件
        btnSn.addAction(UIAction(handler: { [weak self] _ in
            self?.clickBtnSn()
        }), for: .primaryActionTriggered)
    }
    deinit{
        self.evBtnSnClicked$.clearCallback()
    }
    @IBAction func clickBtnSn(){
        evBtnSnClicked$.trigger(self, _sn)
    }
    private var testRemarkH1: [DText] {
        let r1 = "\u{4ecb}\u{7cfb}\u{8a5e} \u{05d1}\u{05bc}\u{05b0} + \u{540d}\u{8a5e}\u{ff0c}\u{9670}\u{6027}\u{55ae}\u{6578}"
        return [DText(r1)]
    }
    var _sn: DText = DText() {
        didSet {
            btnSn.setTitle(_sn.w ?? "", for: .normal)
        }
    }
    var _word: DText = DText() {
        didSet {
            btnWord.setTitle(_word.w ?? "", for: .normal)
        }
    }
    var _orig: DText = DText() {
        didSet {
            btnOrig.setTitle(_orig.w ?? "", for: .normal)
        }
    }
    /// .pro (新約才有，名詞/動詞) + .wform
    var _wform: [DText] = [] {
        didSet {
            _set_cell(cell: showerXForm, data: _wform, isSn: true)
        }
    }
    var _remark: [DText] = [] {
        didSet{
            if _remark.count == 0 || (_remark.count == 1 && _remark[0].w!.isEmpty ) {
                stackLast.isHidden = true
            } else {
                _set_cell(cell: showerXRemark, data: _remark, isSn: true)
                stackLast.isHidden = false
            }
        }
    }
    var _exp: [DText] = [] {
        didSet {
            _set_cell(cell: showerXExp, data: _exp, isSn: true)
        }
    }
    private func _set_cell(cell: ViewDisplayCell,data: [DText],isSn: Bool){
        cell.set(dtexts: data, isVisibleSn: isSn, isSwitchOn: true, isSwitchVisible: false)
    }
}

