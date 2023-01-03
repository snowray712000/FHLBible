//
//  SQLNormalize_unv_gb.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/28.
//

import Foundation
import IJNSwift

/// 重構: 相似程式碼。
class SQLBibleTextTransfor: NSObject {
    
    /// nameTable: 例子 unv2 nstrunv2
    func generateCommand(
        nameOfTableOfGenerator unv2:String,
        nameOfTableOfSource unv:String,
        pathOfRelativeOfUnzipFile path:String)->String{
        // attch 要用到的參數，不能用相對路徑
        let path_db = fm.getPathAtDocumentUserDomain(pathRelative: path) // /unzip/bible_little.db
        
            // 3個分號，很適合用
        let cmd = """
        drop table if exists \(unv2);
        CREATE TABLE "\(unv2)" (
            "id"    INTEGER,
            "book"    INTEGER,
            "chap"    INTEGER,
            "sec"    INTEGER,
            "txt"    TEXT
        );
        
        attach database "\(path_db)" as db2;
        attach database "\(pathMainDb)" as db3;
        insert into \(unv2)(id,book,chap,sec,txt) select A.id,B.id,A.chap,A.sec,A.txt from db2.\(unv) as A left join db3.main as B on A.engs = B.engs;
        """
        
        return cmd
    }
    private lazy var fm = FileManager.default
    private lazy var pathMainDb = fm.getPathAtDocumentUserDomain(pathRelative: "/offline/main.db")
}
