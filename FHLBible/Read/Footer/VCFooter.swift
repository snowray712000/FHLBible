//
//  VCFooter.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/22.
//

import Foundation
import UIKit

class VCFooter : UIViewController {
    /// 第一個 ver, 是目前 col. 第二個 vers 主要是若內容 click reference 時要用到的
    func setInitData(_ dtext: DText, _ ver: String, _ addr: DAddress,_ vers:[String]){
        _dtext = dtext
        _ver = ver
        _addr = addr
        _vers = vers
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// 繪圖
        self._dataOnChanged$.addCallback { sender, pData in
            self._drawData()
        }
        
        /// 內容字 click
        self.v2.onClicked$.addCallback { sender, pData in
            if pData != nil && pData!.refDescription != nil {
                print (pData!.w!)
                let vc = self.gVCRead()
                let r1 = StringToVerseRange().main(pData!.refDescription!, (self._addr.book,self._addr.chap))
                vc.setInitData( VerseRange(r1) , self._vers)
                self.navigationController?.pushViewController(vc, animated: false)
            }
        }
        _swipeHelp.addSwipe(dir: .left)
        _swipeHelp.addSwipe(dir: .right)
        _swipeHelp.onSwipe$.addCallback { sender, pData in
            if pData?.direction == .right {
                self.doPrev()
            } else if pData?.direction == .left {
                self.doNext()
            }
        }
        
        // init
        _drawData() // 取資料資中
        _queryDataAsyncAndTriggerDataChanged() // 第1次查詢
    }
    lazy var _swipeHelp = SwipeHelp(view:self.view)
    @IBOutlet var _viewText: UIView!
    fileprivate var v2: ViewDisplayCell { _viewText as! ViewDisplayCell }
    fileprivate var _dtext: DText!
    fileprivate var _pFoot: DFoot { self._dtext.foot! }
    /// 按 下一個，或上一個的時候，而改變的
    fileprivate var _dtextIdOfFootOfTextChanged$: IjnEventAny = IjnEvent()
    /// engs=Matt&chap=1&version=cnet&id=1
    fileprivate func gParam() -> String { "engs=\(BibleBookNames.getBookName(_addr.book, .Matt))&chap=\(_addr.chap)&version=\(_ver!)&id=\(_pFoot.id!)&\(ManagerLangSet.s.curQueryParamGb)" }
    fileprivate var _ver: String!
    fileprivate var _addr: DAddress!
    fileprivate var _vers: [String]!
    
    fileprivate var _data: [DText] = []
    fileprivate var _dataOnChanged$: IjnEventAny = IjnEvent()
    
    fileprivate func _queryDataAsyncAndTriggerDataChanged(){
        let param = gParam()
        fhlRt(param) { data in
            if data.isSuccess() == false {
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: false)
                    print (data.status)
                    return
                }
                return
            }
            
            self._data = cvtFooter(data.record.first!.text!,self._addr,self._ver)
            DispatchQueue.main.async {
                self._dataOnChanged$.trigger()
            }
        }
    }
    
    fileprivate func _drawData(){
        if _data.count == 0 {
            v2.set([DText(NSLocalizedString("取得資料中...", comment: ""))], false)
        } else {
            v2.set(_data, true)
        }
        self.title = "【\(self._pFoot.id!)】"
    }
    
    @IBAction func doNext(){
        let id = _pFoot.id!
        let r1 = _dtext.clone()
        r1.foot!.id = id + 1
        self._dtext = r1
        
        self._queryDataAsyncAndTriggerDataChanged()
        
    }
    @IBAction func doPrev(){
        let id = _pFoot.id!
        if id > 0 {
            let r1 = _dtext.clone()
            r1.foot!.id = id - 1
            self._dtext = r1
            
            self._queryDataAsyncAndTriggerDataChanged()
        }
    }
}
