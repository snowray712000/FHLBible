//
//  VCComment.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/10.
//

import Foundation
import UIKit
import IJNSwift
import FMDB

class VCComment : UIViewController {
    func setInitData(_ addr: DAddress){
        self.addr = addr
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // apiResult -> addr
        // addrNext, addrPrev, datas -> apiResult
        addrChanged$.addCallback { sender, pData in
            self.datas = [DText(NSLocalizedString("取得資料中...", comment: ""))]
            self.draw()
            self.reloadDatas()
        }
        apiResultChanged$.addCallback { sender, pData in
            if self.apiErrorMsg != nil {
                self.v2.set(self.apiErrorMsg!, true)
            } else {
                let com_text = self.apiResult!.com_text ?? ""
                // let com_text = self.apiResult!.record.first!.com_text ?? ""
                self.datas = CommentDataStrToDText().main(com_text)
                self.draw()
            }
        }
        
        // 點擊到內容中的交叉參照
        v2.onClicked$.addCallback { sender, pData in
            if pData != nil && pData!.refDescription != nil {
                let r1 = StringToVerseRange().main(pData!.refDescription!, (self.addr.book,self.addr.chap))
                let r2 = self.gVCRead()
                r2.setInitData(VerseRange(r1), ManagerBibleVersions.s.cur)
                self.navigationController?.pushViewController(r2, animated: false)
            }
        }
        // 點擊到內容中的 原文 SN
        v2.onClicked$.addCallback { sender, pData in
            if pData != nil && pData!.sn != nil {
                let vers = ManagerBibleVersions.s.cur
                SnDTextClickFlow(vc: self, addr: self.addr, vers: vers).mainAsync(pData!)
            }
        }
        _swipeHelp.addSwipe(dir: .left)
        _swipeHelp.addSwipe(dir: .right)
        _swipeHelp.onSwipe$.addCallback { sender, pData in
            if pData?.direction == .right {
                self.goPrev()
            } else if pData?.direction == .left {
                self.goNext()
            }
        }
        
        // 首先觸發
        addrChanged$.trigger()
    }
    lazy var _swipeHelp = SwipeHelp(view:self.view)
    @IBOutlet var viewCell: UIView!
    @IBAction func goNext(){
        if addrNext != nil {
            addr = addrNext
            addrChanged$.trigger()
        }
    }
    @IBAction func goPrev(){
        if addrPrev != nil {
            addr = addrPrev
            addrChanged$.trigger()
        }
    }
    
    // apiResult, reloadData() -> addr
    // addrNext, addrPrev, datas -> apiResult
    // draw() -> datas
    var addr: DAddress!
    var addrChanged$: IjnEventAny = IjnEvent()
    
    var datas: [DText] = []
    var apiErrorMsg: [DText]?
    var apiResult: DReloadData? // DApiSc?
    var apiResultChanged$: IjnEventAny = IjnEvent()
    // reload data 關鍵是，完成後，會 trigger ResultChanged$
    // 關鍵資料 apiResult
    func reloadDatas(){
        let r1:IReloadData = ReloadDataAutoUseOfflineOrScApi()
        r1.apiFinished$.addCallback { sender, pData in
            self.apiErrorMsg = nil
            self.apiResult = nil
            if sender != nil {
                self.apiErrorMsg = sender!
            } else {
                self.apiResult = pData!
            }
            self.apiResultChanged$.trigger()
        }
        r1.reloadAsync(self.addr)
    }
    func draw(){
        v2.set(datas, true, false, .left)
        title = titleComment
    }
    var v2: ViewDisplayCell { viewCell as! ViewDisplayCell }
    var addrNext: DAddress? {
        return apiResult?.addrNext
    }
    var addrPrev: DAddress? {
        return apiResult?.addrPrev
    }
    var titleComment: String? {
        let prev = addrPrev
        let next = addrNext
        if (apiResult == nil || next == nil || prev == nil ){
            return NSLocalizedString("註釋", comment: "") + addr.toString(ManagerLangSet.s.curTpBookNameLang)
            //return "註釋 \(addr.toString(.太))"
        }
        
        // comment 會有 第 0 章，也就是此卷書的導論
        let r1 = prev!.chap == 0 ? DAddress(prev!.book,1,1) : prev!.goNextVerse()
        let r2 = next!.goPrevVerse()
        
        let r3 = ManagerLangSet.s.curTpBookNameLang
        return NSLocalizedString("註釋", comment: "") + "\(r1.toString(r3))至\(r2.toString(r3))"
        //return "註釋 \(r1.toString(.太))至\(r2.toString(.太))"
    }
}
