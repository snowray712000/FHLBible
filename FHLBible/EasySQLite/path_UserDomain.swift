//
//  File.swift
//
//
//  Created by littlesnow on 2022/10/28.
//

import Foundation

extension FileManager {
    /// 當時是為了處理`離線版本聖經`時作的。
    /// 解壓縮時，它不會自動路徑不存在就產生，要 `手動產生` 才行
    open func makeSureDirExistAtDocumentUserDomain(dirName dir:String) -> URL{
        // let r2 = getPathAtDocumentUserDomain(pathRelative: "/\(dir)")
        let r2 = getPathAtDocumentUserDomain(pathRelative: "\(dir)")
        if self.fileExists(atPath: r2.path) == false{
            do{
                try self.createDirectory(at: r2, withIntermediateDirectories: true, attributes: nil)
            }catch{
                print(error.localizedDescription)
            }
        }
        return r2.standardized
    }
    /// 當時是為了處理`離線版本聖經`時作的。download unzip offline 資料都在這裡
    /// 取得能夠存取的 `SandBox` 路徑。
    open func getPathAtDocumentUserDomain(pathRelative path:String) -> URL{
        let r1 = self.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return r1.appendingPathComponent(path)
    }
}
