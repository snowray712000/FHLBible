//
//  SnHelper.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/17.
//

import Foundation
/// 一個文字，協助判斷它是一般文字，還是它其實是 G3212 H231 之類的 Sn 文字
/// 這個原本存在於 search 功能開發過程。但上色也用到，所以將它抽出來
class SnHelper : NSObject {
    func main(_ keyword:String) {
        _keyword = keyword
        
        self._resetResult()
        self._determineKeyword()
    }
    /// 若是Sn 會回傳 G321 H412 ，若不是，回傳原本的字
    var keyword: String { _sn == nil ? _keyword : _tp! + _sn! }
    /// sn 值, 若 0412 會是  412, 也支援 412a 這樣的 Sn (因為有 a 為結尾的 Sn)
    var sn: String? { _sn }
    /// G or H
    var snTp: String? { _tp }
    
    /// 原本的值
    private var _keyword: String!
    /// 若是 sn 會把數字解析出來
    private var _sn: String?
    /// 若是 sn，它是 tp 什麼？是  G 或 H
    private var _tp: String?
    
    private func _determineKeyword(){
        var r1 = ijnMatchFirstAndToSubString(Self._regH, _keyword)
        if r1 != nil {
            _tp = "H"
            _sn = String ( r1![1]! )
            return
        }
        r1 = ijnMatchFirstAndToSubString(Self._regG, _keyword)
        if r1 != nil {
            _tp = "G"
            _sn = String ( r1![1]! )
            return
        }
    }
    private func _resetResult (){
        _sn = nil
        _tp = nil
    }
    static var _regG = try! NSRegularExpression(pattern: #"G0*([\d]+[a-z]?)"#, options: [.caseInsensitive])
    static var _regH = try! NSRegularExpression(pattern: #"H0*([\d]+[a-z]?)"#, options: [.caseInsensitive])
}
