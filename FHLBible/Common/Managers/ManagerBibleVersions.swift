//
//  ManagerBibleVersions.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/10.
//

import Foundation
import FHLCommon

class ManagerBibleVersions : NSObject {
    static var s: ManagerBibleVersions = ManagerBibleVersions()
    override init(){
        super.init()
    }
    
    var cur: [String] { _curG.cur! }
    var curChanged$: IjnEventAny { _curG.curChanged$ }
    func updateCur(_ v:[String]) { _curG.updateCur(v) }
    var recent: [String] { _recG.cur! }
    var recentChanged$: IjnEventAny { _recG.curChanged$ }
    func updateRecent(_ v:[String]) { _recG.updateCur(v) }
    var sets: [[String]] {
        let r1 = _setG.cur!
        let r2 = r1.split(separator: ";")
        let r3 = r2.map({$0.split(separator: ",")})
        return r3.map({$0.map({String($0)})})
    }
    func updateSets(_ v:[[String]]){
        let r1 = v.map({$0.joined(separator: ",")}).joined(separator: ";")
        _setG.updateCur(r1)
    }
    var isOnSub: Bool { _onSub.cur == 1 }
    func updateOnSub(_ v:Bool) { _onSub.updateCur( v ? 1 : 0)}
    var optSub: BibleVersionConstants.TpGroup { BibleVersionConstants.TpGroup(rawValue: _optSub1.cur ?? ""  ) ?? .ch }
    func updateOptSub(_ v:  BibleVersionConstants.TpGroup) { _optSub1.updateCur(v.rawValue) }
    /// 中文「次分類」篩選目前勾選的條件 (教派、文體、年代)；從沒存過時是預設值
    var optSub2: [BibleVersionConstants.TpChtSub] { (_optSub2.cur ?? []).compactMap({BibleVersionConstants.TpChtSub(rawValue: $0)}) }
    func updateOptSub2(_ v: [BibleVersionConstants.TpChtSub]) { _optSub2.updateCur(v.map({$0.rawValue})) }
    
    fileprivate var _curG: Cur = Cur()
    fileprivate var _recG: Recent = Recent ()
    fileprivate var _setG = Sets()
    fileprivate var _onSub = OnSub()
    fileprivate var _optSub1 = Sub1Opt()
    fileprivate var _optSub2 = Sub2Opt()
    
    fileprivate class Cur : GlobalVariableStringArrayBase {
        override var _tp: FHLUserDefaults.keys { .BibleVersions }
        override var _getDefaultStringArray: [String] { ["unv"] }
    }
    fileprivate class Recent : GlobalVariableStringArrayBase {
        override var _tp: FHLUserDefaults.keys { .BibleVersionsRecently }
    }
    fileprivate class Sets : GlobalVariableStringBase {
        override var _tp: FHLUserDefaults.keys {.BibleVersionsSets}
    }
    fileprivate class OnSub : GlobalVariableIntBase {
        override var _tp: FHLUserDefaults.keys { .BibleVersionIsOnSub }
    }
    fileprivate class Sub1Opt : GlobalVariableStringBase {
        override var _tp: FHLUserDefaults.keys { .BibleVersionSub1Opt }
    }
    fileprivate class Sub2Opt : GlobalVariableStringArrayBase {
        override var _tp: FHLUserDefaults.keys { .BibleVersionSub2Opt }
        /// 與舊的 xib 預設一致：三種教派、官話、1919-60、近代
        override var _getDefaultStringArray: [String] {
            [.pr, .cc, .ro, .officer, .yr1960, .yrnow].map({ (a: BibleVersionConstants.TpChtSub) in a.rawValue })
        }
    }
}


