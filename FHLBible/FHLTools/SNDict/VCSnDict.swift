//
//  VCSnDict.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/29.
//

import UIKit

class VCSnDict: UIViewController {
    /// addr, vers 是因為若點點了 內容，有時候可能會需要，而非 dict 真的需要
    func setInitData(_ dtext: DText,_ addr:DAddress,_ vers: [String]){
        assert ( dtext.sn != nil )
        assert ( dtext.snAction != nil)
        _dtext = dtext
        _addr = addr
        _vers = vers
    }
    /// draw() -> _data -> _dtext
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _swipeHelp.addSwipe(dir: .right)
        _swipeHelp.addSwipe(dir: .left)
        _swipeHelp.onSwipe$.addCallback { sender, pData in
            if pData?.direction == .right {
                self.goPrev()
            } else if pData?.direction == .left {
                self.goNext()
            }
        }
        
        _dataOnChanged$.addCallback { sender, pData in
            self.drawData()
        }
        _dtextOnChanged$.addCallback { sender, pData in
            self._data = [DText(NSLocalizedString("取得資料中...", comment: ""))]
            self.drawData()
            self.reloadData()
            
            self.reCalcNextPrevDText()
            self.drawNextPrevButton()
            
            self.drawTitle()
        }
        // 點擊內容時，交互參照
        v2.onClicked$.addCallback { sender, pData in
            // print (pData?.w )
            if pData != nil && pData!.refDescription != nil {
                let r1 = self.gVCRead()
                let r2 = StringToVerseRange().main(pData!.refDescription!, nil)
                r1.setInitData(VerseRange( r2 ), ManagerBibleVersions.s.cur)
                self.navigationController?.pushViewController(r1, animated: false)
            }
        }
        // 點擊內容時，原文
        v2.onClicked$.addCallback { sender, pData in
            if pData != nil && pData!.sn != nil {
                let r1 = pData!.clone()
                r1.snAction = self._dtext!.snAction
                let r2 = self.gVCSnDict()
                r2.setInitData(r1, self._addr,self._vers)
                self.navigationController?.pushViewController(r2, animated: false)
            }
        }
        
        // 開始動作
        _dtextOnChanged$.trigger()
    }
    lazy var _swipeHelp = SwipeHelp(view: self.view)
    @IBAction func doDictMore(){
        let vc = VCSnDictMore()
        vc.onPicker$.addCallback { sender, pData in
            if pData == "prev" {
                self.goPrev()
            } else if pData == "next" {
                self.goNext()
            }
        }
        vc.presentMe(self)
    }
    @IBAction func doSnList(){
        if _dtext == nil { return }
        
        let r1 = _dtext!.clone()
        r1.snAction = .list
        
        let vc = self.gVCSearchResult()
        vc.setInitData(_dtext!.w!, _vers, _addr)
        self.navigationController?.pushViewController(vc, animated: false)
    }
    @IBAction func goNext(){
        if _dtextNext != nil {
            _dtext = _dtextNext
            self._dtextOnChanged$.trigger()
        }
    }
    @IBAction func goPrev(){
        if _dtextPrev != nil {
            _dtext = _dtextPrev
            self._dtextOnChanged$.trigger()
        }
    }
    
    var _dtext: DText?
    var _dtextOnChanged$: IjnEventAny = IjnEvent()
    var _data: [DText]?
    var _isVisibleSn: Bool = true // Sn Dict 總是需要顯示 Sn
    var _dataOnChanged$: IjnEventAny = IjnEvent()
    func drawData(){
        v2.set(_data ?? [], self._isVisibleSn )
    }
    func reloadData(){
        let r1 = SnDictDataQ()
        r1.onFinishedQ$.addCallback { sender, pData in
            self._data = r1.resultContent
            self._dataOnChanged$.trigger()
        }
        r1.main(_dtext!)
    }
    var _addr: DAddress!
    var _vers: [String]!
    

    @IBOutlet var viewCell: UIView!
    @IBOutlet var btnPrev: UIButton!
    @IBOutlet var btnNext: UIButton!
    var v2: ViewDisplayCell { viewCell as! ViewDisplayCell }
    func reCalcNextPrevDText(){
        // step1 先清空
        _dtextNext = nil
        _dtextPrev = nil
        
        if _dtext == nil { return  }
        let r1 = _dtext!
        
        // 取出數字
        let r2 = ijnMatchFirstAndToSubString(try! NSRegularExpression(pattern: #"\d+"#, options: []), r1.sn!)
        if r2 == nil { return  }
        
        let r3 = Int(r2![0]!)!
        let r4next = (r3 + 1).description
        let r4prev = (r3 - 1).description
        
        // 設定值
        _dtextNext = DText(r1.tp! + r4next, sn: r4next, tp: r1.tp!, tp2: "")
        _dtextNext!.snAction = r1.snAction
        
        _dtextPrev = DText(r1.tp! + r4prev, sn: r4prev, tp: r1.tp!, tp2: "")
        _dtextPrev!.snAction = r1.snAction
    }
    func drawTitle(){

        var r1: String {
            if _dtext != nil {
                if _dtext!.snAction != nil {
                    switch _dtext!.snAction! {
                    case .twcb:
                        return "浸宣字典"
                    case .cbol, .cbole:
                        return "cbol字典"
                    default:
                        return "原文字典"
                    }
                }
            }
            
            return "原文字典"
        }
        
        let r2 = r1 + _dtext!.w!
        title = r2
    }
    func drawNextPrevButton(){
        if _dtextPrev != nil {
            //btnPrev.setTitle(_dtextPrev!.w!, for: .normal)
        }
        if _dtextNext != nil {
            //btnNext.setTitle(_dtextNext!.w!, for: .normal)
        }
    }
    var _dtextNext: DText?
    var _dtextPrev: DText?
}
