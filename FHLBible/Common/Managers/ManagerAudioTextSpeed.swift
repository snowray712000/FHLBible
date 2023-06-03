//
//  ManagerAudioTextSpeed.swift
//  FHLBible
//
//  Created by littlesnow on 2023/6/2.
//

import Foundation
class ManagerAudioTextSpeed : NSObject {
    static var s: ManagerAudioTextSpeed = ManagerAudioTextSpeed()
    
    // speed 0.5 0.75 1.0 1.25 1.5 2.0
    var curSpeed: [Float] {
        let cntArray = 8
        if _curSpeed._cur == nil {
            return Array(repeating: 1.0, count: cntArray )
        }
        
        var speeds = _curSpeed._cur!.map { Float($0) ?? 1.0 }
        speeds += Array(repeating: 1.0, count: cntArray - speeds.count )
        return speeds
    }
    func updateSpeed(_ v:[Float]) { _curSpeed.updateCur(v.map { String(format: "%.2f", $0) }) }
    fileprivate lazy var _curSpeed = CurG()
    fileprivate class CurG : GlobalVariableStringArrayBase {
        override var _tp: FHLUserDefaults.keys { .AudioTextSpeed }
    }
}
