//
//  ManagerLangSet.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/15.
//

import Foundation
class ManagerAudioBible : NSObject {
    static var s: ManagerAudioBible = ManagerAudioBible()
    
    // speed 0.5 0.75 1.0 1.25 1.5 2.0
    var curSpeed: Float {
        if let cur = _curSpeed.cur, cur != 0.0 {
            return cur
        } else {
            return 1.0
        }
    }
    func updateSpeed(_ v:Float) { _curSpeed.updateCur(v) }
    lazy var _curSpeed = CurSpeed()
    class CurSpeed : GlobalVariableFloatBase {
        override var _tp: FHLUserDefaults.keys { .AudioBibleSpeed }
        override var _getDefaultFloat: Float { 1.0 }
    }
    
    // version index
    var curVersionIndex: Int { _curVersionIndex.cur! }
    func updateVersionIndex(_ v:Int) { _curVersionIndex.updateCur(v) }
    lazy var _curVersionIndex = CurVersionIndex()
    class CurVersionIndex : GlobalVariableIntBase {
        override var _tp: FHLUserDefaults.keys { .AudioBibleVersionIndex }
        override var _getDefaultInt: Int{ 0 }
    }
    
    // loop mode (enum 轉 int)
    var curLoopMode: DAudioBible.LoopMode {
        guard let cur = _curLoopMode.cur else { return .All }
        switch cur {
        case 1:
            return .Book
        case 2:
            return .Chap
        default:
            return .All
        }
    }
    func updateLoopMode(_ v:DAudioBible.LoopMode) {
        switch v {
        case .Book:
            _curLoopMode.updateCur(1)
        case .Chap:
            _curLoopMode.updateCur(2)
        default:
            _curLoopMode.updateCur(0)
        }
    }
    lazy var _curLoopMode = CurVersionIndex()
    class CurLoopMode : GlobalVariableIntBase {
        override var _tp: FHLUserDefaults.keys { .AudioBibleLoopMode }
        override var _getDefaultInt: Int{ 0 }
    }
}
