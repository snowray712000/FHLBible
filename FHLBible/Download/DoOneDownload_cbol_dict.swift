//
//  DoOneDownload_bible_little.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/29.
//

import Foundation
import IJNSwift
import FMDB
extension VCData {
    /// 參考 comment 作出來的，但 comment 是參考 kjv 作出來的
    class DoOneDownload_cbol_dict : DoOneDownload_bible_little {
        override init(){
            super.init()
            if ManagerLangSet.s.curIsGb {
                pathOffline = "/offline/cbol_dict_gb.db"
                pathUnzip = "/unzip/bible_gb_little.db"
                pathDownload = "/download/bible_gb_little.zip"
            } else {
                pathOffline = "/offline/cbol_dict.db"
                pathUnzip = "/unzip/bible_little.db"
                pathDownload = "/download/bible_little.zip"
            }
        }
        override func generateDownload()->IDownload{
            return Download_cbol_dict()
        }
        override func fnNormalizeAsync(_ fn: () -> Void) {
            SQLNormalize_cbol_dict().mainAsync {
                fn()
            }
        }
        class Download_cbol_dict : Download_Base {
            override var linkFromDownload: String { get {
                // 在 little 裡
                if ManagerLangSet.s.curIsGb {
                    return "https://ftp.fhl.net/FHL/COBS/data/bible_gb_little.zip"
                }
                return "https://ftp.fhl.net/FHL/COBS/data/bible_little.zip"
            }}
        }
        /// 正規化這個，花蠻多時間開發的。
        class SQLNormalize_cbol_dict  {
            func mainAsync(_ fn:()->Void){
                mainReCreateTable()
                mainSelectAndInsertDataAsync(fn)
            }
            private func mainReCreateTable(){
                let nameOfTable = "sndict2"
                let cmd = """
                drop table if exists \(nameOfTable);
                
                CREATE TABLE "\(nameOfTable)" (
                    "sn"       INTEGER,
                    "snSuffix" TEXT,
                    "orig"     TEXT,
                    "isOld"    INTEGER,
                    "txt"      TEXT
                );
                """
                
                _ = SQLCBOLDict().doUpdateMore(stringOfSQLite: cmd)
            }
            class DOneSn {
                var sn: Int?
                var snSuffix: String?
                var orig: String?
                var isOld: Int?
                var txt: String?
                
                private func gSQLStringValue(_ str:String?)->String{
                    if str == nil {
                        return "''"
                    }
                    
                    let r1 = str!.replacingOccurrences(of: "'", with: "''")
                    return "'\(r1)'"
                }
                func gInsert()->String{
                    let suf = gSQLStringValue(self.snSuffix)
                    let old = isOld == 1 ? 1 : 0;
                    let orig = gSQLStringValue(self.orig)
                    let txt = gSQLStringValue(self.txt)
                    return """
INSERT INTO sndict2(sn,snSuffix,orig,isOld,txt) VALUES (\(sn!),\(suf),\(orig),\(old),\(txt));
"""
                }
                static var reg = try! NSRegularExpression(pattern: "([\\d]+)([a-zA-Z]*)", options: [])
                static func fromFMResultSet(_ a1: FMResultSet, isOld: Bool)->DOneSn{
                    let r1 = DOneSn()
                    let key1 = isOld ? "hsnum":"gsnum"
                    let hsum = a1.string(forColumn: key1)

                    let snTool = SnSplitSuffix(hsum!)
                    r1.snSuffix = snTool.snSuffix
                    r1.sn = snTool.sn
                    
                    r1.txt   = a1.string(forColumn: "txt")
                    r1.orig  = a1.string(forColumn: "orig")
                    r1.isOld = isOld ? 1 : 0
                    return r1
                }
            }

            class SQLNormalize_BibleLittle : EasySQLiteBase {
                public override var pathToDatabase: URL!{
                    if ManagerLangSet.s.curIsGb {
                        return FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/unzip/bible_gb_little.db")
                    }
                    return FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/unzip/bible_little.db")
                }
            }

            
            private func mainSelectAndInsertDataAsync(_ fn:()->Void){
                _ = SQLNormalize_BibleLittle().doSelect(stringOfSQLite: "select * from hfhl", args: nil) { (a1: FMResultSet) in
                    var records: [DOneSn] = []
                    while a1.next() {
                        records.append( DOneSn.fromFMResultSet(a1, isOld: true) )
                    }

                    _ = SQLNormalize_BibleLittle().doSelect(stringOfSQLite: "select * from gfhl", args: nil) { (a1:FMResultSet) in
                        while a1.next(){
                            records.append( DOneSn.fromFMResultSet(a1, isOld: false) )
                        }
                        
                        let cmds = from(records).select({$0.gInsert()}).toArray()
                        let cmdstr = cmds.joined(separator: "")
                        
                        _ = SQLCBOLDict().doUpdateMore(stringOfSQLite: cmdstr)
                        
                        fn();
                    }
                }
            }
            
        }
    }
}
class SQLCBOLDict : EasySQLiteBase {
    public override var pathToDatabase: URL!{
        if ManagerLangSet.s.curIsGb {
            return FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/offline/cbol_dict_gb.db")
        }
        return FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/offline/cbol_dict.db")
    }
    static func isExist()->Bool{
        return FileManager.default.fileExists(atPath: SQLCBOLDict().pathToDatabase.path)
    }
}
/// 因為 SQL 的 Sn Dict 是正規化的，但是原本的字是 2132a 時，就要切割
class SnSplitSuffix{
    static var reg = try! NSRegularExpression(pattern: "([\\d]+)([a-zA-Z]*)", options: [])
    init(_ snWithSuffix:String){
        main(snWithSuffix)
    }
    var sn: Int!
    /// "" or 'a' 不會是 nil
    var snSuffix: String = ""
    func main(_ snWithSuffix:String){
        let r2 = ijnMatchFirstAndToSubString(Self.reg, snWithSuffix)
        if r2![2] != nil {
            snSuffix = String(r2![2]!)
        } else {
            snSuffix = ""
        }
        
        sn = Int(r2![1]!)
    }
}
