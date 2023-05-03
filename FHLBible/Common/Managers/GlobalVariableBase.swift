//
//  GlobalVariableBase.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/10.
//

import Foundation


/// cur 雖然想用 T 而非 T?, 但因為 String 沒有 init()，會過不了
/// 首先，在 FHLUserDefaults 新增一個 keys
/// 然後，繼承後對應的型別後，然後過載 .tp
/// 過載(選擇性) _getDefaultXXXXXX 、
/// 過載(選擇性) isTheSame...這樣 updateCur 就可以避免，新的與舊的一樣的時候，又 trigger 一次沒必要的
class GlobalVariableBase<T:Equatable> : NSObject{
    var cur: T? { _cur }
    var old: T? { _old }
    var curChanged$: IjnEventAny = IjnEvent()
    func updateCur(_ v:T){
        if false == _isTheSame(_old, v) {
            _old = _cur
            _cur = v
            self._updateToUserDefault(_cur!)
            curChanged$.trigger()
        }
    }
    override init() {
        super.init()
        _cur = _getFromUserDefault()
    }
    internal var _tp: FHLUserDefaults.keys { .None }
    internal var _cur: T? = nil
    internal var _old: T? = nil
    internal func _updateToUserDefault(_ v:T){}
    internal func _getFromUserDefault()->T {return _cur!}
    internal func _isTheSame(_ o1:T?,_ o2: T?)->Bool { return false }
}
class GlobalVariableStringBase : GlobalVariableBase<String> {
    internal var _getDefaultString:String { "" }
    override func _isTheSame(_ o1: String?, _ o2: String?) -> Bool { return o1 == o2 }
    override func _getFromUserDefault() -> String {
        return FHLUserDefaults.s.getCoreString(_tp) ?? _getDefaultString
    }
    override func _updateToUserDefault(_ v: String) {
        FHLUserDefaults.s.setCore(_tp, v)
    }
}
class GlobalVariableIntBase : GlobalVariableBase<Int> {
    internal var _getDefaultInt:Int { -1 }
    override func _isTheSame(_ o1: Int?, _ o2: Int?) -> Bool { return o1 == o2 }
    override func _getFromUserDefault() -> Int {
        return FHLUserDefaults.s.getCoreInt(_tp) ?? _getDefaultInt
    }
    override func _updateToUserDefault(_ v: Int) {
        FHLUserDefaults.s.setCore(_tp, v)
    }
}
class GlobalVariableFloatBase : GlobalVariableBase<Float> {
    internal var _getDefaultFloat:Float { 0 }
    override func _isTheSame(_ o1: Float?, _ o2: Float?) -> Bool { return o1 == o2 }
    override func _getFromUserDefault() -> Float {
        return FHLUserDefaults.s.getCoreFloat(_tp) ?? _getDefaultFloat
    }
    override func _updateToUserDefault(_ v: Float) {
        FHLUserDefaults.s.setCore(_tp, v)
    }
}
class GlobalVariableStringArrayBase : GlobalVariableBase<[String]> {
    internal var _getDefaultStringArray:[String] { [] }
    override func _isTheSame(_ o1: [String]?, _ o2: [String]?) -> Bool {
        if o1 == nil && o2 == nil { return true }
        if o1 == nil || o2 == nil { return false }
        if o1!.count != o2!.count { return false }
        return ijnRange(0, o1!.count).ijnAll({o1![$0]==o2![$0]})
    }
    override func _getFromUserDefault() -> [String] {
        return FHLUserDefaults.s.getCoreStringArray(_tp) ?? _getDefaultStringArray
    }
    override func _updateToUserDefault(_ v: [String]) {
        FHLUserDefaults.s.setCore(_tp, v)
    }
}
