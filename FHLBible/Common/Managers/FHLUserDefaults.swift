//
//  FHLUserDefaults.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/9.
//

import Foundation

/// 此 class 不管理預設值，只在乎 key 不要重複
/// 有新的全域變數，則依型別，去繼續 GlobalVariableStringBase GlobalVariableStringArrayBase 這些去實作
/// 最簡單的，是 ManagerIsSnVisible，可以參考它
/// 總之，就是 cur, updateCur, onCurChanged$ 3 個是最主要實作的
class FHLUserDefaults : NSObject {
    static var s: FHLUserDefaults = FHLUserDefaults()
    
    enum keys:String {
        case None = "None"
        case AddressCurrent = "AddressCurrent"
        case BibleVersions = "BibleVersions"
        case BibleVersionsForCompare = "BibleVersionsForCompare"
        case BibleVersionsRecently = "BibleVersionsRecenlty"
        case BibleVersionsSets = "BibleVersionsSets"
        case BibleVersionIsOnSub = "BibleVersionIsOnSub"
        case BibleVersionSub1Opt = "BibleVersionSub1Opt"
        case BibleVersionSub2Opt = "BibleVersionSub2Opt"
        case HistoryOfRead = "HistoryOfRead"
        case isGb = "isGb"
        case SearchHistory = "SearchHistory"
        case isSn = "isSn"
        case AudioBibleSpeed = "AudioBibleSpeed"
        case AudioBibleVersionIndex = "AudioBibleVersionIndex"
        case AudioBibleLoopMode = "AudioBibleLoopMode"
    }
}

extension FHLUserDefaults{
    fileprivate var p:UserDefaults { UserDefaults.standard }
    fileprivate func p2(_ k:keys)-> String { return k.rawValue }
    
    func getCoreString(_ k:keys)->String? { return p.string(forKey: p2(k))}
    func getCoreInt(_ k:keys)->Int? { return p.integer(forKey: p2(k))}
    func getCoreStringArray(_ k:keys)->[String]? { return p.stringArray(forKey: p2(k))}
    func getCoreFloat(_ k:keys)->Float? { return p.float(forKey: p2(k))}
    func setCore(_ k:keys,_ v:String) { p.set(v, forKey: p2(k)) }
    func setCore(_ k:keys,_ v:Int) { p.set(v, forKey: p2(k)) }
    func setCore(_ k:keys,_ v:[String]) { p.set(v, forKey: p2(k)) }
    func setCore(_ k:keys,_ v:Float) { p.set(v, forKey: p2(k)) }
}
