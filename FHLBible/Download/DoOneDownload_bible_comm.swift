//
//  DoOneDownload_bible_little.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/29.
//

import Foundation
import IJNSwift

extension VCData {
    /// 參考 kjv 作出來的
    /// //cbol=1 isa=2 tcomm=3 tsk=4 rwp=6 蔡茂堂=8 樹枝圖=7 盧俊義=9 康來昌=10 盧俊義導讀台語=21 盧俊義導讀華語=20  動物字典=30 植物字典=31 人造物品字>典=32 綜合字典=33
    class DoOneDownload_comm : DoOneDownload_bible_little {
        override init(){
            super.init()
            if ManagerLangSet.s.curIsGb {
                pathOffline = "/offline/comm_gb.db"
                pathUnzip = "/unzip/bible_gb_comm.db"
                pathDownload = "/download/bible_gb_comm.zip"
            } else {
                pathOffline = "/offline/comm.db"
                pathUnzip = "/unzip/bible_comm.db"
                pathDownload = "/download/bible_comm.zip"
            }
        }
        override func generateDownload()->IDownload{
            return Download_comm()
        }
        override func fnNormalize(){
            SQLNormalize_comm().main()
        }
        class Download_comm : Download_Base {
            /// 可能是 lcc 或 lcc_gb
            override var idOfSession: String { get {
                if ManagerLangSet.s.curIsGb{
                    return "gb_comm"
                }
                return "comm"
                
            }}
        }
        class SQLNormalize_comm : EasySQLiteBase {
            public override var pathToDatabase: URL!{
                if ManagerLangSet.s.curIsGb {
                    return FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/offline/comm_gb.db")
                }
                return FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/offline/comm.db")
            }
            
            func main(){
                let fm = FileManager.default
                _ = fm.makeSureDirExistAtDocumentUserDomain(dirName: "offline")
                
                // attch 要用到的參數，不能用相對路徑
                var path_db = fm.getPathAtDocumentUserDomain(pathRelative: "/unzip/bible_comm.db") // /unzip/bible_little.db
                let pathMainDb = fm.getPathAtDocumentUserDomain(pathRelative: "/offline/main.db")
                let unv2 = "comment2"
                let unv = "comment"
                if ManagerLangSet.s.curIsGb {
                    path_db = fm.getPathAtDocumentUserDomain(pathRelative: "/unzip/bible_gb_comm.db") // /unzip/bible_little.db
                }
                
                    // 3個分號，很適合用
                let cmd = """
                drop table if exists \(unv2);
                
                CREATE TABLE "\(unv2)" (
                    "id" INTEGER,
                    "book"    INTEGER,
                    "bchap"    INTEGER,
                    "bsec"    INTEGER,
                    "echap"    INTEGER,
                    "esec"    INTEGER,
                    "tag"    INTEGER,
                    "txt"    TEXT
                );
                
                attach database "\(path_db)" as db2;
                attach database "\(pathMainDb)" as db3;
                insert into \(unv2)(id,book,bchap,bsec,echap,esec,tag,txt) select A.id,B.id,A.bchap,A.bsec,A.echap,A.esec,A.tag,A.txt from db2.\(unv) as A left join db3.main as B on A.engs = B.engs;
                """
                
                _ = doUpdateMore(stringOfSQLite: cmd)
            }
        }
    }
}
