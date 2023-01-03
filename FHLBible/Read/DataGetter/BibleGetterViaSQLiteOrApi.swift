//
//  File.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/9/10.
//

import Foundation
import IJNSwift
import FMDB

class BibleGetterViaSQLiteOrApi : NSObject, IBibleGetter {
    func queryAsync(_ ver: String, _ addr: String, _ fn: @escaping ([DOneLine]) -> Void) {
        if isExistSQLite(ver) {
            print("using sql \(ver)")
            BibleGetterViaSQLiteFile().queryAsync(ver, addr, fn)
        } else {
            print("using api \(ver)")
            BibleGetterViaFhlApiQsb().queryAsync(ver, addr, fn)
        }
    }
    private func isExistSQLite(_ ver:String)->Bool {
        return FileManager.default.fileExists(atPath: SQLNameOfFileAndTableRuler(ver).pathOfSQL.path)
    }
}
