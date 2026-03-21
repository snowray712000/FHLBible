//
//  Unzipor.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/28.
//

import Foundation
import OSLog
class Unzipor : NSObject {
    var logger = Logger(subsystem: "com.FHLBible", category: "Unzipor")

    func main(pathZip: URL){
        let fm = FileManager.default
        let dir2 = fm.makeSureDirExistAtDocumentUserDomain(dirName: "unzip")
        //let pathZip = fm.getPathAtDocumentUserDomain(pathRelative: pathZip)
        do{
            try fm.unzipItem(at: pathZip, to: dir2) // /unzip/bible_little.db
        }catch{
            logger.error("\(error.localizedDescription)")
        }
    }
}
