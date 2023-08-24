//
//  RefDTextClickFlow.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/27.
//

import Foundation
import UIKit

/// 原本在 read 中，但是搜尋結果顯示若有 reference，流程一樣，所以就抽出 class
class OneVerseFunctionsClickFlow : NSObject {
    init(vc: UIViewController,addrThisPageFirst addr:DAddress?,vers vers:[String]){
        _vc = vc
        _addrThisPage = addr
        _vers = vers
    }
    /// 這不是真正的 main, 只是協助將 dtext.w 轉為 addr
    /// 這個其實是配合原本 VCRead 長相加的，但這個的本質其實是 addr
    /// 若 w 為空，會直接 return 不作任何事
    func mainAsync(_ dtext:DText?){
        if dtext == nil || dtext!.w == nil { return }

        let addr = _cvtDText2DAddress(dtext!)
        if addr == nil { return }
        
        mainAsync(addr!)
    }
    /// 選取功能，然後執行對應功能
    func mainAsync(_ addr:DAddress){
        _addr = addr
        
        // 選擇功能，選擇後，去作對應的事
        let vc1 = _vc.gVCVerseActionPicker()
        vc1.onPicker$.addCallback { sender, pData in
            if pData != nil {
                self._verseAction = pData!
                // 去作對應的事
                self._doWhenClickedVerseAddressCell()
            }
        }
        vc1.presentMe(_vc)
        
    }
    
    private var _vc: UIViewController!
    private var _addrThisPage: DAddress?
    private var _addr: DAddress!
    var _vers: [String] = []
    
    /// 選擇功能後，會設定
    private var _verseAction: VerseAction!
    private func _cvtDText2DAddress(_ d:DText)->DAddress?{
        let addr = self._addrThisPage
        let bk = addr == nil ? 1 : addr!.book
        let cp = addr == nil ? 1 : addr!.chap
        
        let r1 = StringToVerseRange().main(d.w!, (bk,cp))
        if r1.count != 0 {
            return r1.first!
        } else {
            return nil
        }
    }
    private func _doWhenClickedVerseAddressCell(){
        let push = { (a1: UIViewController) in
            self._vc.navigationController?.pushViewController(a1, animated: false)
        }
        
        let act = self._verseAction
        if act == .InfoTsk {
            let vc2 = _vc.gVCTsk()
            vc2.setInitData(_addr ?? DAddress(1,1,1))
            push(vc2)
        } else if act == .InfoComment {
            let vc2 = _vc.gVCComment()
            vc2.setInitData(_addr ?? DAddress(1,1,1))
            push(vc2)
        } else if act == .VersionsCompare {
            let vc2 = _vc.gVCVersionsCompareInOneVerse()
            vc2.setInitData(_addr ?? DAddress(1,1,1))
            push(vc2)
        } else if act == .InfoParsing {
            let vc2 = _vc.gVCParsing()
            vc2.set(_addr, _vers )
            push(vc2)
        }
    }
    
}
