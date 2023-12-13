/**
 此檔案，開發複製文字過程時新增的。
 - 此檔案還包含了 unit test 資料
 */

import Foundation

/**
 提供 VCWhenLongPress 使用的，將要顯示要複製的結果用的。
 */
class DSelections {
    
    /**
     複選的資料，key1 是 章節，當時是用 StringToVerseRange 轉換得到的，key2 是 版本，用的是 unv 這些原本的名稱。
     - 技術上，已確定 [DAddress] 作為 key 是可以的。因為有作 Hashable 的樣子。
     - address 之所以用 [DAddress] 而非 DAddress ，是因為有的經文章節是， `創1:1-2` 合併的。
     */
    var data: Dictionary<[DAddress],Dictionary<String,[DText]>>!
    /**
     因為 data 是 dict ，但原本「閱讀 」的順序要保留下來，所以記下原本的順序。
     */
    var addrs: [[DAddress]]!
    /**
     因為 data 是 dict，將原本的「版本」排序保留下來。
     */
    var vers: [String]!
}
extension DSelections {
    /// 一節經文，一個版本。
    static func gTest1()->DSelections{
        let r1 = DSelections()
        r1.addrs = [[DAddress(1,1,1)]]
        r1.vers = ["unv"]
        
        r1.data = [:]
        r1.data[[DAddress(1,1,1)]] = [:]
        r1.data[[DAddress(1,1,1)]]!["unv"] = [DText("起初，  神創造天地。")]
        return r1
    }
    /// 一節，多個版本
    static func gTest2()->DSelections{
        let r1 = DSelections()
        let addr1 = [DAddress(1,1,1)]
        r1.addrs = [addr1]
        r1.vers = ["unv","esv"]
        
        r1.data = [:]
        r1.data[addr1] = [:]
        r1.data[addr1]!["unv"] = [DText("起初，  神創造天地。")]
        r1.data[addr1]!["esv"] = [DText("In the beginning, God created the heavens and the earth.")]
        
        return r1
    }
    /// 2 節， 1 個版本。 2 x 1
    static func gTest3()->DSelections{
        let r1 = DSelections()
        let addr1 = [DAddress(1,1,1)]
        let addr2 = [DAddress(1,1,2)]
        r1.addrs = [addr1,addr2]
        r1.vers = ["unv"]
        
        r1.data = [:]
        
        r1.data[addr1] = [:]
        r1.data[addr1]!["unv"] = [DText("起初，  神創造天地。")]
        
        r1.data[addr2] = [:]
        r1.data[addr2]!["unv"] = [DText("地是空虛混沌，淵面黑暗；　神的靈運行在水面上。")]
        
        return r1
    }
    /// 二節，二個版本。 2 x 2
    static func gTest4()->DSelections{
        let r1 = DSelections()
        let addr1 = [DAddress(1,1,1)]
        let addr2 = [DAddress(1,1,2)]
        r1.addrs = [addr1,addr2]
        r1.vers = ["unv","esv"]
        
        r1.data = [:]
        
        r1.data[addr1] = [:]
        r1.data[addr1]!["unv"] = [DText("起初，  神創造天地。")]
        r1.data[addr1]!["esv"] = [DText("In the beginning, God created the heavens and the earth.")]
        
        r1.data[addr2] = [:]
        r1.data[addr2]!["unv"] = [DText("地是空虛混沌，淵面黑暗；　神的靈運行在水面上。")]
        r1.data[addr2]!["esv"] = [DText("The earth was without form and void, and darkness was over the face of the deep. And the Spirit of God was hovering over the face of the waters.")]
        
        return r1
    }
    /// 非矩形。三節，二個版本。
    static func gTest5()->DSelections{
        let r1 = DSelections()
        let addr1 = [DAddress(1,1,1)]
        let addr2 = [DAddress(1,1,2)]
        let addr3 = [DAddress(1,1,3)]
        r1.addrs = [addr1,addr2,addr3]
        r1.vers = ["unv","esv"]
        
        r1.data = [:]
        
        r1.data[addr1] = [:]
        r1.data[addr1]!["unv"] = [DText("起初，  神創造天地。")]
        // r1.data[addr1]!["esv"] = [DText("In the beginning, God created the heavens and the earth.")]
        
        r1.data[addr2] = [:]
        // r1.data[addr2]!["unv"] = [DText("地是空虛混沌，淵面黑暗；　神的靈運行在水面上。")]
        r1.data[addr2]!["esv"] = [DText("The earth was without form and void, and darkness was over the face of the deep. And the Spirit of God was hovering over the face of the waters.")]
        
        r1.data[addr3] = [:]
        r1.data[addr3]!["unv"] = [DText("　神說：「要有光」，就有了光。")]
        r1.data[addr3]!["esv"] = [DText("And God said, “Let there be light,” and there was light.")]
        
        return r1
    }
    /// 非矩形。有合併節。三節，二個版本。
    static func gTest6()->DSelections{
        let r1 = DSelections()
        let addr1 = [DAddress(1,1,1),DAddress(1,1,2)]
        let addr2 = [DAddress(1,1,1)]
        let addr3 = [DAddress(1,1,2)]
        r1.addrs = [addr1,addr2,addr3]
        r1.vers = ["unv","esv"]
        
        r1.data = [:]
        
        r1.data[addr1] = [:]
        // r1.data[addr1]!["unv"] = [DText("起初，  神創造天地。")]
        r1.data[addr1]!["esv"] = [DText("In the beginning, God created the heavens and the earth.The earth was without form and void, and darkness was over the face of the deep. And the Spirit of God was hovering over the face of the waters.")]
        
        r1.data[addr2] = [:]
        r1.data[addr2]!["unv"] = [DText("地是空虛混沌，淵面黑暗；　神的靈運行在水面上。")]
        
        r1.data[addr3] = [:]
        r1.data[addr3]!["unv"] = [DText("　神說：「要有光」，就有了光。")]
        
        return r1
    }
    /// 1 個版本，跨書卷，連結當有分號時
    static func gTest7()->DSelections{
        let r1 = DSelections()
        let addr1 = [DAddress(1,1,1)]
        let addr2 = [DAddress(1,1,2)]
        let addr3 = [DAddress(2,1,1)]
        r1.addrs = [addr1,addr2,addr3]
        r1.vers = ["unv"]
        
        r1.data = [:]
        
        r1.data[addr1] = [:]
        r1.data[addr1]!["unv"] = [DText("起初，  神創造天地。")]
        
        r1.data[addr2] = [:]
        r1.data[addr2]!["unv"] = [DText("地是空虛混沌，淵面黑暗；　神的靈運行在水面上。")]
        
        r1.data[addr3] = [:]
        r1.data[addr3]!["unv"] = [DText("以色列的眾子，各帶家眷，和雅各一同來到埃及。他們的名字記在下面。")]
        
        return r1
    }
}
