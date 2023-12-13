//
//  ViewParsingWord.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/3.
//

import Foundation
import UIKit

/// 使用 setTextsFirstCellTitle ( ) setTextsSecondCellTitle ( )
/// 信望愛 Parsing 工具，原文一行，中文一行。就是會有兩個 Cell。而且對齊不同是特色。
class ViewParsingWord : ViewFromXibBase {
    override var nibName: String{ "ViewParsingWord" }
    @IBOutlet var viewCellOrig: ViewDisplayCell!
    @IBOutlet var viewCellChineses: ViewDisplayCell!

    func setTextsFirstCellTitle(_ dtexts:[DText],_ isRightToLeft: Bool){
        _data1 = dtexts
        
        let tpAlign: NSTextAlignment = isRightToLeft ? .right : .left
        
        _set_cellview(cellview: viewCellOrig, dtexts: _data1, tpAlign: tpAlign)
        
        viewCellOrig.viewText.textAlignment = tpAlign
    }
    private func _set_cellview(cellview: ViewDisplayCell, dtexts: [DText],tpAlign: NSTextAlignment){
        cellview.set(dtexts: dtexts, isVisibleSn: true, isSwitchOn: true, isSwitchVisible: false)
    }
    func setTextsSecondCellTitle(_ dtexts:[DText],_ isRightToLeft: Bool){
        _data2 = dtexts
        
        let tpAlign: NSTextAlignment = isRightToLeft ? .right : .left
        
        _set_cellview(cellview: viewCellChineses, dtexts: _data2, tpAlign: tpAlign)
        
        viewCellChineses.viewText.textAlignment = tpAlign
    }
    var onClick$: IjnEvent<UIView,DText> = IjnEvent()
        
    private var test3: [DText] {
        get {
            let r1 = testHebrew1["word"]?.replacingOccurrences(of: "\n\r", with: "")
            // let reg = try! NSRegularExpression(pattern: " ", options: [])
            let reg = try! NSRegularExpression(pattern: "[\u{0590}-\u{05fe}]+", options: [])
            let r2 = SplitByRegex().main(str: r1!, reg: reg)!
            let r3 = r2.map({ a1 -> DText in
                return DText(String(a1.w))
            })
            return r3
            
        }
    }
    override func initedFromXib() {
        viewCellOrig.set(dtexts: test3, isVisibleSn: true, isSwitchOn: true, isSwitchVisible: false)
        
        let dataChinese = [DText(testHebrew1["exp"]?.replacingOccurrences(of: "\r\n", with: ""))]
        viewCellChineses.set(dtexts: dataChinese, isVisibleSn: true, isSwitchOn: true, isSwitchVisible: false)
        
        viewCellOrig.onClicked$.addCallback { sender, pData in
            self.onClick$.trigger(sender, pData)
        }
        viewCellChineses.onClicked$.addCallback { sender, pData in
            self.onClick$.trigger(sender, pData)
        }
        self.onClick$.addCallback { sender, pData in
            if pData != nil && pData!.w != nil {
                print (pData!.w!)
            }
        }
    }
    private var _data1: [DText] = []
    private var _data2: [DText] = []
    
