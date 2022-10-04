import Foundation

/// 開發 GetAddresses 而需求的
public protocol IBookNameTryGetBookIdResult {
    var descript: String {get}
    var idBook: Int {get}
}
open class BookNameTryGetBookIdResult : IBookNameTryGetBookIdResult{
    init(_ descript: String,_ idBook: Int) {
        self.descript = descript
        self.idBook = idBook
    }
    public var descript: String
    public var idBook: Int
}
/// 開發 GetAddresses 而需求的
public protocol IGetAddressesType {
    /** 1:32-2:31 (tp:0) 1:2-32 (tp:1) 23 (23節 或 23章 tp:2) */
    var tp: Int {get}
    var ch1: Int {get}
    var vr1: Int {get}
    var ch2: Int {get}
    var vr2: Int {get}
}
open class GetAddressesType : IGetAddressesType{
    internal init(tp: Int, ch1: Int, vr1: Int, ch2: Int, vr2: Int) {
        self.tp = tp
        self.ch1 = ch1
        self.vr1 = vr1
        self.ch2 = ch2
        self.vr2 = vr2
    }
    
    public var tp: Int
    public var ch1: Int
    public var vr1: Int
    public var ch2: Int
    public var vr2: Int
    
}
/** 一卷書 1:1-3,6-7,21,25,2:3-5 分解 */
/// 在開發 StringToVerseRange 時引用到
open class GetAddresses {
    typealias c = GetAddresses
    /// /** // 只5種類似 // 1:32-2:31 // 1:2-32 // 4-7 // 1:23 // 23 (23節 或 23章) */
    private static var regA1: NSRegularExpression = try! NSRegularExpression(pattern: #"(\d+):(\d+)-(\d+):(\d+)"#); // ["11:32-2:31","11","32","2","31"
    /// ["11:32-2:31","11","32","2",
    private static var regA2 =  try! NSRegularExpression(pattern: #"(\d+):(\d+)-(\d+)"#);
    /// 後來發現的 bug, 雖然它應該是a3，但卻是編號4的原因,因為一開始沒考慮到
    private static var regA4 =  try! NSRegularExpression(pattern: #"(\d+)-(\d+)"#);
    /// // 後來發現的 bug, 雖然它應該是a4，但卻是編號5的原因,因為一開始沒考慮到
    private static var regA5 =  try! NSRegularExpression(pattern: #"(\d+):(\d+)"#);
    /// ["11:32-2:31","11"
    private static var regA3 =  try! NSRegularExpression(pattern: #"(\d+)"#);
    
    private var idBook: Int;
    private var addresses = [DAddress]()

    init(_ idBook:Int){
        self.idBook = idBook
    }
    
    public func main(_ oneBookResult: IBookNameTryGetBookIdResult)-> [DAddress] {
        // 約二 case
        if (oneBookResult.descript.count == 0) {
            if ( BibleChapCount.getChapCountEqual1BookIds().ijnAny({$0 == idBook}) ){
                // if (getChapCountEqual1BookIds().includes(self.idBook)) {
                return self.generateOneChap(1);
            } else {
                //console.log(oneBookResult.descript);
                //console.warn('GetAddresses 不加章節只允許「一章」的書卷,例如約一');
                return [];
            }
        }
    
        let r1 = oneBookResult.descript.split(separator: ",")
        let r2 = r1.map({self.classifyType(String($0))})
        
        for a1 in r2 {
            let verses = generateFromTypeX(a1)
            if verses != nil {
                self.addresses.append(contentsOf: verses!)
            }
        }

        return addresses;
    }
    
    private func generateFromTypeX(_ a1: IGetAddressesType?)->[DAddress]?{
        guard let a1 = a1 else { return nil }
        
        switch a1.tp {
        case 0:
            return generateFromType0(a1)
        case 1:
            return generateFromType1(a1)
        case 2:
            return generateFromType2(a1)
        case 3:
            return generateFromType3(a1)
        case 4:
            return generateFromType4(a1)
        default:
            return nil
        }
    }
  
    private func classifyType(_ des: String)-> IGetAddressesType? {
        var ch1 = -1,vr1 = -1,ch2 = -1,vr2 = -1,tp = -1
        func g()->IGetAddressesType {
            return GetAddressesType(tp: tp, ch1: ch1, vr1: vr1, ch2: ch2, vr2: vr2)
        }
        
        var r1 = ijnMatchFirstAndToSubString(c.regA1, des)
        if r1 != nil {
            tp = 0 ;
            ch1 = Int(r1![1]!)!
            vr1 = Int(r1![2]!)!
            ch2 = Int(r1![3]!)!
            vr2 = Int(r1![4]!)!
            return g()
        }
        
        r1 = ijnMatchFirstAndToSubString(c.regA2, des)
        if r1 != nil {
            tp = 1 ;
            ch1 = Int(r1![1]!)!
            vr1 = Int(r1![2]!)!
            ch2 = ch1
            vr2 = Int(r1![3]!)!
            return g()
        }
        
        /// 原本的程式碼真的是 1 2 4 5 3 的順序劉
        r1 = ijnMatchFirstAndToSubString(c.regA4, des)
        if r1 != nil {
            tp = 3
            ch1 = -1
            vr1 = Int(r1![1]!)!
            ch2 = -1
            vr2 = Int(r1![2]!)!
            return g()
        }
        
        r1 = ijnMatchFirstAndToSubString(c.regA5, des)
        if r1 != nil {
            tp = 4
            ch1 = Int(r1![1]!)!
            vr1 = Int(r1![2]!)!
            ch2 = -1
            vr2 = -1
            return g()
        }
        
        r1 = ijnMatchFirstAndToSubString(c.regA3, des)
        if r1 != nil {
            tp = 2
            ch1 = Int(r1![1]!)!
            vr1 = ch1
            ch2 = -1
            vr2 = -1
            return g()
        }

        return nil
    }
  
    private func generateFromType0(_ add: IGetAddressesType)->[DAddress] {
        // 1:2-1:24
        // 1:2-2:24
        // 1:2-3:24
        if (add.ch1 == add.ch2) {
          return generateFromType1(add);
        }
        // 1:2 - 1:結束
        let verse1End = BibleVerseCount.getVerseCount(self.idBook, add.ch1);

        var re = ijnRange(add.vr1, verse1End - add.vr1 + 1).map({DAddress(book: self.idBook, chap: add.ch1, verse: $0)})
        // 中間章節, 例如  1:2-3:24, 第2章 從 2 開始, 有 1 章 (3-1-1)
        if (add.ch1 + 1 < add.ch2) {
            let r2 = ijnRange(add.ch1 + 1, add.ch2 - add.ch1 - 1).map({self.generateOneChap($0)});
            for a1 in r2 {
                re.append(contentsOf: a1)
            }
        }
        // 最後章節, 例 -3:31
        let r3 = ijnRange(1, add.vr2).map({DAddress(book: self.idBook, chap: add.ch2, verse: $0)})
        re.append(contentsOf: r3)

        return re;
    }
    private func generateFromType1(_ add: IGetAddressesType)-> [DAddress] {
        // 1:12-43
        return ijnRange(add.vr1, add.vr2 - add.vr1 + 1).map({DAddress(book: self.idBook, chap: add.ch1, verse: $0)})
    }
    /** 2:1-End */
    private func generateOneChap(_ ch: Int)-> [DAddress] {
        let verseEnd = BibleVerseCount.getVerseCount(self.idBook, ch)
        return ijnRange(1, verseEnd).map({DAddress(book: self.idBook, chap: ch, verse: $0)})
    }
    private func getLastVerseAddress()-> DAddress? {
        return self.addresses.last
    }
    /**
     * 整章，或是一節 (當目前 this.addresses 沒有東西時)
     * - Parameter add: <#add description#>
     * - Returns: <#description#>
     */
    private func generateFromType2(_ add: IGetAddressesType)-> [DAddress] {
        // 整章 or 一節
        let last = self.getLastVerseAddress();
        if (last == nil) {
            return self.generateOneChap(add.ch1);
        }
        return [DAddress(book: self.idBook, chap: last!.chap, verse: add.vr1)]
    }

    private func generateFromType3(_ add: IGetAddressesType)-> [DAddress] {
        // 7-9
        let last = self.getLastVerseAddress();
        let ch = last != nil ? last!.chap : 1;
        return ijnRange(add.vr1, add.vr2 - add.vr1 + 1).map({DAddress(book: self.idBook, chap: ch, verse: $0)})
    }
    private func generateFromType4(_ add: IGetAddressesType)-> [DAddress] {
        // 1:23
        return [DAddress(book: self.idBook, chap: add.ch1, verse: add.vr1)]
    }
}
