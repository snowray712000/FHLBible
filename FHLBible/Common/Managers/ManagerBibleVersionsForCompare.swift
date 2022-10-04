//
//  ManagerBibleVersions.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/10.
//

import Foundation

class ManagerBibleVersionsForCompare : NSObject {
    static var s: ManagerBibleVersionsForCompare = ManagerBibleVersionsForCompare()
    override init(){
        super.init()
    }
    
    var cur: [String] { _curG.cur! }
    func updateCur(_ v:[String]) { _curG.updateCur(v) }
    fileprivate var _curG: Cur = Cur()
    fileprivate class Cur : GlobalVariableStringArrayBase {
        override var _tp: FHLUserDefaults.keys { .BibleVersionsForCompare }
        override var _getDefaultStringArray: [String] { ["unv","esv","cbol"] }
    }
}


