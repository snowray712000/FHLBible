//
//  SQLNormalize_unv_gb.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/28.
//

import Foundation
import IJNSwift

class SQLNormalize_sn_kjv : EasySQLiteBase {
    public override var pathToDatabase: URL!{
        return FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/offline/sn_kjv.db")
    }
    func main(){
        let fm = FileManager.default
        _ = fm.makeSureDirExistAtDocumentUserDomain(dirName: "offline")
        
        // 3個分號，很適合用
        let cmd = SQLBibleTextTransfor().generateCommand(
            nameOfTableOfGenerator: "sn_kjv2",
            nameOfTableOfSource: "kjv",
            pathOfRelativeOfUnzipFile: "/unzip/bible_kjv.db")
        
        _ = doUpdateMore(stringOfSQLite: cmd)
    }
}
