//
//  SQLSelectBibleTextGenerator.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/21.
//

import Foundation
class SQLSelectBibleCommentsGenerator {
    func main(address addr:DAddress,
              tag:Int,
              cntLimit :Int?=1)->String{
        // SELECT * FROM comment2 WHERE tag=3 AND book=1 AND
        // (    (bchap=echap AND bchap=2 AND bsec<=3 AND esec>=3) OR
        // (   bchap<echap AND ( (bchap=2 AND bsec<=3) OR (echap=2 AND esec>=3) OR (bchap<2 AND echap>2) )   )    ) LIMIT 1;
        let chap = addr.chap
        let sec = addr.verse
        
        let strSelectWhere = "SELECT * FROM comment2 WHERE tag=\(tag) AND book=\(addr.book) AND";
        let where1 = "(bchap=echap AND bchap=\(chap) AND bsec<=\(sec) AND esec>=\(sec))"
        let where2b = "(bchap=\(chap) AND bsec<=\(sec)) OR (echap=\(chap) AND esec>=\(sec)) OR (bchap<\(chap) AND echap>\(chap))"
        let where2 = "(bchap<echap AND (\(where2b)))"
        
        let limit = cntLimit == nil ? "" : " LIMIT \(cntLimit!)"
        
        return "\(strSelectWhere) (\(where1) OR \(where2))\(limit);"
    }
}
