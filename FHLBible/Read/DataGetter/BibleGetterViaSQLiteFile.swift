//
//  BibleGetterViaSQLiteFile.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/25.
//

import Foundation
import FMDB
import FHLCommon
import OSLog

class BibleGetterViaSQLiteFile : IBibleGetter {
    var logger = Logger(subsystem: "com.FHLBible", category: "BibleGetterViaSQLiteFile")

    private func cvtToDOneLine(_ a1:FMResultSet)->DOneLine{
        let book = a1.int(forColumn: "book")
        let chap = a1.int(forColumn: "chap")
        let sec = a1.int(forColumn: "sec")
        let txt = a1.string(forColumn: "txt")

        let r1 = DOneLine()

        r1.address2 = DAddress(Int(book),Int(chap),Int(sec))
        r1.children = [DText(txt)]
        return r1
    }
    private func bhs_to_utf8_umscode(_ result: [DOneLine]) {
        for i in 0..<result.count {
            var r1 = result[i]
            var r2 = r1.children
            if r2 != nil {
                var r3 = r2! // children!, 是一個 DText Array
                for j in 0..<r3.count {
                    var r4: DText = r3[j]
                    if r4.w != nil {
                        r4.w = umscode(r4.w!)
                    }
                }
            }
        }
    }
    private func fhlwh_to_utf8_gcode(_ result: [DOneLine]) {
        for i in 0..<result.count {
            var r1 = result[i]
            var r2 = r1.children
            if r2 != nil {
                var r3 = r2! // children!, 是一個 DText Array
                for j in 0..<r3.count {
                    var r4: DText = r3[j]
                    if r4.w != nil {
                        r4.w = gcode2(r4.w!)
                    }
                }
            }
        }
    }


    func queryAsync(_ ver: String, _ addr: String, _ fn: @escaping ([DOneLine]) -> Void) {

        let nameRulerOfSQL = SQLNameOfFileAndTableRuler(ver)

        let addrs = StringToVerseRange().main(addr)
        let cmdSelector = SQLSelectBibleTextGenerator().main(
            addresses: addrs,
            nameOfTable: nameRulerOfSQL.nameOfTable,
            isOrderbyId: true)

        let sqlFile = SQLBibles(path: nameRulerOfSQL.pathOfSQL)
        let isSuccess = sqlFile.doSelect(stringOfSQLite: cmdSelector, args: nil) { (a1:FMResultSet) in

            var result :[DOneLine] = []
            while ( a1.next() ){
                result.append(cvtToDOneLine(a1)) // 轉成 DText 基本，不是真正處理與分析，那一步是在下面的 BibleText2DText 才進行
            }

            // 離線資料的 希伯來原文，要另外處理
            if ver == "bhs" {
                bhs_to_utf8_umscode(result)
            }
            // 離線資料的 新約原文，要另外處理
            if ver == "fhlwh" || ver == "lxx" {
                fhlwh_to_utf8_gcode(result)
            }


            let r2 = BibleText2DText().main(result, ver)

            fn(r2)
        }

        if isSuccess == false {
            let r1 = DOneLine()
            r1.children = [ DText("SQLite 查詢失敗") ]
            fn([r1])
        }


    }

    class SQLBibles :  EasySQLiteBase {
        public override var pathToDatabase: URL! {
            get { return self.path }
        }
        var path:URL!
        init(path:URL){
            self.path = path
            super.init()
        }
    }
}
