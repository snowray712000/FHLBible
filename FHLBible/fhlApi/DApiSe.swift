//
//  uiabv.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/11/3.
// 請參考 qsb 實作新的, 這個也是參考那個作的
import Foundation

/// 以下是舊約超過500筆的例子(前2個與最後1個)
/// index_only=1&limit=500&offset=0&orig=2&RANGE=2&q=430
/// index_only=1&limit=500&offset=500&orig=2&RANGE=2&q=430
/// index_only=1&limit=500&offset=2000&orig=2&RANGE=2&q=430
/// 以下是關鍵字超過500筆的例子
/// orig=0&VERSION=unv&index_only=1&limit=500&offset=0&q=摩西&gb=0
/// 以下是2個關鍵字的例子
/// orig=0&VERSION=unv&index_only=1&limit=500&offset=0&q=摩西 亞倫&gb=0
func fhlSe(_ param: String,_ fn: @escaping FhlJson<DApiSe>.FnCallback) {
    fhlCore(param, "se", fn)
}

class DApiSe : FhlJsonResult {
    enum CodingKeys: String,  CodingKey {
        case record
        case orig
        case key
        case record_count
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        record = try container.decode([OneRecord].self, forKey: .record)
        record_count = try? container.decode(Int.self, forKey: .record_count)
        orig = try? container.decode(String.self, forKey: .orig)
        key = try? container.decode(String.self, forKey: .key)
        
        try super.init(from: decoder)
    }
    required init(_ status: String = "") {
        record = []
        super.init(status)
    }
    
    var record: [OneRecord]
    typealias OneRecord = DApiSeRecord
    
    /// 2 是舊約彙編 1是新約 0 是關鍵字
    var orig: String?
    /// 只有數字
    var key: String?
    /// 500 是一次的上限
    var record_count: Int?
}

class DApiSeRecord : Decodable {
    /// 雖有回傳, 但用 engs, chap, sec 即可
    // var id: Int?
    /// 雖有回傳, 但用 engs 即可
    // var chineses: String?
    var engs: String?
    var chap: Int?
    var sec: Int?
}

