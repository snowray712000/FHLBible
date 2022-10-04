//
//  ManagerHistoryOfRead.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/10.
//

import Foundation

class ManagerHistoryOfRead : NSObject {
    static var s = ManagerHistoryOfRead()
    var cur:[String] { _curG.cur! }
    func updateCur(_ v:[String]) { _curG.updateCur(v) }
    
    fileprivate var _curG = CurG()
    fileprivate class CurG : GlobalVariableStringArrayBase {
        override var _tp: FHLUserDefaults.keys { .HistoryOfRead }
    }
}
