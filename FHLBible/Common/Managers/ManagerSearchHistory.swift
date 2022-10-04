//
//  ManagerSearchHistory.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/17.
//

import Foundation

class ManagerSearchHistory : NSObject {
    static var s = ManagerSearchHistory()
    var cur: [String] { _curG.cur! }
    func updateCur(_ v:[String]) {       _curG.updateCur(v)
    }
    
    var _curG = Cur ()
    class Cur : GlobalVariableStringArrayBase {
        override var _tp: FHLUserDefaults.keys { .SearchHistory }
        override var _getDefaultStringArray: [String] { [] }
    }
}
