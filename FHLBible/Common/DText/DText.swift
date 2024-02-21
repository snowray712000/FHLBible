//
//  DText.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/22.
//

import Foundation
import FHLCommon

public class BibleBookNames {
    public static func getBookName(_ id:Int,_ tp: BookNameLang) -> String {
        return get_booknames_via_tp(tp: tp)[id-1]
    }
    public static func getBookNames(_ tp:BookNameLang) -> [String] {
        return get_booknames_via_tp(tp: tp)
    }
}

//class BibleBookNameToId {
//    /// 若沒有找到，回傳 -1
//    /// 已經優化過效率，是用 dictionary，並且作為 static 了。
//    func main1based(_ tp: BookNameLang,_ str: String)-> Int {
//        var r1 = Self.dicts[tp]
//        if r1 == nil {
//            r1 = generateOneDict(tp)
//            Self.dicts[tp] = r1!
//        }
//
//        let r2 = r1![str]
//        return r2 != nil ? r2! : -1
//
//        //let r1 =  BibleBookNames.getBookNames(tp)
//        //let r2 = r1.ijnIndexOf(str)
//        //return r2 != nil ? r2! + 1 : -1
//    }
//    /// na : bookId
//    typealias OneDict = [String:Int]
//    static var dicts: [BookNameLang : OneDict ] = [:]
//
//    func generateOneDict(_ tp:BookNameLang)->OneDict{
//        let r2 = BibleBookNames.getBookNames(tp)
//        var re: OneDict = [:]
//        for (i,a2) in r2.enumerated() {
//            re[a2] = i + 1 // 1-based
//        }
//        return re
//    }
//}

//public class DOneLine : Equatable {
//    public init(addresses: String? = nil, children: [DText]? = nil, ver: String? = nil) {
//        self.addresses = addresses
//        self.children = children
//        self.ver = ver
//    }
//    
//    /// 為了 unit test 增加的 XCTAssertEqual QsbRecords2DOneLinesTests
//    /// 若其中一個 ver 是 nil, ver 則忽略
//    /// 若其中一個 addresses 是 nil, addresses 則忽略
//    public static func == (lhs: DOneLine, rhs: DOneLine) -> Bool {
//        if lhs.ver != nil && rhs.ver != nil && lhs.ver != rhs.ver {
//            return false
//        }
//        if lhs.addresses != nil && rhs.addresses != nil && lhs.addresses != rhs.addresses {
//            return false
//        }
//        if lhs.children == nil && rhs.children == nil {
//            return true
//        }
//        if lhs.children == nil { // 只有一個 children 是 nil
//            return false
//        }
//        if rhs.children == nil {
//            return false
//        }
//        return lhs.children! == rhs.children!
//    }
//    /// 效率考量，set 時，不會去同時設 2 版本
//    /// get 以 addresses 為主，若沒有，才會從 2 版本嘗試取得。
//    public var addresses : String? {
//        set {
//            _addresses = newValue
//        }
//        get {
//            if _addresses == nil && (_address2 != nil || _addresses2 != nil) {
//                if _addresses2 != nil {
//                    return VerseRangeToString().main(_addresses2!, .Matt)
//                }
//                if _address2 != nil {
//                    let cht = BibleBookNames.getBookName(_address2!.book, ManagerLangSet.s.curTpBookNameLang)
//                    return "\(cht)\(_address2!.chap):\(_address2!.verse)"
//                }
//            }
//            
//            return _addresses
//        }
//    }
//    public var children : [DText]?
//    public var ver : String?
//    
//    /// set 時，只會設 2 版本的
//    /// get 時，先以 2 版本的為主，若沒有，會嘗試從 1 版本的取得
//    var address2: DAddress? {
//        set {
//            _address2 = newValue
//        }
//        get {
//            if _address2 != nil {
//                return _address2
//            }
//            if _addresses2 != nil && _addresses2!.count != 0{
//                return _addresses2!.first!
//            }
//            if _addresses != nil {
//                let r1 = StringToVerseRange().main(_addresses!)
//                if r1.count != 0 {
//                    return r1.first!
//                }
//            }
//            
//            return _address2
//        }
//    }
//    /// set 時，只會設 2 版本的
//    /// get 時，先以 2 版本的為主，若沒有，會嘗試從 1 版本的取得
//    var addresses2: [DAddress]? {
//        set {
//            _addresses2 = newValue
//        }
//        get {
//            if _addresses2 != nil {
//                return _addresses2!
//            }
//            if _address2 != nil {
//                return [_address2!]
//            }
//            if _addresses != nil {
//                let r1 = StringToVerseRange().main(_addresses!)
//                if r1.count != 0 {
//                    return r1
//                }
//            }
//            
//            return _addresses2
//        }
//    }
//    
//    /// 保持原本的
//    private var _addresses: String?
//    /// 若來源是這個, 會較有效率, 有時候
//    private var _address2: DAddress?
//    /// 若來源是這個, 會較有效率, 有時候
//    private var _addresses2: [DAddress]?
//    
//}
