//
//  SnDTextClickFlow.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/25.
//

import Foundation
import UIKit
import FHLCommon

/// 因為 comment 也有，所以從 Read 中抽離出來流程
/// Step1: 選 Action 動作 2: 執行對應動作
public class SnDTextClickFlow {
    init(vc: UIViewController,addr: DAddress,vers:[String]){
        _vc = vc
        _addr = addr
        _vers = vers
    }
    public func mainAsync(_ dtext:DText){
        if dtext.sn == nil { return }
        
        // 選 action 後, 開啟對應的功能；按取消不會呼叫
        _vc.presentSnActionPicker(sn: (dtext.tp ?? "") + dtext.sn!) { [self] action in
            dtext.snAction = action

            if action == .list {
                _doWhenSnDTextClickedForList(dtext)
            } else if action == .parsing {
                _doWhenUsingParsing()
            } else {
                _doWhenSnDTextClickedForDicts(dtext)
            }
        }
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
        
        _push(VCSearchResult(keyword: keyword, vers: _vers, addr: _addr))
    }
    private func _doWhenSnDTextClickedForDicts(_ dtext:DText){
        _push(VCSnDict(dtext: dtext, addr: _addr, vers: _vers))
    }
    private func _doWhenUsingParsing(){
        _push(VCParsing(addr: _addr, vers: _vers))
    }
}
