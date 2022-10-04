import Foundation
import UIKit

/// 若沒有換行符號，就是 [str]，也就是 count = 1
/// 空白的會被拿掉，\r \n 都會被視為換行
/// https://stackoverflow.com/questions/32021712/how-to-split-a-string-by-new-lines-in-swift
public func splitByNewLines(str: String)->[String]{
    /// 沒有 filter 會使 \r\n 中間多一個空白
    return str.components(separatedBy: CharacterSet.newlines).filter({!$0.isEmpty})
}
