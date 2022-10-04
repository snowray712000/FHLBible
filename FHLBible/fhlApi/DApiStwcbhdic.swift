//
//  uiabv.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/11/3.
// 請參考 qsb 實作新的, 這個也是參考那個作的
import Foundation

/// 浸宣舊約字典
/// k=03615&gb=0&N=1
func fhlStwcbhdic(_ param: String,_ fn: @escaping FhlJson<DApiStwcbhdic>.FnCallback) {
    fhlCore(param, "stwcbhdic", fn)
}

class DApiStwcbhdic : DApiSbdBase {}
