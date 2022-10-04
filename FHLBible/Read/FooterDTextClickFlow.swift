//
//  RefDTextClickFlow.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/27.
//

import Foundation
import UIKit

/// 原本在 read 中，但是搜尋結果顯示若有 reference，流程一樣，所以就抽出 class
class FooterDTextClickFlow : NSObject {
    init(vc: UIViewController,vers: [String]){
        self._vc = vc
        _vers = vers
    }
    func mainAsync(_ dtext:DText,_ ver:String,_ addr: DAddress){
        if dtext.foot == nil { return }
        
        // 準備參數給 VCFooter
        _dtext = dtext
        _addr = addr
        _ver = ver
        
        // 主流程
        let vc = _vc.gVCFooter()
        vc.setInitData(dtext, _ver, _addr! ,_vers)
        _vc.navigationController?.pushViewController(vc, animated: false)
    }
    
    private var _vc: UIViewController!
    private var _vers: [String]!
    private var _ver: String!
    private var _row: Int!
    private var _col: Int!
    private var _dtext: DText!
    private var _addr: DAddress?
}
