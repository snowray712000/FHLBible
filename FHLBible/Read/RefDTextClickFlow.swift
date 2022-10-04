//
//  RefDTextClickFlow.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/27.
//

import Foundation
import UIKit

/// 原本在 read 中，但是搜尋結果顯示若有 reference，流程一樣，所以就抽出 class
class RefDTextClickFlow : NSObject {
    init(vc: UIViewController,addr: DAddress,vers:[String]){
        _vc = vc
        _addr = addr
        _vers = vers
    }
    func mainAsync(_ dtext:DText){
        if dtext.refDescription == nil { return }
        
        // 和合本2010 太1 可以測試
        let vc = _vc.gVCRead()
        let addr = _addr!
        let ref = StringToVerseRange().main(dtext.refDescription!, (addr.book,addr.chap))
        vc.setInitData(VerseRange(ref), _vers)
        _vc.navigationController?.pushViewController(vc, animated: false)
    }
    var _vc: UIViewController!
    var _addr: DAddress!
    var _vers: [String]!
}
