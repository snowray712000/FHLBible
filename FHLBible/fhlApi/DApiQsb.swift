//
//  uiabv.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/16.
//

import Foundation

/// 開發 IDataGetter 時，在 BibleReadDataGetter 中的第1步用到
public func fhlQsb(_ param: String,_ fn: @escaping FhlJson<DApiQsb>.FnCallback) {
    fhlCore(param, "qsb", fn)
}
/// 可直接使用 fhlQsb function
/// 取得經文 qstr 是關鍵參數
open class DApiQsb : FhlJsonResult {
    private enum CodingKeys: String, CodingKey { case record }
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        record = try container.decode([OneRecord].self, forKey: .record)
        
        try super.init(from: decoder)
        
        // Decodable 在 class 繼承時，子類別不如預期的，會轉換成功 https://stackoverflow.com/questions/44553934/using-decodable-in-swift-4-with-inheritance
    }
    
    required public init(_ status: String = "") {
        record = []
        super.init(status)
    }
    public var record : [OneRecord]
    public typealias OneRecord = DApiQsbRecord
}
/// 為了 DApiQsb 存在
public class DApiQsbRecord : Decodable {
    public init(chineses: String? = nil, engs: String, chap: Int, sec: Int, bible_text: String) {
        self.chineses = chineses
        self.engs = engs
        self.chap = chap
        self.sec = sec
        self.bible_text = bible_text
    }
    
    /// 羅
    public var chineses: String?
    /// Rom
    public var engs: String
    public var chap: Int
    public var sec: Int
    public var bible_text: String
}
