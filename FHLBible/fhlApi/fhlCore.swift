//
//  fhlCore.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/10.
//

import Foundation

/// fhlQsb fhlQp fhlSc 都長一樣，所以加這個
/// apiPrefix 就是 qsb qp sc
/// param 是不包含 ? 的
func fhlCore<T: FhlJsonResult>(_ param:String, _ apiPrefix:String,_ fn: @escaping FhlJson<T>.FnCallback){
    FhlJson<T>().postAsync(fn, "https://bible.fhl.net/json/\(apiPrefix).php", param)
}
