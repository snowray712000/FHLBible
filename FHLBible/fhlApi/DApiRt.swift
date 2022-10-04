//
//  uiabv.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/11/3.
// 請參考 qsb 實作新的, 這個也是參考那個作的
import Foundation

/// https://bible.fhl.net/json/rt.php?engs=Matt&chap=1&version=cnet&id=1
func fhlRt(_ param: String,_ fn: @escaping FhlJson<DApiRt>.FnCallback) {
    fhlCore(param, "rt", fn)
}

class DApiRt : FhlJsonResult {
    enum CodingKeys: String,  CodingKey {
        case record
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        record = try container.decode([OneRecord].self, forKey: .record)
        try super.init(from: decoder)
    }
    required init(_ status: String = "") {
        record = []
        super.init(status)
    }
    
    var record: [OneRecord]
    typealias OneRecord = DApiRtRecord
}

class DApiRtRecord : Decodable {
    var text: String?
    var id: Int?
}