    var testHebrew2: [String:String] = ["word":"\u{05d5}\u{05b0}\u{05e8}\u{05d5}\u{05bc}\u{05d7}\u{05b7} \u{05d0}\u{05b1}\u{05dc}\u{05b9}\u{05d4}\u{05b4}\u{05d9}\u{05dd} \u{05de}\u{05b0}\u{05e8}\u{05b7}\u{05d7}\u{05b6}\u{05e4}\u{05b6}\u{05ea} \u{05e2}\u{05b7}\u{05dc}-\u{05e4}\u{05bc}\u{05b0}\u{05e0}\u{05b5}\u{05d9} \u{05d4}\u{05b7}\u{05de}\u{05bc}\u{05b8}\u{05d9}\u{05b4}\u{05dd}\u{05c3}", "exp":"\u{5730}\u{662f}\u{7a7a}\u{865b}\u{6df7}\u{6c8c}\u{ff0c}\r\n\u{6df5}\u{9762}\u{9ed1}\u{6697}\u{ff1b}\r\n\u{4e0a}\u{5e1d}\u{7684}\u{9748}\u{904b}\u{884c}\u{5728}\u{6c34}\u{9762}\u{4e0a}\u{3002}"]
    var testHebrew1: [String:String] = ["word":"\u{05d5}\u{05b0}\u{05e8}\u{05d5}\u{05bc}\u{05d7}\u{05b7} \u{05d0}\u{05b1}\u{05dc}\u{05b9}\u{05d4}\u{05b4}\u{05d9}\u{05dd} \u{05de}\u{05b0}\u{05e8}\u{05b7}\u{05d7}\u{05b6}\u{05e4}\u{05b6}\u{05ea} \u{05e2}\u{05b7}\u{05dc}-\u{05e4}\u{05bc}\u{05b0}\u{05e0}\u{05b5}\u{05d9} \u{05d4}\u{05b7}\u{05de}\u{05bc}\u{05b8}\u{05d9}\u{05b4}\u{05dd}\u{05c3}\n\r\u{05d5}\u{05b0}\u{05d7}\u{05b9}\u{05e9}\u{05c1}\u{05b6}\u{05da}\u{05b0} \u{05e2}\u{05b7}\u{05dc}-\u{05e4}\u{05bc}\u{05b0}\u{05e0}\u{05b5}\u{05d9} \u{05ea}\u{05b0}\u{05d4}\u{05d5}\u{05b9}\u{05dd}\n\r\u{05d5}\u{05b0}\u{05d4}\u{05b8}\u{05d0}\u{05b8}\u{05e8}\u{05b6}\u{05e5} \u{05d4}\u{05b8}\u{05d9}\u{05b0}\u{05ea}\u{05b8}\u{05d4} \u{05ea}\u{05b9}\u{05d4}\u{05d5}\u{05bc} \u{05d5}\u{05b8}\u{05d1}\u{05b9}\u{05d4}\u{05d5}\u{05bc}", "exp":"\u{5730}\u{662f}\u{7a7a}\u{865b}\u{6df7}\u{6c8c}\u{ff0c}\r\n\u{6df5}\u{9762}\u{9ed1}\u{6697}\u{ff1b}\r\n\u{4e0a}\u{5e1d}\u{7684}\u{9748}\u{904b}\u{884c}\u{5728}\u{6c34}\u{9762}\u{4e0a}\u{3002}"]
    var testGreek1: [String:String] = ["word":"\u{039b}\u{1f73}\u{03b3}\u{03c9} \u{03b3}\u{1f70}\u{03c1} \u{03b4}\u{03b9}\u{1f70} \u{03c4}\u{1fc6}\u{03c2} \u{03c7}\u{1f71}\u{03c1}\u{03b9}\u{03c4}\u{03bf}\u{03c2} \u{03c4}\u{1fc6}\u{03c2} \u{03b4}\u{03bf}\u{03b8}\u{03b5}\u{1f77}\u{03c3}\u{03b7}\u{03c2} \u{03bc}\u{03bf}\u{03b9} \n\u{03c0}\u{03b1}\u{03bd}\u{03c4}\u{1f76} \u{03c4}\u{1ff7} \u{1f44}\u{03bd}\u{03c4}\u{03b9} \u{1f10}\u{03bd} \u{1f51}\u{03bc}\u{1fd6}\u{03bd} \n\u{03bc}\u{1f74} \u{1f51}\u{03c0}\u{03b5}\u{03c1}\u{03c6}\u{03c1}\u{03bf}\u{03bd}\u{03b5}\u{1fd6}\u{03bd} \u{03c0}\u{03b1}\u{03c1}\u{1fbd} \u{1f43} \u{03b4}\u{03b5}\u{1fd6} \u{03c6}\u{03c1}\u{03bf}\u{03bd}\u{03b5}\u{1fd6}\u{03bd} \n\u{1f00}\u{03bb}\u{03bb}\u{1f70} \u{03c6}\u{03c1}\u{03bf}\u{03bd}\u{03b5}\u{1fd6}\u{03bd} \u{03b5}\u{1f30}\u{03c2} \u{03c4}\u{1f78} \u{03c3}\u{03c9}\u{03c6}\u{03c1}\u{03bf}\u{03bd}\u{03b5}\u{1fd6}\u{03bd},\n \u{1f11}\u{03ba}\u{1f71}\u{03c3}\u{03c4}\u{1ff3} \u{1f61}\u{03c2} \u{1f41} \u{03b8}\u{03b5}\u{1f78}\u{03c2} \u{1f10}\u{03bc}\u{1f73}\u{03c1}\u{03b9}\u{03c3}\u{03b5}\u{03bd} \u{03bc}\u{1f73}\u{03c4}\u{03c1}\u{03bf}\u{03bd} \u{03c0}\u{1f77}\u{03c3}\u{03c4}\u{03b5}\u{03c9}\u{03c2}.", "exp":"\u{56e0}\u{70ba}\u{6211}\u{85c9}\u{8457}\u{6240}\u{8cdc}\u{7d66}\u{6211}\u{7684}\u{6069}\u{5178}...\u{8aaa}\u{ff1a}(...\u{8655}\u{586b}\u{5165}\u{4e0b}\u{4e00}\u{884c})\r\n\u{5c0d}\u{4f60}\u{5011}\u{4e2d}\u{9593}\u{6bcf}\u{500b}\u{4eba}\r\n\u{4e0d}\u{8981}\u{770b}\u{81ea}\u{5df1}\u{9ad8}\u{65bc}\u{6240}\u{7576}\u{770b}\u{7684}\u{ff0c}\r\n\u{800c}\u{662f}\u{770b}\u{5f97}\u{5408}\u{7406}\u{ff0c}\r\n\u{6bcf}\u{500b}\u{4eba}\u{5982}\u{540c}\u{4e0a}\u{5e1d}\u{6240}\u{5206}\u{7d66}\u{4fe1}\u{5fc3}\u{7684}\u{4efd}\u{91cf}\u{3002}"]
}
