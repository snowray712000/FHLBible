//
//  BibleGetterViaSQLiteFile.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/25.
//

import Foundation
import IJNSwift
import FMDB



class BibleGetterViaSQLiteFile : IBibleGetter {
    private func cvtToDOneLine(_ a1:FMResultSet)->DOneLine{
        let book = a1.int(forColumn: "book")
        let chap = a1.int(forColumn: "chap")
        let sec = a1.int(forColumn: "sec")
        let txt = a1.string(forColumn: "txt")
        
        let r1 = DOneLine()
        
        r1.address2 = DAddress(book,chap,sec)
        r1.children = [DText(txt)]
        return r1
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
                result.append(cvtToDOneLine(a1))
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
