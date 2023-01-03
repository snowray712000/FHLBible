//
//  SwiftFileManager_Extensions.swift
//  FHLBible
//
//  Created by littlesnow on 2022/11/2.
//

import Foundation
extension FileManager {
    func sizeOfFile(atPath path: String) -> Int64? {
        guard let attrs = try? attributesOfItem(atPath: path) else {
            return nil
        }

        return attrs[.size] as? Int64
    }
    func dateOfLastModified(atPath path:String) -> Date? {
        guard let attrs = try? attributesOfItem(atPath: path) else {
            return nil
        }

        return attrs[.modificationDate] as? Date
    }
}
