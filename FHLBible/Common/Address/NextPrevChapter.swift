//
//  NextPrevChapter.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/9.
//

import Foundation
import FHLCommon

extension VerseRange {
    func goNext()->VerseRange {
        return VerseRange(VerseRangeGoNextChap().goNext(self.verses))
    }
    func goPrev()->VerseRange {
        return VerseRange(VerseRangeGoNextChap().goPrev(self.verses))
    }
}
extension DAddress {
    func goNextChap()->[DAddress]{
        return VerseRangeGoNextChap().goNext([self])
    }
    func goPrevChap()->[DAddress]{
        return VerseRangeGoNextChap().goPrev([self])
    }
}
