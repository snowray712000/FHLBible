//
//  Unzipor.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/28.
//

import Foundation

class Unzipor : NSObject {
    func main(pathZip: URL){
        let fm = FileManager.default
        let dir2 = fm.makeSureDirExistAtDocumentUserDomain(dirName: "unzip")
        //let pathZip = fm.getPathAtDocumentUserDomain(pathRelative: pathZip)
        do{
            try fm.unzipItem(at: pathZip, to: dir2) // /unzip/bible_little.db
        }catch{
            print(error.localizedDescription)
        }
    }
}
