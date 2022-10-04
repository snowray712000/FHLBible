import Foundation

/// 為了 StringToVerseRange 需求
/// 輸入網址時，有時候不知道這章幾節，直接寫 1:3-e；甚至可以寫 1:3-
open class SmartDescriptEndParsing {
  /** 不需要變更, 會回傳 undefined, 否則, 回傳 1:2-e 回傳 1:2-34 */
  func main(_ book: Int,_ des: String)-> String? {
    // 1:end or 1:e
    // 1:2-2:end or 1:2-2:e
    // 1:3-end or 1:3-e
    let reg = try! NSRegularExpression(pattern: #"(?:((\d+):)e|end)|(?:((\d+):(?:\d+)-)e|end)"#, options: [.caseInsensitive])
    let r1 = SplitByRegex().main(str: des, reg: reg)
    // /(?:((\d+):)e|end)|(?:((\d+):(?:\d+)-)e|end)/gi);
    // console.log(r1);
    if r1 == nil {
        return nil
    }

    let re3:NSMutableString = ""
    for it2 in r1! {
        if (false == it2.isMatch()){
            re3.append(String(it2.w))
        } else {
            if ( it2.exec[1] == nil ){
                // 將 e 這個字，用 節(的數字) 取代即可
                // [3] '1:4-' [4] '1'
                let verse = BibleVerseCount.getVerseCount(book, Int(String(it2.exec[4]!))!)
                re3.append(String(it2.exec[3]!))
                re3.append(verse.description)
            } else {
                // 將 e 這個字，用 節(的數字) 取代即可
                // [1] '1:' [2] '1'
                let verse = BibleVerseCount.getVerseCount(book, Int(String(it2.exec[2]!))!)
                re3.append(String(it2.exec[1]!))
                re3.append(verse.description)
            }
        }
    }
    // console.log(re3);
    return re3 as String;
  }
}
