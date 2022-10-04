//
//  uiabv.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/11/3.
// 請參考 qsb 實作新的, 這個也是參考那個作的
import Foundation



/// book=4&engs=Gen&gb=0&chap=2&sec=1
func fhlSc(_ param: String,_ fn: @escaping FhlJson<DApiSc>.FnCallback) {
    fhlCore(param, "sc", fn)
}
class DApiScRecord : Decodable {
    var title: String? // 創世記 2章1節 到 2章1節
    var book_name: String? // 串珠
    var com_text: String? // 內容
}

class DApiSc : FhlJsonResult {
    fileprivate enum CodingKeys: String,  CodingKey {
        case record
        /// book: "4" engs: "Gen" chap: 1 sec: 31
        case prev
        /// book: "4" engs" Gen" chap: 2 sec: 2
        case next
    }
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        record = try container.decode([OneRecord].self, forKey: .record)
        prev = try? container.decode(PrevNext.self, forKey: .prev)
        next = try? container.decode(PrevNext.self, forKey: .next)
        
        try super.init(from: decoder)
        
        // Decodable 在 class 繼承時，子類別不如預期的，會轉換成功 https://stackoverflow.com/questions/44553934/using-decodable-in-swift-4-with-inheritance
    }
    
    required public init(_ status: String = "") {
        record = []
        super.init(status)
    }
    var record : [OneRecord] = []
    typealias OneRecord = DApiScRecord
    var prev: PrevNext? = nil
    var next: PrevNext? = nil
    class PrevNext : Decodable {
        /// "4" 指的是 串珠
        var book: String? = ""
        var engs: String? = ""
        var chap: Int? = 0
        var sec: Int? = 0
        
        /// engs nil 就回傳 nil
        func toAddress()->DAddress?{
            if engs == nil {
                return nil
            }
            let r1 = BibleBookNameToId().main1based(.Matt, engs!)
            if chap == nil {
                return DAddress(r1,1,1)
            }
            if sec == nil {
                return DAddress(r1,chap!,1)
            }
            return DAddress(r1,chap!,sec!)
        }
    }
    
}
