//
//  SnDTextClickFlow.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/25.
//

import Foundation
import UIKit

/// 因為 comment 也有，所以從 Read 中抽離出來流程
/// Step1: 選 Action 動作 2: 執行對應動作
class SnDTextClickFlow {
    init(vc: UIViewController,addr: DAddress,vers:[String]){
        _vc = vc
        _addr = addr
        _vers = vers
    }
    func mainAsync(_ dtext:DText){
        if dtext.sn == nil { return }
        
        let r1 = _vc.gVCSnActionPicker()
        r1.onPicker$.addCallback { sender, pDataAction in
            if pDataAction != nil {
                // 選了 action 後, 開啟對應的功能
                dtext.snAction = pDataAction
                
                if dtext.snAction == .list {
                    self._doWhenSnDTextClickedForList(dtext)
                } else if dtext.snAction == .parsing {
                    self._doWhenUsingParsing()
                } else if dtext.snAction != nil {
                    self._doWhenSnDTextClickedForDicts(dtext)
                }
            } else { } // 按下 cancel
        }
        r1.presentMe(_vc)
    }
    
    private var _vc: UIViewController!
    private var _addr: DAddress!
    private var _vers: [String]!
    
    private func  _push(_ vc:UIViewController){
        _vc!.navigationController?.pushViewController(vc, animated: false)
    }
    private func _doWhenSnDTextClickedForList(_ dtext:DText){
        // 不可直接用 dtext.w! 因為可能會是 <G3212> 而非 G3212
        let keyword = dtext.tp! + dtext.sn!
        
        let vcSnSearch = _vc.gVCSearchResult()
        vcSnSearch.setInitData(keyword, _vers, _addr)
        _push(vcSnSearch)
    }
    private func _doWhenSnDTextClickedForDicts(_ dtext:DText){
        let vcSnDict = _vc.gVCSnDict()
        vcSnDict.setInitData(dtext, _addr, _vers)
        _push(vcSnDict)
    }
    private func _doWhenUsingParsing(){
        let vc2 = _vc.gVCParsing()
        vc2.set(_addr, _vers)
        _push(vc2)
    }
}
