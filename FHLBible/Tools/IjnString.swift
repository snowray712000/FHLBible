//
//  IjnString.swift
//  FHLBible
//
//  Created by littlesnow on 2022/11/21.
//

import Foundation

extension String {
    /// `lcc_gb` 拿掉後面 3 個字元，就傳入 -3
    func substring(offsetFromEnd:Int)->Substring{
        return self.prefix(upTo: self.index(self.endIndex, offsetBy: offsetFromEnd))
    }
    /// `lcc_gb` 傳入 3，就得 `_gb`
    /// 其實就是呼叫 suffix(count)
    func substring_end(count:Int)->Substring{
        return self.suffix(count)
    }
}
