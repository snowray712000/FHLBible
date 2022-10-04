//
//  ManagerLangSet.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/15.
//

import Foundation
class ManagerIsSnVisible : NSObject {
    static var s: ManagerIsSnVisible = ManagerIsSnVisible()
    var cur: Bool { _cur.cur == 1 }
    func updateCur(_ v:Bool) {
        if v {
            _cur.updateCur(1)
        } else {
            _cur.updateCur(0)
        }
    }
    lazy var _cur = Cur()
    class Cur : GlobalVariableIntBase {
        override var _tp: FHLUserDefaults.keys { .isSn }
        override var _getDefaultInt: Int { 0 }
    }
}
