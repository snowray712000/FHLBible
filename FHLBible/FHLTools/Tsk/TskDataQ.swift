//
//  TskDataQ.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/10.
//

import Foundation

class TskDataQ {
    var dataQ$: IjnEventOnce<Any,DApiSc> = IjnEventOnce()
    func main(_ addr:DAddress){
        let r1 = BibleBookNames.getBookName(addr.book, .Matt)
        let param = "book=4&engs=\(r1)&chap=\(addr.chap)&sec=\(addr.verse)"
        fhlSc(param) { data in
            self.dataQ$.triggerAndCleanCallback(nil, data)
        }
    }
}
