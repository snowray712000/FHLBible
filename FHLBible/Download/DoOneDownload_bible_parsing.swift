//
//  DoOneDownload_bible_little.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/29.
//

import Foundation
import IJNSwift

extension VCData {
    /// 參考 comment 作出來的，但 comment 是參考 kjv 作出來的
    class DoOneDownload_parsing : DoOneDownload_bible_little {
        override init(){
            super.init()
            if ManagerLangSet.s.curIsGb {
                pathOffline = "/offline/parsing_gb.db"
                pathUnzip = "/unzip/bible_gb_parsing.db"
                pathDownload = "/download/bible_gb_parsing.zip"
            } else {
                pathOffline = "/offline/parsing.db"
                pathUnzip = "/unzip/bible_parsing.db"
                pathDownload = "/download/bible_parsing.zip"
            }
        }
        override func generateDownload()->IDownload{
            return Download_parsing()
        }
        override func fnNormalize(){
            SQLNormalize_parsing().main()
        }
        class Download_parsing : Download_Base {
            /// 可能是 lcc 或 lcc_gb
            override var idOfSession: String { get {
                if ManagerLangSet.s.curIsGb{
                    return "gb_parsing"
                }
                return "parsing"
                
            }}
        }
        class SQLNormalize_parsing : EasySQLiteBase {
            public override var pathToDatabase: URL!{
                if ManagerLangSet.s.curIsGb {
                    return FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/offline/parsing_gb.db")
                }
                return FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/offline/parsing.db")
            }
            func main(){
                mainOldTestment()
                mainNewTestment()
            }
            private func mainNewTestment(){
                self.mainCore("fhlwhparsing", "fhlwhparsing2")
            }
            private func mainOldTestment(){
                self.mainCore("lparsing", "lparsing2")
            }
            /// tableName: 'unv' tableName2: 'unv2'
            private func mainCore(_ tableName:String,_ tableName2:String){
                let fm = FileManager.default
                _ = fm.makeSureDirExistAtDocumentUserDomain(dirName: "offline")
                
                // attch 要用到的參數，不能用相對路徑
                var path_db = fm.getPathAtDocumentUserDomain(pathRelative: "/unzip/bible_parsing.db") // /unzip/bible_little.db
                let pathMainDb = fm.getPathAtDocumentUserDomain(pathRelative: "/offline/main.db")
                let unv2 = tableName2
                let unv = tableName
                if ManagerLangSet.s.curIsGb {
                    path_db = fm.getPathAtDocumentUserDomain(pathRelative: "/unzip/bible_gb_parsing.db") // /unzip/bible_little.db
                }
                
                    // 3個分號，很適合用
                let cmd = """
                drop table if exists \(unv2);
                
                CREATE TABLE "\(unv2)" (
                    "id" INTEGER,
                    "book"    INTEGER,
                    "chap"    INTEGER,
                    "sec"     INTEGER,
                    "wid"     INTEGER,
                    "word"    TEXT,
                    "sn"      TEXT,
                    "pro"     TEXT,
                    "wform"   TEXT,
                    "orig"    TEXT,
                    "exp"     TEXT,
                    "remark"  TEXT
                );
                
                attach database "\(path_db)" as db2;
                attach database "\(pathMainDb)" as db3;
                insert into \(unv2)(id,book,chap,sec,wid,word,sn,pro,wform,orig,exp,remark) select A.id,B.id,A.chap,A.sec,A.wid,A.uword,A.sn,A.pro,A.wform,A.uorig,A.exp,A.remark from db2.\(unv) as A left join db3.main as B on A.engs = B.engs;
                """
                
                _ = doUpdateMore(stringOfSQLite: cmd)
            }
            
        }
    }
}
