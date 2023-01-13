//
//  SQLNormalize_unv_gb.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/28.
//

import Foundation
import IJNSwift

class SQLNormalize_unv_gb : EasySQLiteBase {
    public override var pathToDatabase: URL!{
        return FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/offline/unv_gb.db")
    }
    func main(){
        let fm = FileManager.default
        _ = fm.makeSureDirExistAtDocumentUserDomain(dirName: "offline")
        
        // 3個分號，很適合用
        let cmd = SQLBibleTextTransfor().generateCommand(
            nameOfTableOfGenerator: "unv_gb2",
            nameOfTableOfSource: "nstrunv",
            pathOfRelativeOfUnzipFile: "/unzip/bible_gb_little.db")
        
        _ = doUpdateMore(stringOfSQLite: cmd)
    }
}
