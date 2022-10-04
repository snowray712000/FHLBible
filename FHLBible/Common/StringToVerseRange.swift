import Foundation


/// 使用情境: 常常要將 "創1" 或 "Ge1" 或 "创1" 轉為 VerseRange
/// 它原本存寫在 VerseRange 的 fromReferenceDescription，但抽出來
/// 讓 VerseRange 單純是資料結構，演算單純另一個 Class 、 與 VerseRangeToString 一樣
/// (其它原本也是抽出來，只是叫 ParsingReferenceDescription )
/// 但現在改名字，讓它與 VerseRangeToString 成對
open class StringToVerseRange {
    /// 所有書卷，包含中英簡體，並依長度順序，還包含特別名稱約一、約壹皆可
    static private var regBookNames: NSRegularExpression?;
    /// 用於 strDescription = strDescription.replace(/\./g, ';');
    static private var regDot: NSRegularExpression?;
    /// 用於 \s 去除空白， 在 getAddressesOneBook 用到
    static private var regSpace: NSRegularExpression?
    /// c: class 的意思，方便用 static 變數 (輸入程式較方便)
    private typealias c = StringToVerseRange
    public init() {
        self.makeSureStaticExist()
    }
      

    public func main(_ strDescription: String,_ defaultAddress: (book: Int?, chap: Int?)? = nil ) ->  [DAddress] {
        let str2 = ijnReplaceString(c.regDot!, strDescription, ";")
        let defAddress = self.getDefaultAddress(defaultAddress)
        var re2 = self.splitBook(str2, defAddress)
        
        var reVerse: [DAddress] = []
        for i1 in 0..<re2.count {
            var it = re2[i1]
            let re3 = SmartDescriptEndParsing().main(it.id, it.des);
            if re3 != nil {
                re2[i1].des = re3!
                it = re2[i1]
            }
            
            let verses = getAddressesOneBook(it.id,it.des)
            reVerse.append(contentsOf: verses)
        }
        return reVerse;
      }

    private func getAddressesOneBook(_ id:Int,_ des: String)-> [DAddress] {
        let r1 = ijnReplaceString(c.regSpace!, des, "")
        let r2 = r1.split(separator: ";").map(String.init).filter({$0.count != 0})
        if r2.count != 0 {
            var vrs: [DAddress] = []
            for it2 in r2 {
                let r3 = GetAddresses(id).main(BookNameTryGetBookIdResult(it2, id))
                vrs.append(contentsOf: r3)
            }
            return vrs
        } else {
            return GetAddresses(id).main(BookNameTryGetBookIdResult("", id));
        }
      }

    private func splitBook(_ strDescription: String,_ defAddress: ( book: Int, chap: Int ))->[(id:Int,des:String)] {
        // 1:4-5;羅1:4;Mt3:3-2 會被切為 '1:4-5;' 、 '羅' 、 '1:4;' 、 Mt 、 3:3-2
        let re3 = SplitByRegex().main(str: strDescription, reg: c.regBookNames!)
        guard let re = re3 else { return [(id: defAddress.book, des: strDescription)] }
        
        var re2: [( id: Int, des: String )] = []
        var cur = defAddress.book;
        var curDes = NSMutableString()
        
        func pushLast(){
            // push 前一個 (當是第1個，例如Case 羅1:4;Mt3:3-2 就不會有前面的 1:4-5)
            if curDes.length != 0 {
                re2.append((id: cur, des: String(curDes)))
            } else if curDes.length == 0 && BibleChapCount.getChapCountEqual1BookIds().ijnAny({$0 == cur}) {
                re2.append((id: cur, des: "")) // 約二 約三 猶 (這些只有一章的書)
            }
        }
        
        
        for it in re {
            if it.isMatch() == false {
                curDes.append(String(it.w))
            } else {
                pushLast()
                
                // push 後 reset curDes
                let id2 = BookNameAndId().getIdOrUndefined(it.exec[0]!.lowercased());
                cur = id2 == nil ? defAddress.book : id2!;
                curDes = NSMutableString(); // reset
            }
        }
        
        pushLast()

        return re2;
      }

      private func getDefaultAddress(_ defaultAddress: ( book: Int?, chap: Int?)?) -> ( book: Int, chap: Int) {
        var defAddress: ( book: Int, chap: Int) = ( book: 40, chap: 1 )
        if (defaultAddress != nil) {
          if (defaultAddress!.book != nil) {
            defAddress.book = defaultAddress!.book!;
          }
          if (defaultAddress!.chap != nil) {
            defAddress.chap = defaultAddress!.chap!;
          }
        }
        return defAddress;
      }
    private func makeSureStaticExist() {
        if (c.regBookNames == nil) {
            /// 此  regBookNames 主要是用於 SplitStringByRegexVer2 參數
            let r1:String = BookNameAndId().getNamesOrderByNameLength().joined(separator: "|")
            
            c.regBookNames = try! NSRegularExpression(pattern: r1, options: [.caseInsensitive])
            c.regDot = try! NSRegularExpression(pattern: #"\."#, options: [])
            c.regSpace = try! NSRegularExpression(pattern: #"\s"#, options: [])
        }
    }
}

