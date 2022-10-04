import Foundation

/// 開發 StringToVerseRange 時要用到
open class BookNameAndId {
    private typealias c = BookNameAndId
  /** matt:40, mt:40, 太:40, lower case, 1-based */
    private static var mapsNa2Id: [String: Int]?;
  // private static var mapsNa2Id: Map<String, Int>?;
  /** */
    private static var namesOrderByNameLength: [String]?;
    init() {
        if (c.mapsNa2Id == nil) {
            self.generate();
        }
    }
  
    func getIdOrUndefined(_ nameLowcase: String)-> Int? {
        return c.mapsNa2Id![nameLowcase]
    }
 
    /** ["second thessalonians","first thessalonians",..."太"] */
    func getNamesOrderByNameLength()-> [String] {
        return c.namesOrderByNameLength!;
    }
  
    /** 同時完成 namesOrderByNameLength mapsNa2Id 兩個變數 */
    private func generate() {
        var rr1 = [Int: [String]]() // Reg 1=['創世記','Matthew','Matt','太','Mt'] 2= ...
        (1..<67).forEach({rr1[$0] = []})
        var r2 = [String: Int]() // 同時產生 創世記=1, matthew=1
    
        let tp: [BookNameLang] = [.Matthew,.Matt,.Mt,.馬太福音,.马太福音GB,.太,.太GB]
        for a1 in tp {
            for (i2,a2) in BibleBookNames.getBookNames(a1).enumerated() {
                rr1[i2+1]!.append(a2)
                r2[a2.lowercased()] = i2+1
            }
        }
        
        // 特殊中文字 / 別名
        var sp1 = [Int: [String]]()
        sp1[62] = ["約壹", "約翰壹書", "约壹", "约翰壹书"]
        sp1[63] = ["約貳", "約翰貳書", "约贰", "约翰贰书"]
        sp1[64] = ["約參", "約翰參書", "约参", "约翰参书"]
          
        for (id,a1) in sp1 {
            for a2 in a1{
                rr1[id]!.append(a2)
                r2[a2.lowercased()] = id
            }
        }
    
        // 結果1
        c.mapsNa2Id = r2;
        c.namesOrderByNameLength = r2.keys.sorted(by: {$0.count > $1.count})
        // c.namesOrderByNameLength = Array.from(r2.keys()).sort((a1, a2) => a2.length - a1.length);
        // mt 若剛好有個也是 mt 開頭會被誤會,所以長的在前面

        // console.log(BookNameAndId.mapsNa2Id);
        // console.log(BookNameAndId.namesOrderByNameLength);
    }
}
