//
//  uiabv.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/11/3.
// 請參考 qsb 實作新的, 這個也是參考那個作的
import Foundation

/// 浸宣新約字典
/// k=03615&gb=0&N=0
func fhlSbdag(_ param: String,_ fn: @escaping FhlJson<DApiSbdag>.FnCallback) {
    fhlCore(param, "sbdag", fn)
}
class DApiSbdBaseRecord : Decodable {
    var sn:String?
    var dic_text:String?
}
class DApiSbdag : DApiSbdBase {}


/// 因為 DApiSbdag 、 DApiStwcbhdic  根本一模一樣，所以抽出來
class DApiSbdBase : FhlJsonResult {
    enum CodingKeys: String,  CodingKey {
        case record
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        record = try container.decode([OneRecord].self, forKey: .record)
        record.forEach({$0.sn = removeSn000($0.sn)})
        
        try super.init(from: decoder)
    }
    required init(_ status: String = "") {
        record = []
        super.init(status)
    }
    var record: [OneRecord]
    typealias OneRecord = DApiSbdBaseRecord
}
