//
//  SQLNormalize_unv_gb.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/28.
//

import Foundation
import IJNSwift

class SQLNormalizeBase : EasySQLiteBase {
    /// override
    /// e.g. `lcc or lcc_gb`
    var version : String { get { return "asv" }}
    
    // unv.db sn_unv.db unv_gb.db sn_unv_gb.db
    public override var pathToDatabase: URL!{
        return FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/offline/\(version).db")
    }
    func main(){
        assert( fm.fileExists(atPath: fm.getPathAtDocumentUserDomain(pathRelative: "/offline/main.db").path) )
        
        _ = fm.makeSureDirExistAtDocumentUserDomain(dirName: "offline")
        
        let ver = version
        if ver.substring_end(count: 3) == "_gb" {
            let verNogb = String( ver.substring(offsetFromEnd: -3) )
            let cmd = SQLBibleTextTransfor().generateCommand(
                nameOfTableOfGenerator: "\(version)2",
                nameOfTableOfSource: verNogb,
                pathOfRelativeOfUnzipFile: "/unzip/bible_\(verNogb).db")
            
            _ = doUpdateMore(stringOfSQLite: cmd)
        } else {
            let cmd = SQLBibleTextTransfor().generateCommand(
                nameOfTableOfGenerator: "\(ver)2",
                nameOfTableOfSource: ver, //
                pathOfRelativeOfUnzipFile: "/unzip/bible_\(ver).db")
            
            _ = doUpdateMore(stringOfSQLite: cmd)
        }
    }
    lazy var fm = FileManager.default
}
/// `重構味道` 取代了下面那群
/// tp2 這名稱，是因為是先重構 DoOneDownload_bible_tp2；它們是成對的，所以也叫 tp2
class SQLNormalizeBase_tp2 : SQLNormalizeBase{
    init(_ ver:String){
        _ver = ver
        super.init()
    }
    private var _ver:String
    override var version: String { get { return _ver }}
}
//class SQLNormalize_asv : SQLNormalizeBase {
//    override var version: String { get { return "asv" }}
//}
//class SQLNormalize_darby : SQLNormalizeBase {
//    override var version: String { get { return "darby" }}
//}
//class SQLNormalize_bbe : SQLNormalizeBase {
//    override var version: String { get { return "bbe" }}
//}
