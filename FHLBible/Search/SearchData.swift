//
//  SearchData.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/23.
//

import Foundation

public class SearchData {
    public var curGroup: String = ""
    public var curOpt: String = ""
    public var datas: [[DOneLine]] = []
    public var vers: [DOneLine] = []
    public var filters: [Filter] = []
    
    /// 繪圖 filter 上的按鈕，對應的資料
    public class Filter {
        /// 彼前 or 保羅書信 (可能是簡體字)
        public var na = ""
        public var cnt = -1
        /// 書卷 分類 2種可能
        public var na2 = "" // 分類
        public var w: String { return "\(na) \(cnt)"}
        
        public init(_ na:String,_ cnt:Int,_ na2:String = "") {
            self.na = na
            self.cnt = cnt
            self.na2 = na2
        }
    }
}
