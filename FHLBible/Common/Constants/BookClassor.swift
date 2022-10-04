//
//  BookClassor.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/13.
//

import Foundation

/// 搜尋結果，統計分類
class BibleBookClassor {
    /// 使徒行傳加到福音書(畢竟是路加寫的下集)
    /// 希伯來書加在這56
    static let _dictNa2Cnt: [String:[Int]] = [
        "全部" : ijnRange(1, 66),
        "舊約" : ijnRange(1, 39),
        "新約" : ijnRange(40, 27),
        "摩西五經" : ijnRange(1, 5),
        "歷史書" : ijnRange(6, 12),
        "詩歌智慧書" : ijnRange(18, 5),
        "大先知書" : ijnRange(23, 5),
        "小先知書" : ijnRange(28, 12),
        "福音書" : ijnRange(40, 5),
        "保羅書信" : ijnRange(45, 13),
        "其它書信" : ijnRange(58, 9),
    ]
    /// 因為 dict 會改變 order, 所以 dictNa2Cnt For each 是不會按順序的
    static let _orderNa: [String] = [
        "全部","舊約","新約","摩西五經","歷史書","詩歌智慧書","大先知書","小先知書","福音書","保羅書信","其它書信"]
    static let _dictNa2CntGB: [String:[Int]] = [
        "全部" : ijnRange(1, 66),
        "旧约" : ijnRange(1, 39),
        "新约" : ijnRange(40, 27),
        "摩西五经" : ijnRange(1, 5),
        "历史书" : ijnRange(6, 12),
        "诗歌智慧书" : ijnRange(18, 5),
        "大先知书" : ijnRange(23, 5),
        "小先知书" : ijnRange(28, 12),
        "福音书" : ijnRange(40, 5),
        "保罗书信" : ijnRange(45, 13),
        "其它书信" : ijnRange(58, 9),
    ]
    static let _orderNaGB: [String] = [
        "全部","旧约","新约","摩西五经","历史书","诗歌智慧书","大先知书","小先知书","福音书","保罗书信","其它书信",]
    
}
